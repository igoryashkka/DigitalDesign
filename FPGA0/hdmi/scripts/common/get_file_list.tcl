proc get_file_list { dir_list type_list } {
	set file_list {}
	while {[llength $dir_list]} {
		set files [glob -type f -nocomplain -directory [lindex $dir_list 0] *.{$type_list}]
		if {[llength $files]} {
			set file_list [concat $file_list $files]
		}
		set dir_list [lrange $dir_list 1 end]
	}
	return $file_list
}
