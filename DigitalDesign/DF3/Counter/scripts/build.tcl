##########################################################################################################
#
# build.tcl: Tcl script for re-creating platform project 'OCT640_7A'
#
# Modified by: Mykola Konovalenko 15:00 28.01.2024
#
##########################################################################################################

# Sourcing setiings from external script
source $env(REPO_DIR)/scripts/settings.tcl

# Set the directory path for the original project from where this script was exported
set project_dir "[file normalize "$repository_dir/project"]"
file mkdir $project_dir

cd $project_dir

# Create project
if {[file exists $_xil_proj_name_.xpr]} {
	open_project $_xil_proj_name_
} else {
	create_project $_xil_proj_name_ $project_dir -part $_part_number_
}

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [current_project]
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "enable_resource_estimation" -value "0" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "revised_directory_structure" -value "1" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj
set_property -name "sim_compile_state" -value "1" -objects $obj
set_property -name "webtalk.activehdl_export_sim" -value "2" -objects $obj
set_property -name "webtalk.modelsim_export_sim" -value "2" -objects $obj
set_property -name "webtalk.questa_export_sim" -value "2" -objects $obj
set_property -name "webtalk.riviera_export_sim" -value "2" -objects $obj
set_property -name "webtalk.vcs_export_sim" -value "2" -objects $obj
set_property -name "webtalk.xsim_export_sim" -value "2" -objects $obj
set_property -name "xpm_libraries" -value "XPM_CDC" -objects $obj


## SOURCES
# Set 'sources_1' fileset object
set obj [get_filesets sources_1]

# Search for rtl and memory files in repository
set files [get_file_list [get_dir_list $_src_dir_] "sv,svh,v,vh,vhd,mif"]

# Add source files to design
add_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset file properties for local files
set file_obj [get_files -of_objects $obj [list [lsearch -all -inline $files *.sv]]]
if {[llength $file_obj]} { set_property -name "file_type" -value "SystemVerilog" -objects $file_obj }

set file_obj [get_files -of_objects $obj [list [lsearch -all -inline $files *.mif]]]
if {[llength $file_obj]} { set_property -name "file_type" -value "Memory Initialization Files" -objects $file_obj }

# Set 'sources_1' fileset properties
set_property -name "dataflow_viewer_settings" -value "min_width=16" -objects $obj
set_property -name "top" -value "$_inst_top_name_" -objects $obj

# Configure clk_wiz_0 IP and set 2 clocks: 60MHz and 100MHz
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [list \
  CONFIG.CLKIN1_JITTER_PS {80.0} \
  CONFIG.CLKOUT1_DRIVES {BUFG} \
  CONFIG.CLKOUT1_JITTER {261.690} \
  CONFIG.CLKOUT1_PHASE_ERROR {249.865} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {60.000} \
  CONFIG.CLKOUT2_DRIVES {BUFG} \
  CONFIG.CLKOUT2_JITTER {237.312} \
  CONFIG.CLKOUT2_PHASE_ERROR {249.865} \
  CONFIG.CLKOUT2_USED {true} \
  CONFIG.CLKOUT3_DRIVES {BUFG} \
  CONFIG.CLKOUT4_DRIVES {BUFG} \
  CONFIG.CLKOUT5_DRIVES {BUFG} \
  CONFIG.CLKOUT6_DRIVES {BUFG} \
  CONFIG.CLKOUT7_DRIVES {BUFG} \
  CONFIG.JITTER_SEL {No_Jitter} \
  CONFIG.MMCM_CLKFBOUT_MULT_F {36.000} \
  CONFIG.MMCM_CLKIN1_PERIOD {8.000} \
  CONFIG.MMCM_CLKIN2_PERIOD {10.000} \
  CONFIG.MMCM_CLKOUT0_DIVIDE_F {15.000} \
  CONFIG.MMCM_CLKOUT0_DUTY_CYCLE {0.5} \
  CONFIG.MMCM_CLKOUT1_DIVIDE {9} \
  CONFIG.MMCM_CLKOUT1_DUTY_CYCLE {0.5} \
  CONFIG.MMCM_DIVCLK_DIVIDE {5} \
  CONFIG.NUM_OUT_CLKS {2} \
  CONFIG.PRIM_IN_FREQ {125.000} \
  CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin} \
  CONFIG.USE_LOCKED {true} \
  CONFIG.USE_MIN_POWER {true} \
  CONFIG.USE_PHASE_ALIGNMENT {false} \
] [get_ips clk_wiz_0]

set ip_src_dir "$proj_dir/$_xil_proj_name_.srcs/sources_1/ip"
set ip_uf_dir "$proj_dir/$_xil_proj_name_.ip_user_files"
set ip_simlib_dir "$proj_dir/$_xil_proj_name_.cache/compile_simlib"

generate_target {instantiation_template} [get_files $ip_src_dir/clk_wiz_0/clk_wiz_0.xci]
update_compile_order -fileset sources_1
generate_target all [get_files  $ip_src_dir/clk_wiz_0/clk_wiz_0.xci]

catch { config_ip_cache -export [get_ips -all clk_wiz_0] }
export_ip_user_files -of_objects [get_files $ip_src_dir/clk_wiz_0/clk_wiz_0.xci] \
		-no_script -sync -force -quiet
export_simulation -of_objects [get_files $ip_src_dir/clk_wiz_0/clk_wiz_0.xci] \
	-directory $ip_uf_dir/sim_scripts -ip_user_files_dir $ip_uf_dir \
	-ipstatic_source_dir $ip_uf_dir/ipstatic \
	-lib_map_path [list {modelsim=$ip_simlib_dir/modelsim} {questa=$ip_simlib_dir/questa} \
		{xcelium=$ip_simlib_dir/xcelium} {vcs=$ip_simlib_dir/vcs} {riviera=$ip_simlib_dir/riviera}] \
	-use_ip_compiled_libs -force -quiet

# Set 'sources_1' fileset file properties for local files
set file "clk_wiz_0/clk_wiz_0.xci"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property -name "generate_files_for_reference" -value "0" -objects $file_obj
set_property -name "registered_with_manager" -value "1" -objects $file_obj
if { ![get_property "is_locked" $file_obj] } {
	set_property -name "synth_checkpoint_mode" -value "Singular" -objects $file_obj
}


## CONSTRAINTS
# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Search for constraint files in set folders
set files [get_file_list [get_dir_list $_cnstr_dir_] "xdc,sdc"]

# Add source files to design
add_files -norecurse -fileset $obj $files

# Add/Import constrs file and set constrs file properties
set file_obj [get_files -of_objects $obj [list [lsearch -all -inline $files *.xdc]]]
if {[llength $file_obj]} { set_property -name "file_type" -value "XDC" -objects $file_obj }


## SIMULATION
# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
# Empty (no sources present)

# Search for simulation files in set location
set files [get_file_list [get_dir_list $_sim_dir_] "v,sv,vhd"]
if {[llength $files]} {
  add_files -norecurse -fileset $obj $files
}

# Set 'sim_1' fileset properties
set_property -name "top" -value "$_inst_top_name_" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj

exit
