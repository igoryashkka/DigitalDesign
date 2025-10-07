`timescale 1ns/1ps
import ili934x_pkg::*;

module ili934x_driver #(
  parameter bit   P_ILI9341    = 1'b1,
  parameter int   CLK_HZ       = 50_000_000,
  parameter int   WR_PULSE_CYC = 2,
  parameter int   WR_RECOV_CYC = 1,
  parameter int   X_RES        = 240,
  parameter int   Y_RES        = 320,
  parameter int   FIFO_DEPTH   = 256
)(
  input  logic          clk,
  input  logic          rst_n,

  // host control
  input  logic          init_start,
  output logic          init_done,

  input  logic          win_set_stb,
  input  logic [15:0]   win_x0, win_y0, win_x1, win_y1,

  input  logic          stream_start,
  input  logic [15:0]   pix_data,
  input  logic          pix_valid,
  output logic          pix_ready,

  // busy = init running or window/stream active or fifo not empty
  output logic          busy,

  // 8080-8
  output logic          lcd_cs_n,
  output logic          lcd_rd_n,
  output logic          lcd_rst_n,  // here kept as always released (can add POR if needed)
  output logic          lcd_dc,
  output logic          lcd_wr_n,
  output logic [7:0]    lcd_d
);

  // Hold reset high (you can add a POR counter if desired)
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) lcd_rst_n <= 1'b0;
    else        lcd_rst_n <= 1'b1;
  end

  // === INIT SEQ ===
  logic       init_v, init_r;
  wr_item_t   init_item;

  ili934x_init_seq #(.CLK_HZ(CLK_HZ)) u_init (
    .clk        (clk),
    .rst_n      (rst_n),
    .start      (init_start),
    .done       (init_done),
    .item_valid (init_v),
    .item       (init_item),
    .item_ready (init_r)
  );

  // === WINDOW/STREAM ===
  logic       ws_v, ws_r;
  wr_item_t   ws_item;

  // We pass a simple “can accept” as the downstream ready of the FIFO
  logic fifo_out_ready;
  logic fifo_out_valid;
  wr_item_t fifo_out_item;

  ili934x_win_stream u_ws (
    .clk            (clk),
    .rst_n          (rst_n),
    .win_set_stb    (win_set_stb),
    .win_x0         (win_x0), .win_y0(win_y0), .win_x1(win_x1), .win_y1(win_y1),
    .stream_start   (stream_start),
    .pix_data       (pix_data),
    .pix_valid      (pix_valid),
    .pix_ready      (pix_ready),
    .item_valid     (ws_v),
    .item           (ws_item),
    .item_ready     (ws_r),
    .sink_can_accept(fifo_out_ready)   // conservative hint
  );

  // === ARBITER (init has priority) ===
  logic       arb_v;
  wr_item_t   arb_item;
  logic       arb_r;

  two_src_arb u_arb (
    .clk     (clk),
    .rst_n   (rst_n),
    .a_valid (init_v),
    .a_item  (init_item),
    .a_ready (init_r),
    .b_valid (ws_v),
    .b_item  (ws_item),
    .b_ready (ws_r),
    .o_valid (arb_v),
    .o_item  (arb_item),
    .o_ready (arb_r)
  );

  // === FIFO between high-level and 8080 engine ===
  logic       fifo_in_ready;

  stream_fifo #(.DEPTH(FIFO_DEPTH)) u_fifo (
    .clk       (clk),
    .rst_n     (rst_n),
    .in_valid  (arb_v),
    .in_item   (arb_item),
    .in_ready  (arb_r),
    .out_valid (fifo_out_valid),
    .out_item  (fifo_out_item),
    .out_ready (fifo_out_ready)
  );

  // === 8080 write engine ===
  lcd8080_writer #(
    .WR_PULSE_CYC (WR_PULSE_CYC),
    .WR_RECOV_CYC (WR_RECOV_CYC)
  ) u_wr (
    .clk        (clk),
    .rst_n      (rst_n),
    .item_valid (fifo_out_valid),
    .item_is_cmd(fifo_out_item.is_cmd),
    .item_byte  (fifo_out_item.byte_pack),
    .item_ready (fifo_out_ready),
    .lcd_cs_n   (lcd_cs_n),
    .lcd_rd_n   (lcd_rd_n),
    .lcd_dc     (lcd_dc),
    .lcd_wr_n   (lcd_wr_n),
    .lcd_d      (lcd_d)
  );

  // === Busy flag ===
  // busy while init not in DONE state (exposed by init_done), or WS in active state,
  // or FIFO not empty (we can infer from fifo_out_valid or track internal pointers).
  // Simple heuristic: busy if anything valid at FIFO output or either producer asserts valid.
  assign busy = fifo_out_valid | init_v | ws_v;

endmodule
