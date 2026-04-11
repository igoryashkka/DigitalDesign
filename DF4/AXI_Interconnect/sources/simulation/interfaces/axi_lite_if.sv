interface axi_lite_if #(
  parameter int DW = 32,
  parameter int AW = DW
);
  logic aclk;
  logic aresetn;

  // Write Address Channel
  logic [AW-1:0] awaddr;
  logic [2:0]    awprot;
  logic          awvalid;
  logic          awready;

  // Write Data Channel
  logic [DW-1:0] wdata;
  logic [(DW/8)-1:0] wstrb;
  logic          wvalid;
  logic          wready;

  // Write Response Channel
  logic [1:0]    bresp;
  logic          bvalid;
  logic          bready;

  // Read Address Channel
  logic [AW-1:0] araddr;
  logic [2:0]    arprot;
  logic          arvalid;
  logic          arready;

  // Read Data Channel
  logic [DW-1:0] rdata;
  logic [1:0]    rresp;
  logic          rvalid;
  logic          rready;

  modport mst (
    input  aclk, aresetn,
    output awaddr, awprot, awvalid,
    input  awready,
    output wdata, wstrb, wvalid,
    input  wready,
    input  bresp, bvalid,
    output bready,
    output araddr, arprot, arvalid,
    input  arready,
    input  rdata, rresp, rvalid,
    output rready
  );

  modport slv (
    input  aclk, aresetn,
    input  awaddr, awprot, awvalid,
    output awready,
    input  wdata, wstrb, wvalid,
    output wready,
    output bresp, bvalid,
    input  bready,
    input  araddr, arprot, arvalid,
    output arready,
    output rdata, rresp, rvalid,
    input  rready
  );

  // Same subset naming as axi_if.abstract_* for easier reuse.
  modport abstract_mst (
    input  aclk, aresetn,
    output awaddr, awprot, awvalid,
    input  awready,
    output wdata, wstrb, wvalid,
    input  wready,
    input  bresp, bvalid,
    output bready,
    output araddr, arprot, arvalid,
    input  arready,
    input  rdata, rresp, rvalid,
    output rready
  );

  modport abstract_slv (
    input  aclk, aresetn,
    input  awaddr, awprot, awvalid,
    output awready,
    input  wdata, wstrb, wvalid,
    output wready,
    output bresp, bvalid,
    input  bready,
    input  araddr, arprot, arvalid,
    output arready,
    output rdata, rresp, rvalid,
    input  rready
  );

endinterface : axi_lite_if