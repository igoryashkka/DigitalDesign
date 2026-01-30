# TODO — DF4 (AXI Slave + GPIO)

## Overview
Goal: Implement an AXI4-Lite slave core and a memory-mapped GPIO peripheral accessible via that AXI port. Deliverables include RTL, testbenches, documentation, and basic synthesis/runs on a target (optional).

## Design choices
- Use **AXI4-Lite** for register-mapped access (simple and common for GPIO/peripherals).
- DATA_WIDTH = 32, ADDR_WIDTH = 32 (configurable in RTL)

## Register Map (suggested)
- 0x00 — GPIO_DATA (R/W): read current input pins or write output pins
- 0x04 — GPIO_DIR (R/W): 0 = input, 1 = output per bit
- 0x08 — IRQ_STATUS (RO): latched interrupt status
- 0x0C — IRQ_ENABLE (R/W): enable interrupt per bit
- 0x10 — RESERVED / future use

## Tasks
- [ ] Write `src/axi_slave.sv` skeleton (channels, handshakes) and a small register file helper
- [ ] Write `src/gpio.sv` with register interface and pin logic
- [ ] Create `sim/tb_axi_slave.sv` to verify read/write transfers (basic AXI4-Lite writes/reads)
- [ ] Create `sim/tb_gpio.sv` to test register map, direction control, and interrupts
- [ ] Add simple integration test that connects `axi_slave` -> `gpio` and performs basic register-based operations
- [ ] Add CI-friendly regression scripts (e.g., `sim/run_sim.sh`) and wave generation for debugging
- [ ] Add documentation (`docs/DF4.md`) describing interfaces and register map
- [ ] Optional: add formal property checks for AXI handshake correctness and register safety
- [ ] Optional: synthesize on example FPGA target and confirm timing if desired

## Test vectors / cases
- Write `GPIO_DIR` to set some bits as outputs, write `GPIO_DATA` and observe outputs
- Simulate input pins toggling and read `GPIO_DATA` with direction set to inputs
- Test read-after-write consistency and read-modify-write handling of `GPIO_DATA` using byte strobes
- Test interrupt behavior: configure IRQ_ENABLE, toggle inputs, check `IRQ_STATUS` and interrupt clear semantics

## Notes & Implementation tips
- Consider implementing a simple address decoder that supports 32-bit aligned addresses (ADDR[3:0] = 0..F)
- Use write strobes (`WSTRB`) in AXI to support sub-word writes and proper read-modify-write behavior
- Keep the AXI slave generic; the GPIO module should be register-accessible but not tied to a specific AXI implementation (create a small register interface between them)

## Files to add
- `src/axi_slave.sv` (skeleton + register access pipe)
- `src/gpio.sv` (register map implementation)
- `sim/tb_axi_slave.sv`, `sim/tb_gpio.sv` (testbenches)
- `docs/DF4.md` (documentation page)