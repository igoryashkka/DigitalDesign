
`timescale 1ns/1ps

`define CLK_60 (test_top.clknetwork.clk_out1)
`define CLK_100 (test_top.clknetwork.clk_out2)
`define PUSH_BUT(x)						\
		btn[x] = 1;						\
		@(posedge clk) btn[x] = 0;

module tb_test_top ();

	localparam c_data_len = (6 * 8);

	logic 			i_clk;
	logic [1:0]		sw = '1;
	logic [3:0]		btn = '0;
	logic 			led_1_r;
	logic 			led_1_g;
	logic 			led_1_b;
	logic 			led_2_r;
	logic 			led_2_g;
	logic 			led_2_b;
	logic [3:0]		led;
	logic [19:0]	IO;
	logic [7:0]		ja;
	logic [7:0]		jb;
	logic [7:0]		jc;
	logic [7:0]		jd;

	wire logic clk = `CLK_100;

	const logic [c_data_len - 1 : 0] r_write_word = 48'hFF_FF_FF_FF_FF_00;

	Zybo_Z7_top inst_test_top (
			.sys_clk_100       (i_clk),
			.*);

	initial begin
		i_clk = '0;
		forever #4 i_clk = ~i_clk;
	end

	always_ff @(posedge `CLK_60)
		if (!ck_rstn) begin
			sw <= '0;
			btn <= '0;
		end

	initial begin
		sw[0] = 0;
		@(posedge `CLK_60);
		@(posedge `CLK_60) sw[0] = 1;
		@(posedge `CLK_60) sw[0] = 0;
		@(posedge `CLK_60) sw[0] = 1;

		repeat(100)@(posedge clk);

		for (int i = c_data_len; i > 0; i--) begin
			`PUSH_BUT(r_write_word[i - 1])
		end

		repeat(100)@(posedge clk);

		if (sw[0]) begin
			repeat(10)@(posedge `CLK_60);
			btn[2] = 1;
			@(posedge `CLK_60) btn[2] = 0;
		end else begin
			repeat(10)@(posedge clk);
			btn[3] = 1;
			@(posedge clk) btn[3] = 0;
		end
	end

endmodule
