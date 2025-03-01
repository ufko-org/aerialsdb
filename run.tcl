# ---------------------------------------------------------------------
# Copyright (c) 2025, Ufko.org
# Licensed under the Apache License, Version 2.0. 
# See LICENSE file in the project root for details.
# ---------------------------------------------------------------------

source config.tcl

# This is a testing helper to quickly create simple JSON metadata
# from a 1-level list with an even number of elements
# json1 {name imgfile1 size 25000 type png}
proc json1 {lst} {
	if {[llength $lst] % 2 != 0} {
		error "List must have an even number of elements"
	}

	set json_str "{"
	foreach {key value} $lst {
		append json_str "\"$key\": \"$value\","
	}
	# remove the last comma
	if {[string length $json_str] > 1} {
		set json_str [string range $json_str 0 end-1]
	}
	append json_str "}"
	return $json_str
}

# Generates random data
proc random_gen {length} {
	set fd [open "/dev/urandom" rb]
	set data [read $fd $length]
	close $fd
	binary encode hex $data
}

# Generates a random bucket value with a size between 1 and 200
proc random_val {} {
	set len [expr {int(rand() * 200) + 1}] 
	random_gen $len
}

# Generates a random bucket path
proc random_path {} {
	set path [random_gen 8]
	set dir1  [string range $path 0 1]
	set dir2  [string range $path 2 3]
	set file  [string range $path 4 end]
	return [list "$dir1/$dir2" $file]
}

# Example: bucket_add [json1 {name image2 size 100 type png}] [random_val]
# Example: bucket_get name image2 
# Example: bucket_get size 100
proc bucket_add {meta value} {
	sqlite3 db aerial.sq3

	# Check for free space in the existing bucket
	# For now, only one bucket at a time has free rows, but
	# when we start deleting rows in the buckets, 
	# random() can help
	set bucket_info [db eval "select rowid, dir, file from buckets 
		where rows < $::bucket_max_rows order by random() limit 1"]
	set random_key  [random_gen 32]

	if {[lindex $bucket_info 0] eq "" } {
		# No rowid, no free space in the existing bucket. 
		# Creating a new bucket, saving the key and the value
		set path  [random_path]
		set dir   [lindex	$path 0]
		set file  [lindex $path 1]
		file mkdir  "$::bucket_root/$dir"
		sqlite3 db2 "$::bucket_root/$dir/$file.sq3"
		db2 eval {create table if not exists bucket(key, value)}
		db2 eval {insert into bucket (key, value) values (:random_key, :value)}
		db2 close
		db eval {insert into buckets (dir, file, rows) 
			values (:dir, :file, 1)}
		db eval {insert into buckets_meta (dir, file, row_key, meta) 
			values (:dir, :file, :random_key, :meta)}
		puts "New bucket created"
	} else {
		# Found free space in the existing bucket, saving the key and the value
		set dir [lindex $bucket_info 1]
		set file [lindex $bucket_info 2]
		sqlite3 db2 "$::bucket_root/$dir/$file.sq3"
		db2 eval {insert into bucket (key, value) values (:random_key, :value)}
		db2 close
		db eval {update buckets set rows = (rows + 1) 
			where dir = :dir AND file = :file}
		db eval {insert into buckets_meta (dir, file, row_key, meta) 
			values (:dir, :file, :random_key, :meta)}
		puts "Existing bucket used"
	}

	db close
}

# Example: bucket_add [json1 {name image2 size 100 type png}] [random_val]
# Example: bucket_get name image2 
proc bucket_get {jsonkey jsonval {limit 1}} {

	sqlite3 db aerial.sq3
	if {$limit > 0} {
		set bucket_info [db eval "select dir, file, row_key from buckets_meta 
			where json_extract(meta, '\$.$jsonkey') = '$jsonval' limit $limit"]
	} else {
		set bucket_info [db eval "select dir, file, row_key from buckets_meta 
			where json_extract(meta, '\$.$jsonkey') = '$jsonval'"]
	}
	db close

	set i 1
	foreach {dir file row_key} $bucket_info {
		sqlite3 db "$::bucket_root/$dir/$file.sq3"
		set value [db eval {select value from bucket where key=:row_key}]
		puts "\[Value $i:\] $value"
		incr i
		db close
	}
}

proc aerial_init {} {
	sqlite3 db aerial.sq3
	db eval {create table if not exists buckets (dir, file, rows)}
	db eval {create table if not exists buckets_meta (dir, file, row_key, meta)}
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
