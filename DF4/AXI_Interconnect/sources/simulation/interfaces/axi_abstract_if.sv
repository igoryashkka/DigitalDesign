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

	modport mst (
		input  aclk, aresetn,
		output awid, awaddr, awprot, awvalid,
		input  awready,
		output wdata, wstrb, wlast, wvalid,
		input  wready,
		input  bid, bresp, bvalid,
		output bready,
		output arid, araddr, arprot, arvalid,
		input  arready,
		input  rid, rdata, rresp, rlast, rvalid,
		output rready
	);

	modport slv (
		input  aclk, aresetn,
		input  awid, awaddr, awprot, awvalid,
		output awready,
		input  wdata, wstrb, wlast, wvalid,
		output wready,
		output bid, bresp, bvalid,
		input  bready,
		input  arid, araddr, arprot, arvalid,
		output arready,
		output rid, rdata, rresp, rlast, rvalid,
		input  rready
	);

endinterface : axi_abstract_if
