# ST7789 constraints for top module: lcd_top
# NOTE: Verify PACKAGE_PIN values against your exact board schematic.

# FPGA configuration
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE Yes [current_design]

# Board clock and reset
# 200 MHz differential clock from onboard oscillator.
set_property -dict {PACKAGE_PIN R4 IOSTANDARD DIFF_SSTL15} [get_ports clk_200_p]
set_property -dict {PACKAGE_PIN T4 IOSTANDARD DIFF_SSTL15} [get_ports clk_200_n]
create_clock -period 5.000 -name sys_clk_200m [get_ports clk_200_p]

set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33 PULLUP TRUE} [get_ports rst_n]

# ST7789 module connector mapping (TFT pin order to JM1 pin order):
#   TFT-3 SCL -> JM1-3  (IO_L5P_16) -> E16
#   TFT-4 SDA -> JM1-4  (IO_L1P_16) -> F13
#   TFT-5 RES -> JM1-5  (IO_L5N_16) -> D16
#   TFT-6 DC  -> JM1-6  (IO_L1N_16) -> F14
#   TFT-7 CS  -> JM1-7  (IO_L8P_16) -> C13
#   TFT-8 BLK -> JM1-8  (IO_L6P_16) -> D14
#   VCC/GND are power pins (not constrained in XDC)
#   FS0/FCS are not used by this design

set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVCMOS33} [get_ports lcd_scl]
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports lcd_sda]
set_property -dict {PACKAGE_PIN D16 IOSTANDARD LVCMOS33} [get_ports lcd_res]
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports lcd_dc]
set_property -dict {PACKAGE_PIN C13 IOSTANDARD LVCMOS33} [get_ports lcd_cs]
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33} [get_ports lcd_blk]

