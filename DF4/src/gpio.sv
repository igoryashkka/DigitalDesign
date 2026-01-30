// GPIO module (skeleton)
// Memory-mapped via register interface (connect to AXI slave)

module gpio_regfile #(
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rstn,

    // Register interface (simple APB-like signals or custom)
    input  wire [31:0]           reg_addr,
    input  wire [DATA_WIDTH-1:0] reg_wdata,
    input  wire                  reg_we,
    input  wire [(DATA_WIDTH/8)-1:0] reg_wstrb,
    output reg  [DATA_WIDTH-1:0] reg_rdata,

    // GPIO pins
    input  wire [31:0]           gpio_in,
    output reg  [31:0]           gpio_out,
    output reg  [31:0]           gpio_dir  // 0=input, 1=output
);


always @(posedge clk or negedge rstn) begin

end

endmodule
