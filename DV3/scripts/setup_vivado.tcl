# Vivado automation script for DXI UVM simulation
# Creates/refreshes a project, adds RTL + UVM sources, and optionally launches simulation.

set script_dir [file normalize [file dirname [info script]]]
set proj_name "dxi_uvm"
set proj_root [file normalize [file join $script_dir ".."]]
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
proc clean_artifacts {proj_dir proj_root script_dir} {
  foreach path [list \
      $proj_dir \
      [file join $proj_root "xsim.dir"] \
      [file join $proj_root ".Xil"]] {
    if {[file exists $path]} {
      puts "Removing $path"
      file delete -force -recursive $path
    }
  }

  foreach pattern [list "vivado.jou" "vivado.log" "*.jou" "*.jou.*" "*.log" "*.log.*"] {
    foreach f [glob -nocomplain -directory $script_dir $pattern] {
      puts "Removing $f"
      file delete -force $f
    }
  }
}

if { $action eq "clean" } {
  clean_artifacts $proj_dir $proj_root $script_dir
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
  [file join $proj_root rtl dxi_if.sv] \
  [file join $proj_root rtl config_if.sv] \
  [file join $proj_root rtl filter.vhd]
]

# UVM environment + testbench (package includes all dxi_* sources)
set tb_files [list \
  [file join $proj_root dxi_pkg.sv] \
  [file join $proj_root tb_top.sv]
]

# Ensure includes resolve for files pulled in by dxi_pkg.sv
set_property include_dirs [list $proj_root] [get_filesets sim_1]

# Add files to simulation set
add_files -fileset sim_1 $rtl_files
add_files -fileset sim_1 $tb_files
set_property file_type {VHDL 2008} [get_files [file join $proj_root rtl filter.vhd]]

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
    set run_tcl [file join $sim_dir "run.tcl"]
    set snapshot "tb_top_behav"
    if {![file exists $run_tcl]} {
      error "Expected xsim run script not found at $run_tcl"
    }
    puts "Running xsim in batch: snapshot=$snapshot script=$run_tcl"
    exec xsim $snapshot -tclbatch $run_tcl
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
