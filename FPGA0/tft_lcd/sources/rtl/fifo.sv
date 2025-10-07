import ili934x_pkg::*;

module stream_fifo #(
  parameter int DEPTH = 256
)(
  input  logic       clk,
  input  logic       rst_n,

  // push
  input  logic       in_valid,
  input  wr_item_t   in_item,
  output logic       in_ready,

  // pop
  output logic       out_valid,
  output wr_item_t   out_item,
  input  logic       out_ready
);
  localparam int AW = $clog2(DEPTH);

  wr_item_t mem [DEPTH];
  logic [AW:0] wptr, rptr;

  wire empty = (wptr == rptr);
  wire full  = (wptr[AW-1:0] == rptr[AW-1:0]) && (wptr[AW] != rptr[AW]);

  assign in_ready  = !full;
  assign out_valid = !empty;
  assign out_item  = mem[rptr[AW-1:0]];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr <= '0; rptr <= '0;
    end else begin
      // push
      if (in_valid && in_ready) begin
        mem[wptr[AW-1:0]] <= in_item;
        wptr <= wptr + 1;
      end
      // pop
      if (out_valid && out_ready) begin
        rptr <= rptr + 1;
      end
    end
  end
endmodule
