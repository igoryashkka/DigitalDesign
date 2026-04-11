interface axi_if #(
	parameter int DW = 32,
	parameter int AW = DW,
	parameter int IW = 4,
	parameter int UW = 1
);
	logic aclk;
	logic aresetn;

	// Write address channel
	logic [IW-1:0] awid;
	logic [AW-1:0] awaddr;
	logic [7:0]    awlen;
	logic [2:0]    awsize;
	logic [1:0]    awburst;
	logic          awlock;
	logic [3:0]    awcache;
	logic [2:0]    awprot;
	logic [3:0]    awqos;
	logic [UW-1:0] awuser;
	logic          awvalid;
	logic          awready;

	// Write data channel
	logic [DW-1:0]     wdata;
	logic [(DW/8)-1:0] wstrb;
	logic              wlast;
	logic [UW-1:0]     wuser;
	logic              wvalid;
	logic              wready;

	// Write response channel
	logic [IW-1:0] bid;
	logic [1:0]    bresp;
	logic [UW-1:0] buser;
	logic          bvalid;
	logic          bready;

	// Read address channel
	logic [IW-1:0] arid;
	logic [AW-1:0] araddr;
	logic [7:0]    arlen;
	logic [2:0]    arsize;
	logic [1:0]    arburst;
	logic          arlock;
	logic [3:0]    arcache;
	logic [2:0]    arprot;
	logic [3:0]    arqos;
	logic [UW-1:0] aruser;
	logic          arvalid;
	logic          arready;

	// Read data channel
	logic [IW-1:0] rid;
	logic [DW-1:0] rdata;
	logic [1:0]    rresp;
	logic          rlast;
	logic [UW-1:0] ruser;
	logic          rvalid;
	logic          rready;

	// Full AXI4 modports
	modport mst (
		input  aclk, aresetn,
		output awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awuser, awvalid,
		input  awready,
		output wdata, wstrb, wlast, wuser, wvalid,
		input  wready,
		input  bid, bresp, buser, bvalid,
		output bready,
		output arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, aruser, arvalid,
		input  arready,
		input  rid, rdata, rresp, rlast, ruser, rvalid,
		output rready
	);

	modport slv (
		input  aclk, aresetn,
		input  awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awuser, awvalid,
		output awready,
		input  wdata, wstrb, wlast, wuser, wvalid,
		output wready,
		output bid, bresp, buser, bvalid,
		input  bready,
		input  arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, aruser, arvalid,
		output arready,
		output rid, rdata, rresp, rlast, ruser, rvalid,
		input  rready
	);

	// Unified subset for blocks that use only common AXI/AXI-Lite signals.
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

endinterface : axi_if
