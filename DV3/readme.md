# DV3 UVM Environment

This directory hosts the UVM testbench for the DXI filter design. The DUT used for simulation is the VHDL implementation from DV2/FilterDXI (copied to `rtl/filter.vhd`).

## Files of interest
- `rtl/filter.vhd`: VHDL DUT (dxi_top) sourced from DV2.
- `rtl/dxi_if.sv`, `rtl/config_if.sv`: Interfaces for data and configuration busses.
- `tb_top.sv`: Mixed-language testbench top that instantiates the DUT and UVM environment.
- `dxi_pkg.sv` and related `dxi_*` files: UVM sequences, driver, monitor, scoreboard, and environment.

## Vivado automation
Use the provided Tcl and batch wrappers in `scripts/` to stand up a Vivado simulation project:

- Windows: run `scripts\\run_vivado.bat sim` to create the project and launch xsim behavioral simulation.
- Any platform with Vivado in PATH: run `vivado -mode batch -source scripts/setup_vivado.tcl -tclargs sim`.

Supported actions passed through `-tclargs`/batch argument:
- `sim` (default): creates the project, configures compile order, and launches behavioral simulation.
- `elab`: runs elaboration without starting the simulator GUI.
- any other value: generates the project without running simulation.

Projects are generated under `DV3/vivado_project`. Adjust the part number in `scripts/setup_vivado.tcl` if you need to target a different device.
