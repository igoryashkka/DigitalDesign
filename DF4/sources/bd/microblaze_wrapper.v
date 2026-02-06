//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
//Date        : Thu Feb  5 20:42:04 2026
//Host        : DESKTOP-C9DG6FV running 64-bit major release  (build 9200)
//Command     : generate_target microblaze_wrapper.bd
//Design      : microblaze_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module microblaze_wrapper
   (diff_clock_rtl_0_clk_n,
    diff_clock_rtl_0_clk_p,
    led_1_0,
    pwm_r_o_0,
    reset_rtl_0);
  input diff_clock_rtl_0_clk_n;
  input diff_clock_rtl_0_clk_p;
  output led_1_0;
  output pwm_r_o_0;
  input reset_rtl_0;

  wire diff_clock_rtl_0_clk_n;
  wire diff_clock_rtl_0_clk_p;
  wire led_1_0;
  wire pwm_r_o_0;
  wire reset_rtl_0;

  microblaze microblaze_i
       (.diff_clock_rtl_0_clk_n(diff_clock_rtl_0_clk_n),
        .diff_clock_rtl_0_clk_p(diff_clock_rtl_0_clk_p),
        .led_1_0(led_1_0),
        .pwm_r_o_0(pwm_r_o_0),
        .reset_rtl_0(reset_rtl_0));
endmodule
