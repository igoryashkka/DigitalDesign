# create modelsim working library
vlib work

# compile all the Verilog sources
vcom ../tb_and.vhd ../../andGate.vhd 

# open the testbench module for simulation
vsim work.tb_andGate

# add all testbench signals to time diagram
add wave -r /*

# run the simulation
run -all

# expand the signals time diagram
wave zoom full