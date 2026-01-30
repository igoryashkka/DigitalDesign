# CPU0

Description:

`CPU0` is a SystemVerilog RISC-V-like CPU core implementation with supporting modules (ALU, controller, register file, memories). The design looks self-contained with a `top.sv` rail for integration.

Key files:

- `top.sv` — top-level wrapper for the CPU system
- `cpu_core.sv` — main CPU core implementation
- `datapath.sv`, `controller.sv`, `maindec.sv`, `alu_decoder.sv`, `alu.sv` — core components
- `regfile.sv` — register file
- `imem.sv`, `dmem.sv` — instruction and data memories
- `flopr.sv`, `flopenr.sv` — flops with reset and enable
- `mux2.sv`, `mux3.sv` — multiplexers
- `extend.sv` — immediate extension
- `riscvtest.txt` — sample program / instructions

Simulation / How to run:

- Because this is SystemVerilog, prefer simulators with full SV support (Questa/ModelSim, VCS, or Xcelium). Verilator can be used for many synthesizable subsets but may require C++ testbench glue.
- Typical flow with Questa:
  1. `vlib work`
  2. `vlog *.sv` (or list files explicitly)
  3. `vsim work.top` (or the top-level testbench)

- If you prefer open-source, use Verilator to compile and run C++/Python testbenches, or write a UVM-like testbench using a supported simulator.

Notes:

- `riscvtest.txt` appears to contain a small test program you can load into `imem` for instruction testing.
