`timescale 1ns/1ps

module tb_ili934x_min;
  // --- SIM CLOCK @125 MHz ---
  localparam int   CLK_HZ       = 125_000_000;
  localparam real  T_CLK_NS     = 1e9 / CLK_HZ; // 8.0 ns
  localparam int   WR_PULSE_CYC = 2;            // must match DUT params
  localparam int   WR_RECOV_CYC = 1;

  logic clk = 1, rst_n = 0;
  always #(T_CLK_NS/2.0) clk = ~clk;

  // --- DUT signals ---
  logic          init_start, init_done, busy;
  logic          win_set_stb, stream_start;
  logic [15:0]   win_x0, win_y0, win_x1, win_y1;
  logic [15:0]   pix_data;
  logic          pix_valid, pix_ready;

  logic          lcd_cs_n, lcd_dc, lcd_wr_n, lcd_rd_n, lcd_rst_n;
  logic [7:0]    lcd_d;

  // --- DUT (named port mapping only) ---
  ili934x_driver #(
    .P_ILI9341     (1'b1),
    .CLK_HZ        (CLK_HZ),
    .WR_PULSE_CYC  (WR_PULSE_CYC),
    .WR_RECOV_CYC  (WR_RECOV_CYC),
    .X_RES         (240),
    .Y_RES         (320),
    .FIFO_DEPTH    (256)
  ) dut (
    .clk           (clk),
    .rst_n         (rst_n),

    .init_start    (init_start),
    .init_done     (init_done),

    .win_set_stb   (win_set_stb),
    .win_x0        (win_x0),
    .win_y0        (win_y0),
    .win_x1        (win_x1),
    .win_y1        (win_y1),

    .stream_start  (stream_start),
    .pix_data      (pix_data),
    .pix_valid     (pix_valid),
    .pix_ready     (pix_ready),

    .busy          (busy),

    .lcd_cs_n      (lcd_cs_n),
    .lcd_rd_n      (lcd_rd_n),
    .lcd_rst_n     (lcd_rst_n),
    .lcd_dc        (lcd_dc),
    .lcd_wr_n      (lcd_wr_n),
    .lcd_d         (lcd_d)
  );

  // --- Stimulus ---
  initial begin
    // defaults
    init_start   = 1'b0;
    win_set_stb  = 1'b0;
    stream_start = 1'b0;
    pix_valid    = 1'b0;
    pix_data     = '0;
    win_x0='0; win_y0='0; win_x1='0; win_y1='0;

    // reset
    repeat (10) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    // 1-cycle init_start pulse
    init_start = 1'b1;
    @(posedge clk);
    init_start = 1'b0;

    // wait some time (simulate a slice of the init delays)
    repeat (CLK_HZ/200) @(posedge clk); // ~5 ms at 125 MHz

    // if not yet done, wait for it
    if (!init_done) begin
      @(posedge init_done);
      $display("[%0t] init_done OK", $time);
    end

    // Optionally: set a small window and start a short pixel burst
    win_x0 = 16'd0;    win_y0 = 16'd0;
    win_x1 = 16'd3;    win_y1 = 16'd3;

    win_set_stb = 1'b1; @(posedge clk); win_set_stb = 1'b0;

    // start memory write
    stream_start = 1'b1; @(posedge clk); stream_start = 1'b0;

    // send a few pixels
    repeat (16) begin
      @(posedge clk);
      if (pix_ready) begin
        pix_data  <= $random;
        pix_valid <= 1'b1;
      end else begin
        pix_valid <= 1'b0;
      end
    end
    pix_valid <= 1'b0;

    repeat (200) @(posedge clk);
    $finish;
  end
endmodule
