interface dxi_if #(parameter int WIDTH = 72)(input logic clk);
  logic rstn;
  logic valid;
  logic ready;
  logic [WIDTH-1:0] data;
endinterface
