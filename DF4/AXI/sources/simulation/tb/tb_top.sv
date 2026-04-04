`timescale 1ns/1ps
import uvm_pkg::*;
`include "uvm_macros.svh"
import tb_pkg::*;

module tb_top;
  localparam int ADDR_WIDTH = 32;
  localparam int DATA_WIDTH = 32;
  localparam int GPIO_ADDR_WIDTH = 6;
  localparam int S_COUNT = 2;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;

  axi_lite_if #(DATA_WIDTH) mst_if(); // UVM master <-> interconnect (S side slot 0)
  axi_lite_if #(DATA_WIDTH) gen_if(); // Traffic generator <-> interconnect (S side slot 1)
  axi_lite_if #(DATA_WIDTH) slv_if(); // interconnect (M side) <-> gpio slave

  logic [S_COUNT*ADDR_WIDTH-1:0] s_axi_awaddr;
  logic [S_COUNT*3-1:0]          s_axi_awprot;
  logic [S_COUNT-1:0]            s_axi_awvalid;
  logic [S_COUNT-1:0]            s_axi_awready;
  logic [S_COUNT*DATA_WIDTH-1:0] s_axi_wdata;
  logic [S_COUNT*(DATA_WIDTH/8)-1:0] s_axi_wstrb;
  logic [S_COUNT-1:0]            s_axi_wvalid;
  logic [S_COUNT-1:0]            s_axi_wready;
  logic [S_COUNT*2-1:0]          s_axi_bresp;
  logic [S_COUNT-1:0]            s_axi_bvalid;
  logic [S_COUNT-1:0]            s_axi_bready;
  logic [S_COUNT*ADDR_WIDTH-1:0] s_axi_araddr;
  logic [S_COUNT*3-1:0]          s_axi_arprot;
  logic [S_COUNT-1:0]            s_axi_arvalid;
  logic [S_COUNT-1:0]            s_axi_arready;
  logic [S_COUNT*DATA_WIDTH-1:0] s_axi_rdata;
  logic [S_COUNT*2-1:0]          s_axi_rresp;
  logic [S_COUNT-1:0]            s_axi_rvalid;
  logic [S_COUNT-1:0]            s_axi_rready;

  logic [ADDR_WIDTH-1:0] atg_awaddr;
  logic [2:0]            atg_awprot;
  logic                  atg_awvalid;
  logic                  atg_awready;
  logic [DATA_WIDTH-1:0] atg_wdata;
  logic [(DATA_WIDTH/8)-1:0] atg_wstrb;
  logic                  atg_wvalid;
  logic                  atg_wready;
  logic [1:0]            atg_bresp;
  logic                  atg_bvalid;
  logic                  atg_bready;
  logic                  atg_done;
  logic [31:0]           atg_status;

  tri [7:0] gpio_io;
  logic [7:0] gpio_out;

 
  assign mst_if.aclk = clk;
  assign gen_if.aclk = clk;
  assign slv_if.aclk = clk;
  assign mst_if.aresetn = rst_n;
  assign gen_if.aresetn = rst_n;
  assign slv_if.aresetn = rst_n;

  // Traffic generator CH1 drives slot1 as AXI-Lite master.
  assign gen_if.awaddr  = atg_awaddr;
  assign gen_if.awprot  = atg_awprot;
  assign gen_if.awvalid = atg_awvalid;
  assign atg_awready    = gen_if.awready;

  assign gen_if.wdata   = atg_wdata;
  assign gen_if.wstrb   = atg_wstrb;
  assign gen_if.wvalid  = atg_wvalid;
  assign atg_wready     = gen_if.wready;

  assign atg_bresp      = gen_if.bresp;
  assign atg_bvalid     = gen_if.bvalid;
  assign gen_if.bready  = atg_bready;

  assign gen_if.araddr  = '0;
  assign gen_if.arprot  = '0;
  assign gen_if.arvalid = 1'b0;
  assign gen_if.rready  = 1'b0;

  // Pack two masters into interconnect S-side vectors: slot 0 = mst_if, slot 1 = gen_if.
  assign s_axi_awaddr  = {gen_if.awaddr,  mst_if.awaddr};
  assign s_axi_awprot  = {gen_if.awprot,  mst_if.awprot};
  assign s_axi_awvalid = {gen_if.awvalid, mst_if.awvalid};
  assign {gen_if.awready, mst_if.awready} = s_axi_awready;

  assign s_axi_wdata   = {gen_if.wdata,   mst_if.wdata};
  assign s_axi_wstrb   = {gen_if.wstrb,   mst_if.wstrb};
  assign s_axi_wvalid  = {gen_if.wvalid,  mst_if.wvalid};
  assign {gen_if.wready, mst_if.wready} = s_axi_wready;

  assign {gen_if.bresp, mst_if.bresp}    = s_axi_bresp;
  assign {gen_if.bvalid, mst_if.bvalid}  = s_axi_bvalid;
  assign s_axi_bready  = {gen_if.bready,  mst_if.bready};

  assign s_axi_araddr  = {gen_if.araddr,  mst_if.araddr};
  assign s_axi_arprot  = {gen_if.arprot,  mst_if.arprot};
  assign s_axi_arvalid = {gen_if.arvalid, mst_if.arvalid};
  assign {gen_if.arready, mst_if.arready} = s_axi_arready;

  assign {gen_if.rdata, mst_if.rdata}    = s_axi_rdata;
  assign {gen_if.rresp, mst_if.rresp}    = s_axi_rresp;
  assign {gen_if.rvalid, mst_if.rvalid}  = s_axi_rvalid;
  assign s_axi_rready  = {gen_if.rready,  mst_if.rready};

  // DUT #1: AXI-Lite interconnect
  axi_lite_interconnect #(
    .S_COUNT(S_COUNT),
    .M_COUNT(1),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .M_BASE_ADDR(32'h4000_0000),
    .M_ADDR_MASK(32'hFFFF_FFC0)
  ) dut_ic (
    .clk(clk),
    .rst_n(rst_n),

    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awprot(s_axi_awprot),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),

    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),

    .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),

    .s_axi_araddr(s_axi_araddr),
    .s_axi_arprot(s_axi_arprot),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),

    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),

    .m_axi_awaddr(slv_if.awaddr),
    .m_axi_awprot(slv_if.awprot),
    .m_axi_awvalid(slv_if.awvalid),
    .m_axi_awready(slv_if.awready),

    .m_axi_wdata(slv_if.wdata),
    .m_axi_wstrb(slv_if.wstrb),
    .m_axi_wvalid(slv_if.wvalid),
    .m_axi_wready(slv_if.wready),

    .m_axi_bresp(slv_if.bresp),
    .m_axi_bvalid(slv_if.bvalid),
    .m_axi_bready(slv_if.bready),

    .m_axi_araddr(slv_if.araddr),
    .m_axi_arprot(slv_if.arprot),
    .m_axi_arvalid(slv_if.arvalid),
    .m_axi_arready(slv_if.arready),

    .m_axi_rdata(slv_if.rdata),
    .m_axi_rresp(slv_if.rresp),
    .m_axi_rvalid(slv_if.rvalid),
    .m_axi_rready(slv_if.rready)
  );

  // DUT #2: GPIO AXI-Lite slave.
  top_gpio #(
    .ADDR_WIDTH(GPIO_ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .N_GPIO(8)
  ) dut_gpio (
    .s_axi_aclk(clk),
    .s_axi_aresetn(rst_n),

    .s_axi_awaddr(slv_if.awaddr[GPIO_ADDR_WIDTH-1:0]),
    .s_axi_awvalid(slv_if.awvalid),
    .s_axi_awready(slv_if.awready),

    .s_axi_wdata(slv_if.wdata),
    .s_axi_wstrb(slv_if.wstrb),
    .s_axi_wvalid(slv_if.wvalid),
    .s_axi_wready(slv_if.wready),

    .s_axi_bresp(slv_if.bresp),
    .s_axi_bvalid(slv_if.bvalid),
    .s_axi_bready(slv_if.bready),

    .s_axi_araddr(slv_if.araddr[GPIO_ADDR_WIDTH-1:0]),
    .s_axi_arvalid(slv_if.arvalid),
    .s_axi_arready(slv_if.arready),

    .s_axi_rdata(slv_if.rdata),
    .s_axi_rresp(slv_if.rresp),
    .s_axi_rvalid(slv_if.rvalid),
    .s_axi_rready(slv_if.rready),

    .gpio_io(gpio_io),
    .gpio_out(gpio_out)
  );

  axi_traffic_gen_0 dut_atg (
    .s_axi_aclk(clk),
    .s_axi_aresetn(rst_n),
    .m_axi_lite_ch1_awaddr(atg_awaddr),
    .m_axi_lite_ch1_awprot(atg_awprot),
    .m_axi_lite_ch1_awvalid(atg_awvalid),
    .m_axi_lite_ch1_awready(atg_awready),
    .m_axi_lite_ch1_wdata(atg_wdata),
    .m_axi_lite_ch1_wstrb(atg_wstrb),
    .m_axi_lite_ch1_wvalid(atg_wvalid),
    .m_axi_lite_ch1_wready(atg_wready),
    .m_axi_lite_ch1_bresp(atg_bresp),
    .m_axi_lite_ch1_bvalid(atg_bvalid),
    .m_axi_lite_ch1_bready(atg_bready),
    .done(atg_done),
    .status(atg_status)
  );

  task automatic init_master_if();
    mst_if.awaddr  <= '0;
    mst_if.awprot  <= '0;
    mst_if.awvalid <= 1'b0;
    mst_if.wdata   <= '0;
    mst_if.wstrb   <= '0;
    mst_if.wvalid  <= 1'b0;
    mst_if.bready  <= 1'b0;
    mst_if.araddr  <= '0;
    mst_if.arprot  <= '0;
    mst_if.arvalid <= 1'b0;
    mst_if.rready  <= 1'b0;
  endtask

  string testname;


  initial begin
    init_master_if();
    rst_n = 1'b0;
    repeat (5) @(posedge clk);
    rst_n = 1'b1;
  end

  initial begin


    uvm_config_db#(virtual axi_lite_if#(DATA_WIDTH))::set(null, "uvm_test_top.env", "mst_vif", mst_if);
    uvm_config_db#(virtual axi_lite_if#(DATA_WIDTH))::set(null, "uvm_test_top.env", "slv_vif", slv_if);
    uvm_config_db#(virtual axi_lite_if#(DATA_WIDTH))::set(null, "uvm_test_top.env.mst_agent", "vif", mst_if);
    uvm_config_db#(virtual axi_lite_if#(DATA_WIDTH))::set(null, "uvm_test_top.env.slv_agent", "vif", slv_if);

    if (!$value$plusargs("UVM_TESTNAME=%s", testname)) begin
      testname = "direct_uvm_test";
    end
    run_test(testname);
  end
endmodule