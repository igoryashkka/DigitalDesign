##########################################################################################################
#
# flash.tcl: Program the FPGA with a bitstream
#
# Usage:
#   vivado -mode tcl -source flash.tcl -tclargs <bit_path> <hw_server> <hw_target> <device_name>
#
# Notes:
#   - bit_path: optional, defaults to impl_1 output in the project directory
#   - hw_server: optional, defaults to localhost:3121
#   - hw_target: optional, defaults to the first available target
#   - device_name: optional, defaults to the first device in the target
#
##########################################################################################################

set ::env(REPO_DIR) [file dirname [file dirname [file normalize [info script]]]]
source $env(REPO_DIR)/scripts/settings.tcl

set project_dir "[file normalize "$repository_dir/project"]"

set bit_arg [lindex $argv 0]
set hw_server_arg [lindex $argv 1]
set hw_target_arg [lindex $argv 2]
set device_arg [lindex $argv 3]

if {$hw_server_arg eq ""} { set hw_server_arg "localhost:3121" }

if {$bit_arg eq ""} {
    set candidate_paths [list \
        "$project_dir/$_xil_proj_name_.runs/impl_1/${_xil_proj_name_}.bit" \
        "$project_dir/$_xil_proj_name_.runs/impl_1/${_inst_top_name_}.bit" \
        "$project_dir/$_xil_proj_name_.runs/impl_1/microblaze_wrapper.bit" \
        "$project_dir/${_inst_top_name_}.bit" \
        "$project_dir/$_xil_proj_name_.bit" ]
    set found_bit ""
    foreach p $candidate_paths {
        if {[file exists $p]} { set found_bit $p; break }
    }
    if {$found_bit eq ""} {
        set bits [glob -nocomplain -directory "$project_dir/$_xil_proj_name_.runs/impl_1" "*.bit"]
        if {[llength $bits] > 0} { set found_bit [file normalize [lindex $bits 0]] }
    }
    if {$found_bit eq ""} {
        puts "Error: Bitstream not found. Build the project first."
        exit 1
    }
    set bit_arg $found_bit
}

set bit_arg [file normalize $bit_arg]

puts "Using bitstream: $bit_arg"
puts "Connecting to hw_server: $hw_server_arg"

open_hw_manager
if {$hw_server_arg ne ""} {
    connect_hw_server -allow_non_jtag -url "TCP:$hw_server_arg"
} else {
    connect_hw_server -allow_non_jtag
}

if {$hw_target_arg ne ""} {
    open_hw_target $hw_target_arg
} else {
    open_hw_target
}

set hw_devices [get_hw_devices]
if {[llength $hw_devices] == 0} {
    puts "Error: No hardware devices found."
    exit 1
}

if {$device_arg ne ""} {
    set hw_dev [get_hw_devices $device_arg]
    if {[llength $hw_dev] == 0} {
        puts "Error: Device '$device_arg' not found. Available: $hw_devices"
        exit 1
    }
} else {
    set hw_dev [lindex $hw_devices 0]
}

current_hw_device $hw_dev
refresh_hw_device -update_hw_probes false $hw_dev
set_property PROGRAM.FILE $bit_arg $hw_dev
program_hw_devices $hw_dev
refresh_hw_device $hw_dev

puts "Programming completed."
