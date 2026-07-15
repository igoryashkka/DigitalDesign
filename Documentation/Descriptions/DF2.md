# DF2

Description:

DF2 groups smaller functional blocks across three areas:
- BasicLogicGates — gate and simple arithmetic implementations
- FSM_Protocols — finite state machines and protocol examples (sequence detector, SPI)
- IntermediateBlocks — small building blocks (adder/subtractor, registers, counter, multiplier)

Structure & Key files:

- `BasicLogicGates/`
  - `andGate.vhd`, `orGate.vhd`, `mux2to1.vhd`, `mux4to1.vhd`, `FullAdder4Bit.vhd`
  - `simulation/` contains ModelSim scripts and testbenches: see `simulation/tb_*.vhd`

- `FSM_Protocols/`
  - `SequenceDetector.vhd`, `lookahd.vhd`, `spi_master.vhd`, `spi_slave.vhd`
  - `simulation/` contains example TBs and a `modelsim_script.tcl` to run them

- `IntermediateBlocks/`
  - `counter.vhd`, `Reg.vhd`, `AddSub.vhd`, `mult.vhd`
  - `simulation/` contains testbenches and scripts

Simulation / How to run:

- Use the provided `modelsim_script.tcl` in each subdirectory's `simulation/` folder, or a central runner script. The root `README.md` has a short template for ModelSim usage.
- To test a specific component, update the `vcom` commands and the `vsim` target in the Tcl script.

Notes:

- DF2 contains many prepared testbenches; these are good starting points for learning and verification.
