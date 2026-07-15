# DF1

Description:

DF1 contains basic VHDL components used for digital fundamentals coursework and small experiments: logic gates, a D-latch, a full-adder, a 4:1 multiplexer, and a traffic FSM.

Key files:

- `d-latch.vhd` - D-latch implementation
- `inv.vhd` - Inverter
- `fulladder.vhd` - Full-adder (single-bit)
- `mux4to1.vhd` - 4-to-1 multiplexer
- `traffic_fsm.vhd` - Traffic light finite state machine

Simulation / Test:

- Add or create a VHDL testbench (e.g., `tb_*.vhd`) under a simulation folder, or reuse the generic `modelsim_script.tcl` pattern from other directories (see DF2 simulations).
- Typical ModelSim steps:
  1. `vlib work`
  2. `vcom d-latch.vhd tb_d_latch.vhd`
  3. `vsim work.tb_d_latch`

Notes:

- There are no dedicated testbenches in this folder. You can adapt testbenches from `DF2/*/simulation` or create new ones.
