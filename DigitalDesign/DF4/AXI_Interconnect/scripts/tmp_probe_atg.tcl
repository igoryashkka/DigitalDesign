set proj_dir "./.tmp_atg_probe"
if {[file exists $proj_dir]} { file delete -force $proj_dir }
create_project -force atg_probe $proj_dir -part xc7a35tcpg236-1
create_ip -name axi_traffic_gen -vendor xilinx.com -library ip -module_name axi_tg_0
generate_target all [get_ips axi_tg_0]
set stub_file [file normalize "./.tmp_atg_probe/axi_tg_0_stub.v"]
write_verilog -mode synth_stub $stub_file
puts "STUB_FILE=$stub_file"
close_project
exit
