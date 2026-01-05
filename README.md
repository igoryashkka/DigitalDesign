## Running ModelSim simulations (DF2/DV2)

Each ModelSim-ready simulation folder includes a Windows launcher `sim.bat` that:

- Recreates a temporary `sim` directory for outputs.
- Runs `modelsim_script.tcl` to compile and simulate the design.

```bat
sim.bat
```

To target a different testbench, edit the `vcom` and `vsim` lines inside that folder’s `modelsim_script.tcl`.
