### Simulation Run

1. **Execute the Batch Script**:
   - Run the `sim.bat` file. This script will:
     - Create a temporary folder (`sim`) for storing simulation files.
     - Execute the `modelsim_script.tcl` file to compile and simulate the design.
     - Return to the parent directory after the simulation is complete.

2. **Tcl Script Description**:
   - The Tcl script performs the following steps:
     - Creates a working library for ModelSim (`vlib work`).
     - Compiles the VHDL files for the design and testbench.
     - Opens the testbench for simulation (`vsim`).
     - Adds all signals to the wave window for visualization.
     - Runs the simulation (`run -all`).
     - Adjusts the wave window for a full view.

---

## Note for Testing Different Modules

To test a different module, you need to modify the **Tcl script**:

1. Replace the VHDL file paths in the `vcom` commands:
   ```tcl
   vcom ../your_tb_file.vhd ../../your_component_file.vhd
   ```

2. Update the `vsim` command to specify the testbench entity:
   ```tcl
   vsim work.your_tb_file
   ```