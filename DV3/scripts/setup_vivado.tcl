# Vivado automation script for DXI UVM simulation
# Creates/refreshes a project, adds RTL + UVM sources, and optionally launches simulation.

set proj_name "dxi_uvm"
set proj_root [file normalize [file join [file dirname [info script]] ".."]]
set proj_dir  [file normalize [file join $proj_root "vivado_project"]]
set part_name "xc7a35tcpg236-1"
set action "sim"

if { $argc > 0 } {
  set action [lindex $argv 0]
}

puts "Project root: $proj_root"
puts "Project dir : $proj_dir"
puts "Action      : $action"

# Create project and set mixed-language simulation
create_project -force $proj_name $proj_dir -part $part_name
set_property target_language Mixed [current_project]
set_property target_simulator xsim [current_project]

# RTL interfaces and DUT
set rtl_files [list \
  [file join $proj_root rtl dxi_if.sv] \
  [file join $proj_root rtl config_if.sv] \
  [file join $proj_root rtl filter.vhd]
]

# UVM environment + testbench
set tb_files [list \
  [file join $proj_root dxi_pkg.sv] \
  [file join $proj_root dxi_sequence.sv] \
  [file join $proj_root dxi_master_seq.sv] \
  [file join $proj_root dxi_slave_seq.sv] \
  [file join $proj_root dxi_driver.sv] \
  [file join $proj_root dxi_monitor.sv] \
  [file join $proj_root dxi_agent.sv] \
  [file join $proj_root dxi_scoreboard.sv] \
  [file join $proj_root dxi_env.sv] \
  [file join $proj_root uvm_random_test.sv] \
  [file join $proj_root tb_top.sv]
]

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
  launch_simulation
} elseif { $action eq "elab" } {
  puts "Running elaboration only..."
  launch_simulation -step elab
} else {
  puts "Project generated at $proj_dir"
  puts "Use Vivado GUI or rerun this script with 'sim' to launch simulation."
}
