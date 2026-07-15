# DF4 — AXI Slave & GPIO

Description

DF4 hosts an AXI4-Lite slave IP and a GPIO peripheral that will be memory-mapped through AXI. This page points to the TODO plan and RTL skeletons.

Where to look

- `DF4/README.md` — short project summary
- `DF4/TODO.md` — planned tasks, register map, and test cases
- `DF4/src/axi_slave.sv` — AXI4-Lite slave skeleton
- `DF4/src/gpio.sv` — GPIO register-file skeleton

Goals

- Implement a robust AXI4-Lite slave with correct handshake and byte-strobe support
- Implement a GPIO peripheral (data, direction, interrupts) that can be accessed via AXI
- Provide simulation testbenches and CI-friendly scripts to validate functionality
