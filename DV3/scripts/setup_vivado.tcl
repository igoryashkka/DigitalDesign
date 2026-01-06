# Vivado automation script for DXI UVM simulation
# Creates/refreshes a project, adds RTL + UVM sources, and optionally launches simulation.

set script_dir [file normalize [file dirname [info script]]]
set proj_name "dxi_uvm"
set proj_root [file normalize [file join $script_dir ".."]]
set repo_root [file normalize [file join $proj_root ".."]]
set src_root  [file join $proj_root "sources"]
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
puts "Project dir : $proj_dir"
puts "Action      : $action"
puts "Sim mode    : $sim_mode"

# Reusable clean helper
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

# Create project and set up simulator
create_project -force $proj_name $proj_dir -part $part_name
# Vivado requires a concrete target language; mixed-language designs are still supported with this setting.
set_property target_language VHDL [current_project]
# Vivado expects the target simulator name to use the canonical casing.
set_property target_simulator XSim [current_project]

# RTL interfaces and DUT
set rtl_files [list \
  [file join $src_root rtl dxi_if.sv] \
  [file join $src_root rtl config_if.sv] \
  [file join $src_root rtl filter.vhd]
]

# UVM environment + testbench (package includes all dxi_* sources)
set tb_files [list \
  [file join $src_root dxi_pkg.sv] \
  [file join $src_root simulation tb tb_top.sv]
]

# Ensure includes resolve for files pulled in by dxi_pkg.sv
set_property include_dirs [list \
  $src_root \
  [file join $src_root simulation] \
] [get_filesets sim_1]

# Add files to simulation set
add_files -fileset sim_1 $rtl_files
add_files -fileset sim_1 $tb_files
set_property file_type {VHDL 2008} [get_files [file join $src_root rtl filter.vhd]]

# Configure simulation top
set_property top tb_top [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

if { $action eq "sim" } {
  puts "Launching behavioral simulation..."
  if { $sim_mode eq "tcl" } {
    # Generate scripts only, then run xsim in batch (no GUI)
    launch_simulation -mode behavioral -scripts_only
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
    # Run the generated compile/elaborate scripts to build the snapshot
    set orig_dir [pwd]
    cd $sim_dir
    foreach script [list $compile_script $elaborate_script] {
      puts "Running $script..."
      if {$tcl_platform(platform) eq "windows"} {
        exec cmd /c $script
      } else {
        exec sh $script
      }
    }
    cd $orig_dir
    # Vivado no longer produces run.tcl automatically in scripts-only mode; always create one
    # with a generous runtime so long tests can complete.
    set sim_duration "10 ms"
    puts "Writing run.tcl with simulation duration $sim_duration"
    set fh [open $run_tcl "w"]
    puts $fh "run $sim_duration"
    puts $fh {quit}
    close $fh
    # Normalize plusargs from wrapper (allow users to pass "+UVM_TESTNAME=foo" or "foo").
    set xsim_cmd [list xsim $snapshot -tclbatch $run_tcl]
    if {[info exists ::env(UVM_TESTNAME)]} {
      set testname $::env(UVM_TESTNAME)
      if {[string match "+UVM_TESTNAME=*" $testname]} {
        set testname [string range $testname 14 end]
      } elseif {[string match "+*" $testname]} {
        set testname [string range $testname 1 end]
      }
      if {$testname ne ""} {
        puts "Applying UVM_TESTNAME=$testname"
        lappend xsim_cmd --testplusarg "UVM_TESTNAME=$testname"
      }
    }
    if {[info exists ::env(IMG_FILE)] && $::env(IMG_FILE) ne ""} {
      set img_arg $::env(IMG_FILE)
      if {[string match "+IMG_FILE=*" $img_arg]} {
        set img_arg [string range $img_arg 10 end]
      } elseif {[string match "+*" $img_arg]} {
        set img_arg [string range $img_arg 1 end]
      }
      puts "Applying IMG_FILE=$img_arg"
      lappend xsim_cmd --testplusarg "IMG_FILE=$img_arg"
    }
    puts "Running xsim in batch: $xsim_cmd"
    exec {*}$xsim_cmd
  } else {
    # Default: open the simulator GUI
    launch_simulation -mode behavioral
  }
} elseif { $action eq "elab" } {
  puts "Running elaboration only..."
  launch_simulation -step elab -mode behavioral
} elseif { $action eq "clean" } {
  puts "Clean option is handled by the wrapper script; no project created."
} else {
  puts "Project generated at $proj_dir"
  puts "Use Vivado GUI or rerun this script with 'sim' to launch simulation."
}
