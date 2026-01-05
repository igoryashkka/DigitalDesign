# DV3 UVM environment

UVM testbench for the DXI filter (DUT: `sources/rtl/filter.vhd` copied from DV2).

## Quick start
- Windows: `scripts\\run_vivado.bat [sim|elab|clean] [gui|tcl]`
- Linux/macOS: `chmod +x scripts/run_vivado.sh && scripts/run_vivado.sh [sim|elab|clean] [gui|tcl]`
- Direct Tcl: `vivado -mode batch -source scripts/setup_vivado.tcl -tclargs <action> <mode>`
  - action: `sim` (default) | `elab` | `clean`
  - mode: `gui` (default) | `tcl` (headless)

Both wrappers clean the generated project (`vivado_project`, `.Xil`, `xsim.dir`, log files) when run with the `clean` action. Simulation artifacts live under `DV3/vivado_project`. Adjust the part number in `scripts/setup_vivado.tcl` if you need to target another device.
