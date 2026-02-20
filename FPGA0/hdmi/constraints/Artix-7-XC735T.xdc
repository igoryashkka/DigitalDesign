# Загальні параметри конфігурації
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE Yes [current_design]

# Підключення зовнішніх сигналів та клоку
# TODO: set PACKAGE_PIN for clk_200 based on your board schematics
# set_property -dict {PACKAGE_PIN <PIN> IOSTANDARD LVCMOS33} [get_ports clk_200]
#create_clock -period 5.000 -name clk_200 [get_ports clk_200]
set_property PACKAGE_PIN R4 [get_ports clk_200]
set_property IOSTANDARD LVCMOS33 [get_ports clk_200]

# Reset
#set_property -dict {PACKAGE_PIN W21 IOSTANDARD LVCMOS33 } [get_ports reset_rtl_0] 
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports rst]

set_property -dict {PACKAGE_PIN W22 IOSTANDARD LVCMOS33} [get_ports {pwm_r_o}]
#set_property -dict {PACKAGE_PIN Y22 IOSTANDARD LVCMOS33} [get_ports {pwm_r_o_1}]

#sycn_reset
#set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33 PULLDOWN TRUE} [get_ports sync_reset_i]


# TMDS Clock pair
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD TMDS_33} [get_ports {tmds_clk_p}]
set_property -dict {PACKAGE_PIN Y19 IOSTANDARD TMDS_33} [get_ports {tmds_clk_n}]

# TMDS Data0 pair 
set_property -dict {PACKAGE_PIN V18 IOSTANDARD TMDS_33} [get_ports {tmds_d0_p}]
set_property -dict {PACKAGE_PIN V19 IOSTANDARD TMDS_33} [get_ports {tmds_d0_n}]

# TMDS Data1 pair 
set_property -dict {PACKAGE_PIN AA19 IOSTANDARD TMDS_33} [get_ports {tmds_d1_p}]
set_property -dict {PACKAGE_PIN AB20 IOSTANDARD TMDS_33} [get_ports {tmds_d1_n}]

# TMDS Data2 pair 
set_property -dict {PACKAGE_PIN V17 IOSTANDARD TMDS_33} [get_ports {tmds_d2_p}]
set_property -dict {PACKAGE_PIN W17 IOSTANDARD TMDS_33} [get_ports {tmds_d2_n}]

# set_property DIFF_TERM FALSE [get_ports {tmds_*_p tmds_*_n}]

set_property IOSTANDARD TMDS_33 [get_ports {tmds_clk_p tmds_clk_n tmds_d0_p tmds_d0_n tmds_d1_p tmds_d1_n tmds_d2_p tmds_d2_n}]
