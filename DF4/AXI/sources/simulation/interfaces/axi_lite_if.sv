interface axi_lite_if #(parameter int DW=32);
  logic aclk;
  logic aresetn;

  // Write Address Channel
  logic [DW-1:0] awaddr;
  logic [2:0]    awprot;
  logic          awvalid;
  logic          awready;

  // Write Data Channel
  logic [DW-1:0] wdata;
  logic          wvalid;
  logic          wready;

  // Write Response Channel
  logic [1:0]    bresp;
  logic          bvalid;
  logic          bready;

  // Read Address Channel
  logic [DW-1:0] araddr;
  logic [2:0]    arprot;
  logic          arvalid;
  logic          arready;

  // Read Data Channel
  logic [DW-1:0] rdata;
  logic [1:0]    rresp;
  logic          rvalid;
  logic          rready;
    
endinterface //axi_lite_if