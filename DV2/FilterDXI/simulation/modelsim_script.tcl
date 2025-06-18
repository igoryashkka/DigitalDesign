# create modelsim working library
#vlib work

# compile all the Verilog sources
#vcom ../tb_filter.vhd ../../filter.vhd 

# open the testbench module for simulation
#vsim work.tb_filter

# add all testbench signals to time diagram
#add wave -r /*

# run the simulation
#run -all

# expand the signals time diagram
#wave zoom full

# Create working library
vlib work

# Compile DUT (VHDL)
vcom ../../filter.vhd

# Compile testbench (SystemVerilog)
vlog ../tb_filter_sv.sv

# Launch simulation
vsim work.tb_filter_sv

# Add all signals to waveform
add wave -r /*

# Run simulation
run -all

# Zoom to full view of waveform
wave zoom full
