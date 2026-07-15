##########################################################################################################
#
# build.tcl: Tcl script for re-creating platform project 'OCT640_7A'
#
# Modified by: Mykola Konovalenko 15:00 28.01.2024
# Edited: 2025-10-15 — support -tclargs VHDL_STD {2008|""}; fix get_filesets -quiet ordering;
#                     set per-file VHDL 2008 + simulation flags; make sim_1 robustly exist.
#
##########################################################################################################

# --- Read -tclargs -----------------------------------------------------------------
# Example:
#   vivado -mode batch -source scripts/build.tcl -tclargs VHDL_STD 2008
set VHDL_STD ""
for {set i 0} {$i < [llength $argv]} {incr i} {
  set k [lindex $argv $i]
  if {$k eq "VHDL_STD"} {
    incr i
    set VHDL_STD [string trim [lindex $argv $i]]
  }
}
set USE2008 [expr {$VHDL_STD eq "2008"}]
# -----------------------------------------------------------------------------------

# Sourcing settings from external script (defines: $_xil_proj_name_, $_part_number_, $repository_dir,
# $_src_dir_, $_cnstr_dir_, $_sim_dir_, $_inst_top_name_, helper procs get_dir_list/get_file_list, etc.)
source $env(REPO_DIR)/scripts/settings.tcl

# Project directory
set project_dir "[file normalize "$repository_dir/project"]"
file mkdir $project_dir
cd $project_dir

# Create/open project
if {[file exists $_xil_proj_name_.xpr]} {
  open_project $_xil_proj_name_
} else {
  create_project $_xil_proj_name_ $project_dir -part $_part_number_
}

# Common handles
set proj_dir [get_property directory [current_project]]
set prj      [current_project]

# Project properties
set_property -name default_lib                     -value xil_defaultlib                -objects $prj
set_property -name enable_resource_estimation      -value 0                              -objects $prj
set_property -name enable_vhdl_2008                -value [expr {$USE2008 ? 1 : 0}]      -objects $prj
set_property -name ip_cache_permissions            -value {read write}                   -objects $prj
set_property -name ip_output_repo                  -value "$proj_dir/.cache/ip"          -objects $prj
set_property -name mem.enable_memory_map_generation -value 1                              -objects $prj
set_property -name revised_directory_structure     -value 1                              -objects $prj
set_property -name sim.central_dir                 -value "$proj_dir/.ip_user_files"     -objects $prj
set_property -name sim.ip.auto_export_scripts      -value 1                              -objects $prj
set_property -name simulator_language              -value Mixed                          -objects $prj
set_property -name sim_compile_state               -value 1                              -objects $prj
set_property -name webtalk.activehdl_export_sim    -value 2                              -objects $prj
set_property -name webtalk.modelsim_export_sim     -value 2                              -objects $prj
set_property -name webtalk.questa_export_sim       -value 2                              -objects $prj
set_property -name webtalk.riviera_export_sim      -value 2                              -objects $prj
set_property -name webtalk.vcs_export_sim          -value 2                              -objects $prj
set_property -name webtalk.xsim_export_sim         -value 2                              -objects $prj
set_property -name xpm_libraries                   -value XPM_CDC                        -objects $prj

## SOURCES ###############################################################################################

# Fileset
set src_fs [get_filesets -quiet sources_1]
if {![string length $src_fs]} {
  create_fileset -srcset sources_1
  set src_fs [get_filesets -quiet sources_1]
}

# Collect sources
set files [get_file_list [get_dir_list $_src_dir_] "sv,svh,v,vh,vhd,mif,bd"]

# Add sources
if {[llength $files]} {
  add_files -norecurse -fileset $src_fs $files
}

# File-type normalization
set sv_files   [get_files -of_objects $src_fs [list [lsearch -all -inline $files *.sv]]]
if {[llength $sv_files]} {
  set_property FILE_TYPE {SystemVerilog} $sv_files
}

set mif_files  [get_files -of_objects $src_fs [list [lsearch -all -inline $files *.mif]]]
if {[llength $mif_files]} {
  set_property FILE_TYPE {Memory Initialization Files} $mif_files
}

# VHDL file types: force VHDL 2008 when requested, otherwise plain VHDL
set vhdl_src_files [get_files -of_objects $src_fs -filter {FILE_EXT == vhd || FILE_TYPE =~ "VHDL*"}]
if {[llength $vhdl_src_files]} {
  if {$USE2008} {
    set_property FILE_TYPE {VHDL 2008} $vhdl_src_files
  } else {
    set_property FILE_TYPE {VHDL} $vhdl_src_files
  }
}

