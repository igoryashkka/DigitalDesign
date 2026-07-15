# Project settings for ST7789 automation.

set scripts_dir    [file normalize [file dirname [info script]]]
set repository_dir [file normalize [file dirname $scripts_dir]]

set _xil_proj_name_ "st7789_project"
set _inst_top_name_ "lcd_top"

# Update this part if you target another FPGA.
set _part_number_ "xc7a35tfgg484-2"

set _src_dir_     [file join $repository_dir "sources"]
set _cnstr_dir_   [file join $repository_dir "constraints"]
set _sim_dir_     [file join $repository_dir "simulation"]
set _project_dir_ [file join $repository_dir "project"]
