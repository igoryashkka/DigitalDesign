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

  // --- DUT (same params as your design) ---
  ili934x_driver #(
    .CLK_HZ(CLK_HZ),
    .WR_PULSE_CYC(WR_PULSE_CYC),
    .WR_RECOV_CYC(WR_RECOV_CYC),
    .X_RES(240), .Y_RES(320)
  ) dut (
    .clk, .rst_n,
    .init_start, .init_done,
    .win_set_stb, .win_x0, .win_y0, .win_x1, .win_y1,
    .stream_start,
    .pix_data, .pix_valid, .pix_ready,
    .busy,
    .lcd_cs_n, .lcd_dc, .lcd_wr_n, .lcd_rd_n, .lcd_rst_n, .lcd_d
  );


  initial begin
    init_start   = 0;
    win_set_stb  = 0; stream_start = 0;
    pix_valid    = 0; pix_data = '0;
    win_x0='0; win_y0='0; win_x1='0; win_y1='0;


    repeat (10) @(posedge clk);
    //rst_n = 1;
    @(posedge clk);


    init_start = 1;
    @(posedge clk);
   // init_start = 0;

        repeat (CLK_HZ/200) @(posedge clk); 


         if (!init_done) begin
            @(posedge init_done);
            $display("[%0t] init_done OK", $time);
         end
       

  end

endmodule
