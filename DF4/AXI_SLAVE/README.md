
# DF4 — AXI4-Lite Slave with GPIO
This project implements a custom **AXI4-Lite slave** with GPIO register interface.

## Build Instructions

Project stages are managed via the provided `build.bat` script.

### Create Project

```bash
.\build.bat
```

After the project is generated:

* Open the project in Vivado GUI.
* Set **VHDL 2019** for all VHDL source files
  (except the `top` module, which should keep its original standard).

---

## Build Options

### Build All Stages (Synthesis + Implementation + Bitstream)

```bash
.\build.bat -all
```

### Run Synthesis Only

```bash
.\build.bat -syn
```

### Run Implementation and Generate Bitstream

```bash
.\build.bat -impl -bit
```

### Generate XSA File

```bash
.\build.bat -xsa
```

---

## ⚠️ Important Notes

* In some cases, **Synthesis may fail** if generated IP cores are not properly created.
* This can happen because `build.tcl` does not always force IP regeneration.
* If this occurs:

  * Open the project in Vivado GUI.
  * Manually regenerate IP cores.
  * Re-run synthesis or implementation.

---
