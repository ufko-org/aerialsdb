# ---------------------------------------------------------------------
# Copyright (c) 2025, Ufko.org
# Licensed under the Apache License, Version 2.0. 
# See LICENSE file in the project root for details.
# ---------------------------------------------------------------------

source config.tcl

# Generates random test values
proc generate_random_values {} {
    set data_size [expr {int(rand() * 200) + 1}] 
    set random_data ""
    # let's generate random data
    for {set i 0} {$i < $data_size} {incr i} {
        set random_data "${random_data}[format %c [expr {int(rand() * 256)}]]"
    }
    return [binary encode hex $random_data]
}

# Generates random data
proc random_gen {length} {
	set random_bytes [open "/dev/urandom" rb]
	set random_data [read $random_bytes $length]
	close $random_bytes
	binary encode hex $random_data
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
proc bucket_get {term {json 0}} {
	#meta value {"file": "file.png", "size": "1024KB", "description": "Image file", "created": "2025-02-27"}
	#SELECT json_extract(meta, '$.size') FROM buckets_meta where dir='f70' and file='c44ef23c3d84e';
	#SELECT dir, file, row_key, json_extract(meta, '$.size') AS size FROM buckets_meta
	#SELECT dir, file, row_key, json_extract(meta, '$.size') AS size FROM buckets_meta WHERE json_extract(meta, '$.file') = 'file.png';

	sqlite3 db aerial.sq3
	set pattern %$term%
	set bucket_info [db eval {select dir1, dir2, file, row_key from buckets_meta where meta like :pattern}]
	db close
	set dir1 [lindex $bucket_info 0]
	set dir2 [lindex $bucket_info 1]
	set file [lindex $bucket_info 2]
	set key  [lindex $bucket_info 3]
	sqlite3 db "$::bucket_root/$dir1/$dir2/$file.sq3"
	set value [db eval {select value from bucket where key=:key}]
	db close
	puts $value
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
