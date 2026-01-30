// AXI4-Lite Slave (skeleton)
// TODO: implement read/write logic, register interface, and response handling

module axi4_lite_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                      ACLK,
    input  wire                      ARESETN,

    // Write address channel
    input  wire [ADDR_WIDTH-1:0]     S_AXI_AWADDR,
    input  wire                      S_AXI_AWVALID,
    output wire                      S_AXI_AWREADY,

    // Write data channel
    input  wire [DATA_WIDTH-1:0]     S_AXI_WDATA,
    input  wire [(DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire                      S_AXI_WVALID,
    output wire                      S_AXI_WREADY,

    // Write response channel
    output wire [1:0]                S_AXI_BRESP,
    output wire                      S_AXI_BVALID,
    input  wire                      S_AXI_BREADY,

    // Read address channel
    input  wire [ADDR_WIDTH-1:0]     S_AXI_ARADDR,
    input  wire                      S_AXI_ARVALID,
    output wire                      S_AXI_ARREADY,

    // Read data channel
    output wire [DATA_WIDTH-1:0]     S_AXI_RDATA,
    output wire [1:0]                S_AXI_RRESP,
    output wire                      S_AXI_RVALID,
    input  wire                      S_AXI_RREADY
);

// -----------------------
// TODO: Implementation plan
// -----------------------
// - Implement AW/R handshake and store address
// - Implement write path: use AWADDR + WDATA + WSTRB to update internal registers
// - Implement read path: decode ARADDR and return read data
// - Provide response signals (OKAY / SLVERR as needed)
// - Add a simple register file interface (e.g., read_reg(addr), write_reg(addr, data, strb)) to keep this block generic
// - Add testbench in `sim/` to verify read/write, halting on error

// Placeholders to avoid synthesis errors while skeletoning
assign S_AXI_AWREADY = 1'b0;
assign S_AXI_WREADY  = 1'b0;
assign S_AXI_BRESP   = 2'b00;
assign S_AXI_BVALID  = 1'b0;
assign S_AXI_ARREADY = 1'b0;
assign S_AXI_RDATA   = {DATA_WIDTH{1'b0}};
assign S_AXI_RRESP   = 2'b00;
assign S_AXI_RVALID  = 1'b0;

endmodule
