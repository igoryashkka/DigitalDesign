# DF3

Description:

DF3 contains FPGA-related projects and board-specific artifacts (Counter and Decoder projects, build scripts, constraints, and bitstreams).

Key folders:

- `Counter/` — build scripts (`build.bat`), `bitstreams/`, constraints (XDC), `sim/` and `sources/`
- `Decoder/` — build scripts, `design.xsa` files, constraints, `scripts/` and a small `uart/` submodule containing `uart_*` modules
- `vitis/` — example Vitis project files and application component sources

Build & Deployment:

- These projects are prepared to be used with Xilinx Vivado / Vitis. Each project includes `build.tcl` or helper scripts under `scripts/` to automate build flows.
- Use the `constraints/*.xdc` files to target the intended FPGA board (check `Counter/constraints` and `Decoder/constraints`).

Simulation:

- Simulation testbenches are provided under `sim/` for the relevant subprojects. Use ModelSim or Vivado simulator to run them.

Notes:

- Some directories contain pre-built bitstreams or XSA files; treat these as reference outputs rather than sources to edit directly.
