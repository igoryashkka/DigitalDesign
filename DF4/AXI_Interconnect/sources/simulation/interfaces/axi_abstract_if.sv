// AXI Common Interface.

interface axi_abstract_if #(
	parameter int DW = 32,
	parameter int AW = DW,
	parameter int IW = 4
);
	logic aclk;
	logic aresetn;

	// Common write-address channel
	logic [IW-1:0] awid;
	logic [AW-1:0] awaddr;
	logic [2:0]    awprot;
	logic          awvalid;
	logic          awready;

	// Common write-data channel
	logic [DW-1:0]     wdata;
	logic [(DW/8)-1:0] wstrb;
	logic              wlast;
	logic              wvalid;
	logic              wready;

	// Common write-response channel
	logic [IW-1:0] bid;
	logic [1:0] bresp;
	logic       bvalid;
	logic       bready;

	// Common read-address channel
	logic [IW-1:0] arid;
	logic [AW-1:0] araddr;
	logic [2:0]    arprot;
	logic          arvalid;
	logic          arready;

	// Common read-data channel
	logic [IW-1:0] rid;
	logic [DW-1:0] rdata;
	logic [1:0]    rresp;
	logic          rlast;
	logic          rvalid;
	logic          rready;

endinterface : axi_abstract_if
