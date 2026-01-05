# DV3 UVM Environment

This directory hosts the UVM testbench for the DXI filter design. The DUT used for simulation is the VHDL implementation from DV2/FilterDXI (copied to `rtl/filter.vhd`).

## Files of interest
- `rtl/filter.vhd`: VHDL DUT (dxi_top) sourced from DV2.
- `rtl/dxi_if.sv`, `rtl/config_if.sv`: Interfaces for data and configuration busses.
- `tb/tb_top.sv`: Mixed-language testbench top.
- `seq/`: `dxi_transation.sv`, master/slave sequences.
- `env/`: driver, monitor, agent, scoreboard, and `uvm_env` (environment).
- `tests/uvm_random_test.sv`: Sample test that drives master/slave sequences.

## Vivado automation
Use the provided Tcl and batch wrappers in `scripts/` to stand up a Vivado simulation project. Command/argument cheatsheet:

1) Windows (GUI, default): `scripts\\run_vivado.bat sim gui`
2) Windows (headless): `scripts\\run_vivado.bat sim tcl`
3) Windows (clean only): `scripts\\run_vivado.bat clean`
4) Any platform: `vivado -mode batch -source scripts/setup_vivado.tcl -tclargs <action> <mode>`
   - `<action>` = `sim` (default) | `elab` | `clean`
   - `<mode>`   = `gui` (default) | `tcl` (headless)

Supported actions passed through `-tclargs`/batch argument:
- `sim` (default): creates the project, configures compile order, and launches behavioral simulation.
- `elab`: runs elaboration without starting the simulator GUI.
- any other value: generates the project without running simulation.

Simulation mode (`gui` by default) can be set to `tcl` for a non-GUI run. The Windows wrapper supports `clean` as the action (first argument) to delete generated Vivado outputs (`vivado_project`, `.Xil`, `xsim.dir`, and log files) before exiting. The Tcl script also accepts `clean` as the action if you invoke it directly.

Projects are generated under `DV3/vivado_project`. Adjust the part number in `scripts/setup_vivado.tcl` if you need to target a different device.
