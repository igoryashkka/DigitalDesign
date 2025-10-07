import ili934x_pkg::*;

module two_src_arb(
  input  logic       clk,
  input  logic       rst_n,

  // src A (higher priority) – init
  input  logic       a_valid,
  input  wr_item_t   a_item,
  output logic       a_ready,

  // src B – win/stream
  input  logic       b_valid,
  input  wr_item_t   b_item,
  output logic       b_ready,

  // sink (to FIFO)
  output logic       o_valid,
  output wr_item_t   o_item,
  input  logic       o_ready
);
  always_comb begin
    // default
    o_valid = 1'b0;
    o_item  = '{is_cmd:1'b0, byte_pack:8'h00};
    a_ready = 1'b0;
    b_ready = 1'b0;

    if (a_valid) begin
      o_valid = 1'b1;
      o_item  = a_item;
      a_ready = o_ready;
    end else if (b_valid) begin
      o_valid = 1'b1;
      o_item  = b_item;
      b_ready = o_ready;
    end
  end
endmodule
