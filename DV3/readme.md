# DV3 UVM environment

UVM testbench for the DXI filter (DUT: `sources/rtl/filter.vhd` copied from DV2).

## Quick start
- Windows: `scripts\\run_vivado.bat [sim|elab|clean] [gui|tcl]`
- Linux: `chmod +x scripts/run_vivado.sh && scripts/run_vivado.sh [sim|elab|clean] [gui|tcl]`
- Direct Tcl: `vivado -mode batch -source scripts/setup_vivado.tcl -tclargs <action> <mode>`
  - action: `sim` (default) | `elab` | `clean`
  - mode: `gui` (default) | `tcl` (headless)

Both wrappers clean the generated project (`vivado_project`, `.Xil`, `xsim.dir`, log files) when run with the `clean` action. Simulation artifacts live under `DV3/vivado_project`. Adjust the part number in `scripts/setup_vivado.tcl` if you need to target another device.

## Selecting and running tests

The default UVM test is `random_uvm_test`. You can override it with `+UVM_TESTNAME`.

### Windows (batch wrapper)
```
:: Basic random test
scripts\run_vivado.bat sim gui

:: Boundary test
scripts\run_vivado.bat sim gui boundary_uvm_test

:: File-driven test
scripts\run_vivado.bat sim gui file_uvm_test "..\DV2\FilterDXI\simulation\input_256_194.txt"
```
Args: `action` (sim|elab|clean), `mode` (gui|tcl), `testname` (defaults to `random_uvm_test`), optional `IMG_FILE` for the file test.

Notes:

  - `scripts\run_vivado.bat sim gui boundary_uvm_test` → GUI, boundary test.
  - `scripts\run_vivado.bat sim tcl boundary_uvm_test` → boundary test (console logs only).
  - `scripts\run_vivado.bat sim boundary_uvm_test` → GUI by default, boundary test.
  - `scripts\run_vivado.bat sim file_uvm_test "..\DV2\FilterDXI\simulation\input_256_194.txt"` → GUI by default, file test with IMG_FILE set.

### Direct Vivado Tcl
```
vivado -mode batch -source scripts/setup_vivado.tcl -tclargs sim tcl
```
Then, from `vivado_project/dxi_uvm.sim/sim_1/behav/xsim`, re-run xsim with plusargs:
```
xsim tb_top_behav --testplusarg "UVM_TESTNAME=file_uvm_test" --testplusarg "IMG_FILE=../DV2/FilterDXI/simulation/input_256_194.txt" -tclbatch run.tcl
```
