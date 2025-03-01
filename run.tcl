# ---------------------------------------------------------------------
# Copyright (c) 2025, Ufko.org
# Licensed under the Apache License, Version 2.0. 
# See LICENSE file in the project root for details.
# ---------------------------------------------------------------------

source config.tcl

# Generates random data
proc random_gen {length} {
	set fd [open "/dev/urandom" rb]
	set data [read $fd $length]
	close $fd
	binary encode hex $data
}

# Generates a random bucket value with a size between 1 and -max (default 200)
# or the value of fixed length -fixed
proc random_val {args} {

	# Set default values for the named parameters
	array set opt [concat {-max 200 -fixed 0} $args]
		
	# Check if -max and -fixed are even numbers
	if {($opt(-max) % 2 != 0)} {
		error "Argument '-max' must be an even number."
	}
	if {($opt(-fixed) % 2 != 0) && $opt(-fixed) != 0} {
		error "Argument '-fixed' must be an even number or default (for random length)."
	}

	# Generate a fixed length
	if {$opt(-fixed) != 0} {
		set len $opt(-fixed)
	} else {
		# Generate a random length in the range 2 - $opt(-max), ensuring it's even
		set len [expr {int(rand() * ($opt(-max) / 2)) * 2 + 2}]
	}

	set byte_length [expr {$len / 2}]
	set data [random_gen $byte_length]
	return [string range $data 0 [expr {$len - 1}]]
}

# Generates a random bucket path
proc random_path {} {
	set path [random_gen 8]
	set dir1  [string range $path 0 1]
	set dir2  [string range $path 2 3]
	set file  [string range $path 4 end]
	return [list "$dir1/$dir2" $file]
}

# Example: bucket_add user:1:name [random_val]
# Example: bucket_add image:png:123 [random_val]
# Example: bucket_add "free hand key :)" [random_val]
proc bucket_add {ukey value} {
	sqlite3 db aerial.sq3

	# Check for free space in the existing bucket
	# For now, only one bucket at a time has free rows, but
	# when we start deleting rows in the buckets, 
	# random() can help
	set bucket_info [db eval "select rowid, dir, file from buckets 
		where rows < $::bucket_max_rows order by random() limit 1"]
	set bkey [random_gen 32]

	if {[lindex $bucket_info 0] eq "" } {
		# No rowid, no free space in the existing bucket. 
		# Creating a new bucket, saving the key and the value
		set path  [random_path]
		set dir   [lindex	$path 0]
		set file  [lindex $path 1]
		file mkdir  "$::bucket_root/$dir"
		sqlite3 db2 "$::bucket_root/$dir/$file.sq3"
		db2 eval {create table if not exists bucket(bkey, value)}
		db2 eval {insert into bucket (bkey, value) values (:bkey, :value)}
		db2 close
		db eval {insert into buckets (dir, file, rows) 
			values (:dir, :file, 1)}
		db eval {insert into buckets_meta (dir, file, bkey, key) 
			values (:dir, :file, :bkey, :ukey)}
		puts "New bucket created"
	} else {
		# Found free space in the existing bucket, saving the key and the value
		set dir [lindex $bucket_info 1]
		set file [lindex $bucket_info 2]
		sqlite3 db2 "$::bucket_root/$dir/$file.sq3"
		db2 eval {insert into bucket (bkey, value) values (:bkey, :value)}
		db2 close
		db eval {update buckets set rows = (rows + 1) 
			where dir = :dir AND file = :file}
		db eval {insert into buckets_meta (dir, file, bkey, key) 
			values (:dir, :file, :bkey, :ukey)}
		puts "Existing bucket used"
	}

	db close
}

# Example: bucket_add [json1 {name image2 size 100 type png}] [random_val]
# Example: bucket_get name image2 
proc bucket_get {ukey {limit 1}} {

	sqlite3 db aerial.sq3
	# If ukey contains "*", replace it with "%" for SQL LIKE query
  if {[string match "*\**" $ukey]} {
    set ukey [string map {"*" "%"} $ukey]
    set sql "SELECT dir, file, bkey FROM buckets_meta WHERE key LIKE '$ukey' LIMIT $limit;"
  } else {
    # If no "*", perform an exact match query
    set sql "SELECT dir, file, bkey FROM buckets_meta WHERE key = '$ukey';"
  }
	#puts $sql
	set bucket_info [db eval $sql]
	db close

	set i 1
	foreach {dir file bkey} $bucket_info {
		sqlite3 db "$::bucket_root/$dir/$file.sq3"
		set value [db eval {select value from bucket where bkey=:bkey}]
		puts "\[Value $i:\] $value"
		incr i
		db close
	}
}

proc aerial_init {} {
	sqlite3 db aerial.sq3
	db eval {create table if not exists buckets (dir, file, rows)}
	db eval {create table if not exists buckets_meta (dir, file, bkey unique, key unique)}
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
