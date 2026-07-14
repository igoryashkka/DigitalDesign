Я б трохи спростив постановку так, щоб студенту було одразу зрозуміло, **які модулі потрібно написати і як вони між собою з'єднані**. При цьому CDC не виділяти окремим великим розділом, а оформити як **Note** до SPI-конфігурації.

---

# RTL Design Task: Image Processing with Nonlinear Spatial Filters and SPI Configuration (AXI4-Stream)

## General Description

Design an RTL module that performs image processing on a **3×3 pixel window**. For every input window the module shall produce **one output pixel** using one of four nonlinear spatial filters.

Pixel data are transferred through a simplified **AXI4-Stream** interface, while the processing mode is configured through an **SPI Slave** interface.

The complete design consists of the following modules:

```
                +----------------------+
                |      SPI Master      |
                +----------+-----------+
                           |
                           | SPI
                           v
                  +-------------------+
                  |     SPI Slave     |   (i_spi_clk)
                  +---------+---------+
                            |
                            v
                    +---------------+
                    | Register File |
                    +-------+-------+
                            |
                            | configuration
                            v
                  +---------------------+
                  |  CDC Synchronizers  |
                  +---------+-----------+
                            |
                            | synchronized configuration
                            v
 AXI4-Stream      +---------------------+
 input ---------->| Image Filter Core   |-------> AXI4-Stream output
                  |     (i_clk)         |
                  +---------------------+
```

The student shall implement:

* SPI Slave
* Register File
* CDC synchronization logic
* Image Filter Core
* AXI4-Stream interfaces
* Testbench

---

# 1. Image Filter Core

The Image Filter Core operates in the **`i_clk`** clock domain.

It receives one **3×3 image window** packed into a single AXI4-Stream word and produces one processed pixel.

## Supported filters

| CFG_SELECT | Filter         | Description                             |
| ---------- | -------------- | --------------------------------------- |
| 00         | Min Filter     | Output is the minimum of the 9 pixels   |
| 01         | Max Filter     | Output is the maximum of the 9 pixels   |
| 10         | Median Filter  | Output is the median (5th sorted value) |
| 11         | Sobel Operator | Output = |Gx| + |Gy|                    |

### Sobel kernels

```
Gx

[-1  0 +1]
[-2  0 +2]
[-1  0 +1]

Gy

[-1 -2 -1]
[ 0  0  0]
[+1 +2 +1]
```

## Functional requirements

* Min/Max shall be implemented using a comparator tree.
* Median shall be implemented using a sorting network.
* Sobel shall compute Gx and Gy, calculate absolute values, sum them, and normalize using `CFG_SOBEL_GAIN`.
* The output shall be either saturated or wrapped according to `CFG_SAT_MODE`.
* The datapath should be pipelined.
* If `CFG_ENABLE = 0`, the module shall bypass processing and forward the center pixel.

---

## AXI4-Stream Interface (Image Filter Core)

| Port                | Direction | Description                     |
| ------------------- | --------- | ------------------------------- |
| `i_clk`             | Input     | Processing clock                |
| `i_rstn`            | Input     | Active-low reset                |
| `i_axis_in_tvalid`  | Input     | Input data valid                |
| `o_axis_in_tready`  | Output    | Ready to accept a new window    |
| `i_axis_in_tdata`   | Input     | Packed 3×3 window (9 × DATA_BW) |
| `o_axis_out_tvalid` | Output    | Output pixel valid              |
| `i_axis_out_tready` | Input     | Output ready                    |
| `o_axis_out_tdata`  | Output    | Processed pixel                 |

---

# 2. SPI Slave and Register File

The SPI interface operates in the **`i_spi_clk`** clock domain.

The SPI Slave receives configuration commands from the external host and stores them in the Register File.

The Image Filter Core shall use these registers as its configuration source.

## SPI Interface

| Port         | Direction | Description    |
| ------------ | --------- | -------------- |
| `i_spi_clk`  | Input     | SPI clock      |
| `i_spi_cs_n` | Input     | Chip Select    |
| `i_spi_mosi` | Input     | Master → Slave |
| `o_spi_miso` | Output    | Slave → Master |

---

## SPI Transaction Format

```
+------+----------+---------+
| R/W  | Address  |  Data   |
+------+----------+---------+
 1 bit   7 bits    N bits
```

* Write: `R/W = 0`
* Read: `R/W = 1`

---

## Register Map

| Address | Register       | Width | Description         |
| ------- | -------------- | ----- | ------------------- |
| 0x00    | CFG_SELECT     | 2     | Filter selection    |
| 0x01    | CFG_ENABLE     | 1     | Enable/Bypass       |
| 0x02    | CFG_SAT_MODE   | 1     | Saturate / Wrap     |
| 0x03    | CFG_THRESHOLD  | 8     | Optional threshold  |
| 0x04    | CFG_SOBEL_GAIN | 4     | Sobel normalization |
| 0x05    | CFG_SOFT_RESET | 1     | Software reset      |
| 0x06    | STATUS         | 8     | Read-only status    |

---

> **Note – Clock Domain Crossing (CDC)**
>
> The SPI interface (`i_spi_clk`) and the Image Filter Core (`i_clk`) operate in different asynchronous clock domains. Therefore, all signals crossing between these domains shall be synchronized.
>
> The following synchronization methods shall be used:
>
> * **Single-bit configuration signals** (`CFG_ENABLE`, `CFG_SAT_MODE`) shall use a **2-FF synchronizer**.
> * **Multi-bit configuration buses** (`CFG_SELECT`, `CFG_SOBEL_GAIN`, `CFG_THRESHOLD`) shall **not** be synchronized bit-by-bit. Instead, implement a **handshake/toggle-based CDC**, where configuration data are first stored in the SPI domain and transferred atomically after a synchronized update request.
> * **CFG_SOFT_RESET** shall use a **pulse synchronizer** (pulse → toggle → 2-FF → edge detector).
> * **STATUS** signals generated by the Image Filter Core shall be synchronized back into the SPI clock domain before being read by the SPI master.
>
> Implement reusable synchronization modules such as:
>
> * `sync_2ff`
> * `pulse_sync`
> * `handshake_cdc`
>
> Add comments in the RTL explaining why each synchronization method is required.

---

# 3. Deliverables

The submission shall include:

1. SystemVerilog RTL:

   * Image Filter Core
   * SPI Slave
   * Register File
   * CDC synchronizers
2. Top-level block diagram.
3. Brief documentation describing the function of each module and the implemented synchronization mechanisms.
4. Testbench demonstrating:

   * correct operation of all four filters;
   * SPI register read/write;
   * asynchronous operation of `i_clk` and `i_spi_clk`;
   * correct configuration transfer without CDC-related errors.
