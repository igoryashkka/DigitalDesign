# DV3 UVM Environment

This directory hosts the UVM testbench for the DXI filter design. The DUT used for simulation is the VHDL implementation from DV2/FilterDXI (copied to `rtl/filter.vhd`).

## Files of interest
- `rtl/filter.vhd`: VHDL DUT (dxi_top) sourced from DV2.
- `rtl/dxi_if.sv`, `rtl/config_if.sv`: Interfaces for data and configuration busses.
- `tb_top.sv`: Mixed-language testbench top that instantiates the DUT and UVM environment.
- `dxi_pkg.sv` and related `dxi_*` files: UVM sequences, driver, monitor, scoreboard, and environment.

## Vivado automation
Use the provided Tcl and batch wrappers in `scripts/` to stand up a Vivado simulation project. Key commands (in order of convenience):

1. **Windows (preferred)**: `scripts\\run_vivado.bat sim gui` — create the project and launch xsim behavioral simulation with the GUI (default).
2. **Windows headless**: `scripts\\run_vivado.bat sim tcl` — create the project and run xsim in batch (no GUI).
3. **Windows clean**: `scripts\\run_vivado.bat clean` — delete `vivado_project`, `.Xil`, `xsim.dir`, and Vivado log/jou files.
4. **Any platform**: `vivado -mode batch -source scripts/setup_vivado.tcl -tclargs <action> <mode>`
   - `<action>`: `sim` (default), `elab`, or `clean`.
   - `<mode>`: `gui` (default) or `tcl` (headless batch run).

Supported actions passed through `-tclargs`/batch argument:
- `sim` (default): creates the project, configures compile order, and launches behavioral simulation.
- `elab`: runs elaboration without starting the simulator GUI.
- any other value: generates the project without running simulation.

Simulation mode (`gui` by default) can be set to `tcl` for a non-GUI run. The Windows wrapper supports `clean` as the action (first argument) to delete generated Vivado outputs (`vivado_project`, `.Xil`, `xsim.dir`, and log files) before exiting. The Tcl script also accepts `clean` as the action if you invoke it directly.

Projects are generated under `DV3/vivado_project`. Adjust the part number in `scripts/setup_vivado.tcl` if you need to target a different device.
