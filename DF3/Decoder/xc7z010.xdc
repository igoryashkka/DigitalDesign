## Clock Signal

set_property -dict { PACKAGE_PIN H16    IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L13P_T2_MRCC_35 Sch=SYSCLK
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];#set

set_property -dict { PACKAGE_PIN D19    IOSTANDARD LVCMOS33 } [get_ports { btn_a_up }]; # btn_a_up    | btn[0]                   #IO_L4P_T0_35 Sch=BTN0
set_property -dict { PACKAGE_PIN D20    IOSTANDARD LVCMOS33 } [get_ports { btn_a_down }]; # btn_a_down  | btn[1]                   #IO_L4N_T0_35 Sch=BTN1
set_property -dict { PACKAGE_PIN L20    IOSTANDARD LVCMOS33 } [get_ports { btn_b_up }]; # btn_b_up    | btn[2]                   #IO_L9N_T1_DQS_AD3N_35 Sch=BTN2
set_property -dict { PACKAGE_PIN L19    IOSTANDARD LVCMOS33 } [get_ports { btn_b_down }]; # btn_b_down  | btn[3]                   #IO_L9P_T1_DQS_AD3P_35 Sch=BTN3

set_property -dict { PACKAGE_PIN R14    IOSTANDARD LVCMOS33 } [get_ports { led_zero_o  }]; # led[0] #IO_L6N_T0_VREF_34 Sch=LED0
set_property -dict { PACKAGE_PIN P14    IOSTANDARD LVCMOS33 } [get_ports { led_carry_o }]; #led[1]   IO_L6P_T0_34 Sch=LED1
set_property -dict { PACKAGE_PIN N16    IOSTANDARD LVCMOS33 } [get_ports { led_over_o  }]; #led[2] IO_L21N_T3_DQS_AD14N_35 Sch=LED2
set_property -dict { PACKAGE_PIN M14    IOSTANDARD LVCMOS33 } [get_ports { led_neg_o }]; #  led[3]  IO_L23P_T3_35 Sch=LED3


set_property -dict { PACKAGE_PIN M20  IOSTANDARD LVCMOS33 } [get_ports { rst_n }]; #sw0 #IO_L7N_T1_AD2N_35 Sch=SW0
set_property -dict { PACKAGE_PIN M19  IOSTANDARD LVCMOS33 } [get_ports { ctrl_mode }]; # sw1 #IO_L7P_T1_AD2P_35 Sch=SW1


set_property -dict { PACKAGE_PIN L15    IOSTANDARD LVCMOS33 } [get_ports { u_pwm_r }]; #IO_L22N_T3_AD7P_35 Sch=LED4_B
set_property -dict { PACKAGE_PIN G17    IOSTANDARD LVCMOS33 } [get_ports { u_pwm_g }]; #IO_L16P_T2_35 Sch=LED4_G
set_property -dict { PACKAGE_PIN N15    IOSTANDARD LVCMOS33 } [get_ports { u_pwm_b }]; #IO_L21P_T3_DQS_AD14P_35 Sch=LED4_R