# sources_1 fileset properties
set_property -name dataflow_viewer_settings -value {min_width=16} -objects $src_fs
set_property -name top                      -value $_inst_top_name_ -objects $src_fs

## CLOCK WIZARD (example IP) #############################################################################

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
set ip_uf_dir  "$proj_dir/$_xil_proj_name_.ip_user_files"
set ip_simlib_dir "$proj_dir/$_xil_proj_name_.cache/compile_simlib"

generate_target {instantiation_template} [get_files $ip_src_dir/clk_wiz_0/clk_wiz_0.xci]
update_compile_order -fileset $src_fs
generate_target all [get_files $ip_src_dir/clk_wiz_0/clk_wiz_0.xci]

catch { config_ip_cache -export [get_ips -all clk_wiz_0] }
export_ip_user_files -of_objects [get_files $ip_src_dir/clk_wiz_0/clk_wiz_0.xci] \
  -no_script -sync -force -quiet
export_simulation -of_objects [get_files $ip_src_dir/clk_wiz_0/clk_wiz_0.xci] \
  -directory $ip_uf_dir/sim_scripts -ip_user_files_dir $ip_uf_dir \
  -ipstatic_source_dir $ip_uf_dir/ipstatic \
  -lib_map_path [list {modelsim=$ip_simlib_dir/modelsim} {questa=$ip_simlib_dir/questa} \
                       {xcelium=$ip_simlib_dir/xcelium} {vcs=$ip_simlib_dir/vcs} \
                       {riviera=$ip_simlib_dir/riviera}] \
  -use_ip_compiled_libs -force -quiet

# Mark IP file properties
set clkxci [get_files -of_objects $src_fs [list "*clk_wiz_0/clk_wiz_0.xci"]]
if {[llength $clkxci]} {
  set_property generate_files_for_reference 0 $clkxci
  set_property registered_with_manager      1 $clkxci
  if { ![get_property is_locked $clkxci] } {
    set_property synth_checkpoint_mode Singular $clkxci
  }
}

## CONSTRAINTS ###########################################################################################

set xdc_fs [get_filesets -quiet constrs_1]
if {![string length $xdc_fs]} {
  create_fileset -constrset constrs_1
  set xdc_fs [get_filesets -quiet constrs_1]
}

set cnstr_files [get_file_list [get_dir_list $_cnstr_dir_] "xdc,sdc"]
if {[llength $cnstr_files]} {
  add_files -norecurse -fileset $xdc_fs $cnstr_files
  set xdc_only [get_files -of_objects $xdc_fs [list [lsearch -all -inline $cnstr_files *.xdc]]]
  if {[llength $xdc_only]} {
    set_property FILE_TYPE {XDC} $xdc_only
  }
}

## SIMULATION ############################################################################################

# Ensure sim_1 exists
set sim_fs [get_filesets -quiet sim_1]
if {![string length $sim_fs]} {
  create_fileset -simset sim_1
  set sim_fs [get_filesets -quiet sim_1]
}

# Add sim sources (if any found)
set sim_files [get_file_list [get_dir_list $_sim_dir_] "v,sv,vhd"]
if {[llength $sim_files]} {
  add_files -norecurse -fileset $sim_fs $sim_files
}

# Apply VHDL-2008 per-file in sim set
set vhdl_sim_files [get_files -of_objects $sim_fs -filter {FILE_EXT == vhd || FILE_TYPE =~ "VHDL*"}]
if {[llength $vhdl_sim_files]} {
  if {$USE2008} {
    set_property FILE_TYPE {VHDL 2008} $vhdl_sim_files
  } else {
    set_property FILE_TYPE {VHDL} $vhdl_sim_files
  }
}

# Simulator flags
if {$USE2008} {
  # XSim
  set_property xvhdl.more_options {-2008}     $sim_fs
  # 3rd-party (best-effort, guarded by catch)
  catch { set_property modelsim.vcom.more_options {-2008}  $sim_fs }
  catch { set_property riviera.vcom.more_options  {-2008}  $sim_fs }
} else {
  foreach p {xvhdl.more_options xelab.more_options modelsim.vcom.more_options riviera.vcom.more_options} {
    catch { set_property $p {} $sim_fs }
  }
}

# sim_1 properties
set_property -name top      -value $_inst_top_name_ -objects $sim_fs
set_property -name top_lib  -value xil_defaultlib   -objects $sim_fs

## DONE ##################################################################################################

# Save project (optional) and exit when running in batch
# catch { save_project_as $_xil_proj_name_ $project_dir -force }
exit
