`timescale 1ns/1ps
import uvm_pkg::*;
`include "uvm_macros.svh"
import tb_pkg::*;

module tb_top;
  localparam int ADDR_WIDTH = 32;
  localparam int DATA_WIDTH = 32;
  localparam int GPIO_ADDR_WIDTH = 6;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;

  axi_lite_if #(DATA_WIDTH) mst_if(); // master <-> interconnect (S side)
  axi_lite_if #(DATA_WIDTH) slv_if(); // interconnect (M side) <-> gpio slave

  tri [7:0] gpio_io;
  logic [7:0] gpio_out;

 
  assign mst_if.aclk = clk;
  assign slv_if.aclk = clk;
  assign mst_if.aresetn = rst_n;
  assign slv_if.aresetn = rst_n;

  // DUT #1: AXI-Lite interconnect
  axi_lite_interconnect #(
    .S_COUNT(1),
    .M_COUNT(1),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .M_BASE_ADDR(32'h4000_0000),
    .M_ADDR_MASK(32'hFFFF_FFC0)
  ) dut_ic (
    .clk(clk),
    .rst_n(rst_n),

    .s_axi_awaddr(mst_if.awaddr),
    .s_axi_awprot(mst_if.awprot),
    .s_axi_awvalid(mst_if.awvalid),
    .s_axi_awready(mst_if.awready),

    .s_axi_wdata(mst_if.wdata),
    .s_axi_wstrb(mst_if.wstrb),
    .s_axi_wvalid(mst_if.wvalid),
    .s_axi_wready(mst_if.wready),

    .s_axi_bresp(mst_if.bresp),
    .s_axi_bvalid(mst_if.bvalid),
    .s_axi_bready(mst_if.bready),

    .s_axi_araddr(mst_if.araddr),
    .s_axi_arprot(mst_if.arprot),
    .s_axi_arvalid(mst_if.arvalid),
    .s_axi_arready(mst_if.arready),

    .s_axi_rdata(mst_if.rdata),
    .s_axi_rresp(mst_if.rresp),
    .s_axi_rvalid(mst_if.rvalid),
    .s_axi_rready(mst_if.rready),

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