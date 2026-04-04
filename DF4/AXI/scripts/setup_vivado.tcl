# Vivado automation script for DF4 AXI UVM simulation
# DUT1: DF4/AXI interconnect RTL
# DUT2: DF4/AXI_Slave_example/sources/rtl/axi_gpio

set script_dir [file normalize [file dirname [info script]]]
set proj_name "axi_df4_uvm"
set proj_root [file normalize [file join $script_dir ".."]]
set repo_root [file normalize [file join $proj_root ".." ".."]]
set src_root  [file join $proj_root "sources"]
set gpio_root [file normalize [file join $proj_root ".." "AXI_Slave_example" "sources" "rtl" "axi_gpio"]]
set proj_dir  [file normalize [file join $proj_root "vivado_project"]]
set part_name "xc7a35tcpg236-1"
set action "sim"
set sim_mode "gui"

if { $argc > 0 } {
  set action [lindex $argv 0]
}
if { $argc > 1 } {
  set sim_mode [lindex $argv 1]
}

puts "Project root: $proj_root"
puts "GPIO root   : $gpio_root"
puts "Project dir : $proj_dir"
puts "Action      : $action"
puts "Sim mode    : $sim_mode"

proc clean_artifacts {proj_dir proj_root script_dir repo_root} {
  foreach path [list \
      $proj_dir \
      [file join $proj_root "xsim.dir"] \
      [file join $proj_root ".Xil"]] {
    if {[file exists $path]} {
      puts "Removing $path"
      file delete -force -recursive $path
    }
  }

  foreach dir [list $script_dir $proj_root $repo_root] {
    foreach pattern [list "vivado.jou" "vivado.log" "*.jou" "*.jou.*" "*.log" "*.log.*"] {
      foreach f [glob -nocomplain -directory $dir $pattern] {
        puts "Removing $f"
        file delete -force $f
      }
    }
  }
}

if { $action eq "clean" } {
  clean_artifacts $proj_dir $proj_root $script_dir $repo_root
  puts "Clean completed. Exiting."
  return
}

create_project -force $proj_name $proj_dir -part $part_name
set_property target_language VHDL [current_project]
set_property target_simulator XSim [current_project]

set dut1_files [list \
  [file join $src_root rtl axi_rr_arbiter.vhd] \
  [file join $src_root rtl axi_interconnect_write.vhd] \
  [file join $src_root rtl axi_interconnect_read.vhd] \
  [file join $src_root rtl axi_lite_interconnect_top.vhd]
]

set dut2_files [list \
  [file join $gpio_root axi_gpio.vhd] \
  [file join $gpio_root gpio_regs.vhd] \
  [file join $gpio_root top_gpio.vhd]
]

set tb_files [list \
  [file join $src_root simulation interfaces axi_lite_if.sv] \
  [file join $src_root simulation tb_pkg.sv] \
  [file join $src_root simulation tb tb_top.sv]
]

set_property include_dirs [list \
  $src_root \
  [file join $src_root simulation] \
] [get_filesets sim_1]

add_files -fileset sim_1 $dut1_files
add_files -fileset sim_1 $dut2_files
add_files -fileset sim_1 $tb_files

set_property file_type {VHDL 2008} [get_files $dut1_files]
set_property file_type {VHDL 2008} [get_files $dut2_files]

set_property top tb_top [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1
set_property xsim.simulate.runtime {10 ms} [get_filesets sim_1]

proc parse_plusargs {} {
  set result [dict create testname ""]

  if {[info exists ::env(UVM_TESTNAME)]} {
    set testname [string trim $::env(UVM_TESTNAME)]
    if {[string match "+UVM_TESTNAME=*" $testname]} {
      set testname [string range $testname 14 end]
    } elseif {[string match "+*" $testname]} {
      set testname [string range $testname 1 end]
    }
    dict set result testname $testname
  }

  return $result
}

proc print_log_file {path title} {
  if {![file exists $path]} {
    puts "LOG: $title not found at $path"
    return
  }

  puts "===== BEGIN $title ====="
  set fh [open $path "r"]
  set data [read $fh]
  close $fh
  puts $data
  puts "===== END $title ====="
}

proc build_and_run_xsim {proj_dir proj_name sim_mode plusargs} {
  global tcl_platform
  set sim_dir [file normalize [file join $proj_dir "${proj_name}.sim" "sim_1" "behav" "xsim"]]
  set script_ext [expr {$tcl_platform(platform) eq "unix" ? "sh" : "bat"}]
  set compile_script [file join $sim_dir "compile.$script_ext"]
  set elaborate_script [file join $sim_dir "elaborate.$script_ext"]
  set run_tcl [file join $sim_dir "run.tcl"]
  set snapshot "tb_top_behav"

  foreach script [list $compile_script $elaborate_script] {
    if {![file exists $script]} {
      error "Expected generated script not found at $script"
    }
  }

  set orig_dir [pwd]
  cd $sim_dir
  foreach script [list $compile_script $elaborate_script] {
    puts "Running $script..."
    if {$tcl_platform(platform) eq "windows"} {
      exec cmd /c $script
    } else {
      exec sh $script
    }

    if {[string match "*compile.*" $script]} {
      print_log_file [file join $sim_dir "compile.log"] "COMPILE LOG"
    } elseif {[string match "*elaborate.*" $script]} {
      print_log_file [file join $sim_dir "elaborate.log"] "ELABORATE LOG"
    }
  }
  cd $orig_dir

  set sim_duration "10 ms"
  puts "Writing run.tcl with simulation duration $sim_duration"
  set fh [open $run_tcl "w"]
  puts $fh "run $sim_duration"
  if {$sim_mode eq "tcl"} {
    puts $fh {quit}
  }
  close $fh

  set xsim_cmd [list xsim $snapshot]
  if {$sim_mode eq "gui"} {
    lappend xsim_cmd -gui -tclbatch $run_tcl -log simulate.log
  } else {
    lappend xsim_cmd -tclbatch $run_tcl -log simulate.log
  }

  set testname [dict get $plusargs testname]
  if {$testname ne ""} {
    puts "Applying UVM_TESTNAME=$testname"
    lappend xsim_cmd --testplusarg "UVM_TESTNAME=$testname"
  }

  set orig_dir_xsim [pwd]
  cd $sim_dir
  puts "Running xsim (cwd=$sim_dir): $xsim_cmd"
  if {[catch {set xsim_out [exec {*}$xsim_cmd]} xsim_err]} {
    if {[info exists xsim_out] && $xsim_out ne ""} {
      puts $xsim_out
    }
    puts $xsim_err
    print_log_file [file join $sim_dir "simulate.log"] "SIMULATE LOG"
    cd $orig_dir_xsim
    error $xsim_err
  }
  if {[info exists xsim_out] && $xsim_out ne ""} {
    puts $xsim_out
  }
  print_log_file [file join $sim_dir "simulate.log"] "SIMULATE LOG"
  cd $orig_dir_xsim
}

if { $action eq "sim" } {
  puts "Launching behavioral simulation..."
  set plusargs [parse_plusargs]

  if { $sim_mode eq "tcl" || $sim_mode eq "gui" } {
    launch_simulation -mode behavioral -scripts_only
    build_and_run_xsim $proj_dir $proj_name $sim_mode $plusargs
  } else {
    launch_simulation -mode behavioral
  }
} elseif { $action eq "elab" } {
  puts "Running elaboration only..."
  launch_simulation -step elaborate -mode behavioral
} else {
  puts "Project generated at $proj_dir"
  puts "Use Vivado GUI or rerun this script with 'sim' to launch simulation."
}
