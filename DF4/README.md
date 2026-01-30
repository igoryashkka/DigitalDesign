# DF4 — AXI Slave & GPIO

Purpose

DF4 will host an AXI4-Lite-compatible slave IP and a memory-mapped GPIO module that uses the AXI slave for register access. This folder contains a TODO list, RTL skeletons, and will later contain testbenches and simulations.

Structure

- `TODO.md` — task list and design plan
- `src/axi_slave.sv` — AXI4-Lite slave skeleton (register interface)
- `src/gpio.sv` — GPIO module that maps registers to pins
- `sim/` — (planned) testbenches and simulation scripts

Quick start

1. Read `TODO.md` and pick a task (e.g., implement register write/read path).
2. Use `src/axi_slave.sv` as a starting point and add register handling logic.
3. Add testbenches under `sim/` and iterate until tests pass.
