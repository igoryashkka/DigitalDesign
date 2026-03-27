`timescale 1ns/1ps

module tb_video_timings;
	localparam time CLK_200_PERIOD = 5ns;
	localparam time SIM_TIME       = 2ms;

	logic clk = 1'b0;
	logic rst = 1'b1;

	logic tmds_clk_p;
	logic tmds_clk_n;
	logic tmds_d0_p;
	logic tmds_d0_n;
	logic tmds_d1_p;
	logic tmds_d1_n;
	logic tmds_d2_p;
	logic tmds_d2_n;
	logic pwm_r_o;

	int pwm_toggles;
	int tmds_clk_toggles;

	always #(CLK_200_PERIOD/2) clk = ~clk;

	top_hdmi dut (
		.rst       (rst),
		.clk_200   (clk),
		.tmds_clk_p(tmds_clk_p),
		.tmds_clk_n(tmds_clk_n),
		.tmds_d0_p (tmds_d0_p),
		.tmds_d0_n (tmds_d0_n),
		.tmds_d1_p (tmds_d1_p),
		.tmds_d1_n (tmds_d1_n),
		.tmds_d2_p (tmds_d2_p),
		.tmds_d2_n (tmds_d2_n),
		.pwm_r_o   (pwm_r_o)
	);

	always @(posedge pwm_r_o or negedge pwm_r_o) begin
		if (!rst) pwm_toggles++;
	end

	always @(posedge tmds_clk_p or negedge tmds_clk_p) begin
		if (!rst) tmds_clk_toggles++;
	end

	initial begin
		pwm_toggles = 0;
		tmds_clk_toggles = 0;

		repeat (20) @(posedge clk);
		rst <= 1'b0;
		$display("TB: reset deasserted, run top_hdmi checks...");

		#SIM_TIME;

		assert (tmds_clk_p === ~tmds_clk_n)
			else $fatal(1, "TMDS CLK differential mismatch");
		assert (tmds_d0_p  === ~tmds_d0_n)
			else $fatal(1, "TMDS D0 differential mismatch");
		assert (tmds_d1_p  === ~tmds_d1_n)
			else $fatal(1, "TMDS D1 differential mismatch");
		assert (tmds_d2_p  === ~tmds_d2_n)
			else $fatal(1, "TMDS D2 differential mismatch");

		assert (pwm_toggles > 20)
			else $fatal(1, "PWM output did not toggle enough: %0d", pwm_toggles);
		assert (tmds_clk_toggles > 20)
			else $fatal(1, "TMDS clock did not toggle enough: %0d", tmds_clk_toggles);

		$display("PASS: top_hdmi basic checks passed, pwm_toggles=%0d, tmds_clk_toggles=%0d", pwm_toggles, tmds_clk_toggles);
		$finish;
	end

endmodule
