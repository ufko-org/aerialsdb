# ---------------------------------------------------------------------
# Copyright (c) 2025, Ufko.org
# Licensed under the Apache License, Version 2.0. 
# See LICENSE file in the project root for details.
# ---------------------------------------------------------------------

source config.tcl

# This is a testing helper to quickly create simple json metadata
# from list with even number of members
# puts [json1 {name imgfile1 size 25000 type png}]
proc json1 {lst} {
  # Todo: check if lst has even number of members :)

  set json_str "{"
  foreach {key value} $lst {
    append json_str "\"$key\": \"$value\","
  }
  # remove last comma
  if {[string length $json_str] > 1} {
    set json_str [string range $json_str 0 end-1]
  }
  append json_str "}"
  return $json_str
}

# Generates random data
proc random_gen {length} {
	set random_bytes [open "/dev/urandom" rb]
	set random_data [read $random_bytes $length]
	close $random_bytes
	binary encode hex $random_data
}

# Generates random test values
proc generate_random_values {} {
    set len [expr {int(rand() * 200) + 1}] 
		random_gen len
}

# Generates random bucket_path
proc bucket_path_generator {} {
	set path [random_gen 8]
	set dir1  [string range $path 0 1]
	set dir2  [string range $path 2 3]
	set file  [string range $path 4 end]
	return [list $dir1 $dir2 $file]
}

proc bucket_set {meta value} {
	sqlite3 db aerial.sq3

	# check for free space in the existing bucket
	set bucket_info [db eval "select rowid, dir1, dir2, file from buckets where rows < $::bucket_max_rows limit 1"]
	set random_key  [random_gen 32]

	if {[lindex $bucket_info 0] eq "" } {
		# no rowid, no free space in the existing bucket, creating new bucket, saving key and value
		set path [bucket_path_generator]
		set dir1  [lindex	$path 0]
		set dir2  [lindex	$path 1]
		set file  [lindex $path 2]
		file mkdir "$::bucket_root/$dir1/$dir2"
		sqlite3 db2 "$::bucket_root/$dir1/$dir2/$file.sq3"
		db2 eval {create table if not exists bucket(key, value)}
		db2 eval {insert into bucket (key, value) values (:random_key, :value)}
		db2 close
		db eval {insert into buckets (dir1, dir2, file, rows) values (:dir1, :dir2, :file, 1)}
		db eval {insert into buckets_meta (dir1, dir2, file, row_key, meta) values (:dir1, :dir2, :file, :random_key, :meta)}
		puts "New bucket created"
	} else {
		# found free space in existing bucket, saving key and value
		set dir1 [lindex $bucket_info 1]
		set dir2 [lindex $bucket_info 2]
		set file [lindex $bucket_info 3]
		sqlite3 db2 "$::bucket_root/$dir1/$dir2/$file.sq3"
		db2 eval {insert into bucket (key, value) values (:random_key, :value)}
		db2 close
		db eval {update buckets set rows = (rows + 1) where dir1 = :dir1 AND dir2 = :dir2 AND file = :file}
		db eval {insert into buckets_meta (dir1, dir2, file, row_key, meta) values (:dir1, :dir2, :file, :random_key, :meta)}
		puts "Existing bucket used"
	}

	db close
}

# This is going to be fun :D :D
proc bucket_get {jsonkey jsonval {limit 1}} {
	# meta value {"file": "file.png", "size": "1024KB", "description": "Image file", "created": "2025-02-27"}

	sqlite3 db aerial.sq3
	if {$limit > 0} {
		set bucket_info [db eval "select dir1, dir2, file, row_key from buckets_meta where json_extract(meta, '\$.$jsonkey') = '$jsonval' limit $limit"]
	} else {
		set bucket_info [db eval "select dir1, dir2, file, row_key from buckets_meta where json_extract(meta, '\$.$jsonkey') = '$jsonval'"]
	}
	db close

	foreach {dir1 dir2 file row_key} $bucket_info {
		sqlite3 db "$::bucket_root/$dir1/$dir2/$file.sq3"
		set value [db eval {select value from bucket where key=:row_key}]
		puts $value
		db close
	}
}

proc aerial_init {} {
	sqlite3 db aerial.sq3
	db eval {create table if not exists buckets (dir1, dir2, file, rows)}
	db eval {create table if not exists buckets_meta (dir1, dir2, file, row_key, meta)}
	db close
	file mkdir bucketroot
	puts "Aerial initialized"
}

proc aerial_clean {} {
	file delete -force aerial.sq3
	file delete -force $::bucket_root
	#file delete -force {*}[glob "$::bucket_root/*"]
	puts "Aerial cleaned"
}

proc aerial_reset {} {
	aerial_clean
	aerial_init
}
