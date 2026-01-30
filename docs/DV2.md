# DV2 — FilterDXI

Description:

`DV2/FilterDXI` contains a VHDL implementation of an image filter and image-related test data. This is a verification/demo project for digital image processing.

Key files:

- `filter.vhd` — main filter implementation
- `README.md` — local description and usage notes
- `Data/` — input images / test vectors
- `simulation/` — simulation scripts and testbench files (check the `modelsim_script.tcl` in this folder)

How to run:

- Run the local `README.md` instructions or use the `modelsim_script.tcl` inside `FilterDXI/simulation` to run the testbench and compare output vectors.
- `txt_to_jpg.py` in the simulations folder can be used to convert numeric output into images for visual validation.

Notes:

- This folder contains simulation inputs and expected outputs which are helpful for automated test runs.
