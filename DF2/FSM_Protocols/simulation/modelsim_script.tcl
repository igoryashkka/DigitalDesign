# create modelsim working library
vlib work

# compile all the Verilog sources
vcom ../tb_lookahd.vhd ../../lookahd.vhd 

# open the testbench module for simulation
vsim work.tb_lookahd

# add all testbench signals to time diagram
add wave -r /*

# run the simulation
run -all

# expand the signals time diagram
wave zoom full