# DF4 — AXI Slave & GPIO

This project implements an AXI4-Lite slave with GPIO functionality.

## Build Scripts

Use the provided `build.bat` script to manage project stages.

### Create Project
```bash
.\build.bat
Build All Stages
.\build.bat -all

Run Synthesis Only
.\build.bat -syn

Run Implementation and Generate Bitstream
.\build.bat -impl -bit

Generate XSA File
.\build.bat -xsa
