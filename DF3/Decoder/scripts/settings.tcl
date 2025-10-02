##########################################################################################################
# settings.tcl: Tcl script for configuration user paremeters
#
# Modified by: Mykola Konovalenko 15:00 28.01.2024
#
##########################################################################################################

# reference project directory configuration
set scripts_dir [file dirname [info script]]
set repository_dir [file dirname $scripts_dir]

# Search for include TCL scripts
foreach scr_file [glob -type f -nocomplain "$scripts_dir/common/*.tcl"] {
	source -notrace $scr_file
}

# project name
set _xil_proj_name_	"test_project_zybo_z7"

# top instanse name
set _inst_top_name_	"Zybo_Z7_top"
set _sw_top_name_	"zybo_test"

# part number
set _part_number_	"xc7z020clg400-1"

# sources folders to scan
set _src_dir_	"$repository_dir/sources"

# constraint folder to scan
set _cnstr_dir_	"$repository_dir/constraints"

# simulation file folder to scan
set _sim_dir_	"$repository_dir/sim"
