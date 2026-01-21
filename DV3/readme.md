# DV3 UVM environment

UVM testbench for the DXI filter (DUT: `sources/rtl/filter.vhd` copied from DV2).

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

