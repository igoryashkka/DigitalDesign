# Vivado automation for FPGA0/tft_lcd/st7789.
# Usage examples:
#   vivado -mode batch -source scripts/run_vivado.tcl -tclargs build 1 1 1
#   vivado -mode gui   -source scripts/run_vivado.tcl -tclargs open
#   vivado -mode batch -source scripts/run_vivado.tcl -tclargs clean

set script_dir [file normalize [file dirname [info script]]]
source [file join $script_dir "settings.tcl"]

set action "open"
set synth_flag 1
set impl_flag 1
set bit_flag 1

if {$argc > 0} { set action [string tolower [lindex $argv 0]] }
if {$argc > 1} { set synth_flag [lindex $argv 1] }
if {$argc > 2} { set impl_flag [lindex $argv 2] }
if {$argc > 3} { set bit_flag [lindex $argv 3] }

proc collect_files_recursive {root patterns} {
  set files {}
  if {![file exists $root]} {
    return $files
  }

  foreach p $patterns {
    foreach f [glob -nocomplain -types f -directory $root $p] {
      lappend files [file normalize $f]
    }
  }

  foreach d [glob -nocomplain -types d -directory $root *] {
    set files [concat $files [collect_files_recursive $d $patterns]]
  }

  return $files
}

proc refresh_fileset {fileset_name files} {
  set fs [get_filesets $fileset_name]
  set existing [get_files -quiet -of_objects $fs]
  if {[llength $existing] > 0} {
    catch {remove_files -fileset $fs $existing}
  }

  if {[llength $files] > 0} {
    add_files -norecurse -fileset $fs $files
  }
}

proc check_run_complete {run_name} {
  set status [get_property STATUS [get_runs $run_name]]
  if {![string match "*Complete*" $status] || [string match "*Error*" $status]} {
    puts "ERROR: $run_name failed or is incomplete. Status: $status"
    return -code error "$run_name status: $status"
  }
  puts "$run_name completed. Status: $status"
}

proc run_build {project_dir proj_name top_name synth_flag impl_flag bit_flag} {
  if {$bit_flag == 1} {
    set impl_flag 1
  }
  if {$impl_flag == 1} {
    set synth_flag 1
  }

  puts "Build flags after dependency normalization:"
  puts "  synth=$synth_flag impl=$impl_flag bit=$bit_flag"

  if {$synth_flag == 1} {
    puts "Starting synthesis..."
    reset_run synth_1
    launch_runs synth_1 -jobs 4
    wait_on_run synth_1
    check_run_complete synth_1
  }

  if {$impl_flag == 1} {
    puts "Starting implementation..."
    reset_run impl_1
    launch_runs impl_1 -jobs 4
    wait_on_run impl_1
    check_run_complete impl_1
  }

  if {$bit_flag == 1} {
    puts "Starting bitstream generation..."
    launch_runs impl_1 -to_step write_bitstream -jobs 4
    wait_on_run impl_1
    check_run_complete impl_1

    set bit_dir [file join $project_dir "${proj_name}.runs" "impl_1"]
    set bit_files [glob -nocomplain -directory $bit_dir "*.bit"]
    if {[llength $bit_files] == 0} {
      return -code error "Bitstream was not generated in $bit_dir"
    }

    puts "Bitstream generated:"
    foreach b $bit_files {
      puts "  [file normalize $b]"
    }
  }
}

proc clean_artifacts {project_dir repo_dir script_dir} {
  foreach p [list \
      $project_dir \
      [file join $repo_dir ".Xil"] \
      [file join $repo_dir "xsim.dir"]] {
    if {[file exists $p]} {
      puts "Removing $p"
      file delete -force -- $p
    }
  }

  foreach dir [list $script_dir $repo_dir] {
    foreach pattern [list "vivado.jou" "vivado.log" "*.jou" "*.jou.*" "*.log" "*.log.*"] {
      foreach f [glob -nocomplain -directory $dir $pattern] {
        puts "Removing $f"
        file delete -force $f
      }
    }
  }
}

puts "Project root : $repository_dir"
puts "Project dir  : $_project_dir_"
puts "Action       : $action"

if {$action eq "clean"} {
  clean_artifacts $_project_dir_ $repository_dir $script_dir
  puts "Clean completed."
  exit 0
}

file mkdir $_project_dir_
set project_file [file join $_project_dir_ "${_xil_proj_name_}.xpr"]

if {[file exists $project_file]} {
  open_project $project_file
  puts "Opened existing project: $project_file"
} else {
  create_project $_xil_proj_name_ $_project_dir_ -part $_part_number_
  puts "Created project: $project_file"
}

set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set_property default_lib xil_defaultlib [current_project]

set src_files [collect_files_recursive $_src_dir_ [list "*.sv" "*.svh" "*.v" "*.vh" "*.vhd" "*.vhdl"]]
if {[llength $src_files] == 0} {
  puts "ERROR: No RTL files found in $_src_dir_"
  close_project
  exit 1
}

refresh_fileset sources_1 $src_files

set sv_files [lsearch -all -inline $src_files *.sv]
if {[llength $sv_files] > 0} {
  set_property file_type SystemVerilog [get_files $sv_files]
}
set vhd_files [concat [lsearch -all -inline $src_files *.vhd] [lsearch -all -inline $src_files *.vhdl]]
if {[llength $vhd_files] > 0} {
  set_property file_type "VHDL 2008" [get_files $vhd_files]
}

# Create/update clock wizard IP for 200 MHz differential clock input.
if {[llength [get_ips -quiet clk_wiz_0]] == 0} {
  create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name clk_wiz_0
}

set_property -dict [list \
  CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
  CONFIG.PRIM_IN_FREQ {200.000} \
  CONFIG.NUM_OUT_CLKS {1} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.000} \
  CONFIG.CLKOUT1_REQUESTED_DUTY_CYCLE {0.500} \
  CONFIG.CLKOUT1_REQUESTED_PHASE {0.000} \
  CONFIG.RESET_PORT {resetn} \
  CONFIG.RESET_TYPE {ACTIVE_LOW} \
  CONFIG.USE_LOCKED {true} \
  CONFIG.USE_MIN_POWER {true} \
] [get_ips clk_wiz_0]

set proj_dir [get_property directory [current_project]]
set xci_file [file join $proj_dir "${_xil_proj_name_}.srcs" "sources_1" "ip" "clk_wiz_0" "clk_wiz_0.xci"]

if {[file exists $xci_file]} {
  generate_target all [get_files $xci_file]
  catch {config_ip_cache -export [get_ips -all clk_wiz_0]}
}

set_property top $_inst_top_name_ [get_filesets sources_1]
update_compile_order -fileset sources_1

set cnstr_files [collect_files_recursive $_cnstr_dir_ [list "*.xdc" "*.sdc"]]
refresh_fileset constrs_1 $cnstr_files
if {[llength $cnstr_files] > 0} {
  set xdc_files [lsearch -all -inline $cnstr_files *.xdc]
  if {[llength $xdc_files] > 0} {
    set_property file_type XDC [get_files $xdc_files]
  }
}

if {$action eq "open"} {
  puts "Project prepared and opened in GUI."
  puts "Top module: $_inst_top_name_"
} elseif {$action eq "build"} {
  if {[catch {run_build $_project_dir_ $_xil_proj_name_ $_inst_top_name_ $synth_flag $impl_flag $bit_flag} err]} {
    puts "ERROR: $err"
    close_project
    exit 1
  }
  close_project
  puts "Build finished."
  exit 0
} else {
  puts "ERROR: Unsupported action '$action'. Use open, build, or clean."
  close_project
  exit 1
}
