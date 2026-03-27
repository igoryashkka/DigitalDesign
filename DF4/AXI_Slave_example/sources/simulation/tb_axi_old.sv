/* 
// tb_axi_lite_regs_if.sv

`timescale 1ns/1ps

module tb_axi_lite_regs_if;

  localparam int ADDR_WIDTH = 6;
  localparam int DATA_WIDTH = 32;
  localparam int STRB_WIDTH = DATA_WIDTH/8;


  logic s_axi_aclk;
  logic s_axi_aresetn;


  logic [ADDR_WIDTH-1:0] s_axi_awaddr;
  logic                  s_axi_awvalid;
  wire                   s_axi_awready;


  logic [DATA_WIDTH-1:0] s_axi_wdata;
  logic [STRB_WIDTH-1:0] s_axi_wstrb;
  logic                  s_axi_wvalid;
  wire                   s_axi_wready;


  wire [1:0]             s_axi_bresp;
  wire                   s_axi_bvalid;
  logic                  s_axi_bready;

  
  logic [ADDR_WIDTH-1:0] s_axi_araddr;
  logic                  s_axi_arvalid;
  wire                   s_axi_arready;

  wire [DATA_WIDTH-1:0]  s_axi_rdata;
  wire [1:0]             s_axi_rresp;
  wire                   s_axi_rvalid;
  logic                  s_axi_rready;

  // Register-file side
  wire                   axi_write_fire;
  wire [ADDR_WIDTH-1:0]  wr_addr;
  wire [DATA_WIDTH-1:0]  wr_data;
  wire [STRB_WIDTH-1:0]  wr_strb;

  wire                   rd_en;
  wire [ADDR_WIDTH-1:0]  rd_addr;
  logic [DATA_WIDTH-1:0] rd_data;

  // ----------------------------
  // DUT 
  // ----------------------------
  axi_lite_regs_if #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .s_axi_aclk   (s_axi_aclk),
    .s_axi_aresetn(s_axi_aresetn),

    .s_axi_awaddr (s_axi_awaddr),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),

    .s_axi_wdata  (s_axi_wdata),
    .s_axi_wstrb  (s_axi_wstrb),
    .s_axi_wvalid (s_axi_wvalid),
    .s_axi_wready (s_axi_wready),

    .s_axi_bresp  (s_axi_bresp),
    .s_axi_bvalid (s_axi_bvalid),
    .s_axi_bready (s_axi_bready),

    .s_axi_araddr (s_axi_araddr),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),

    .s_axi_rdata  (s_axi_rdata),
    .s_axi_rresp  (s_axi_rresp),
    .s_axi_rvalid (s_axi_rvalid),
    .s_axi_rready (s_axi_rready),

    .axi_write_fire(axi_write_fire),
    .wr_addr       (wr_addr),
    .wr_data       (wr_data),
    .wr_strb       (wr_strb),

    .rd_en        (rd_en),
    .rd_addr      (rd_addr),
    .rd_data      (rd_data)
  );


  initial begin
    s_axi_aclk = 1'b0;
    forever #5 s_axi_aclk = ~s_axi_aclk; 
  end

  // ----------------------------
  // Default init
  // ----------------------------
  initial begin
    s_axi_awaddr  = '0;
    s_axi_awvalid = 1'b0;

    s_axi_wdata   = '0;
    s_axi_wstrb   = '0;
    s_axi_wvalid  = 1'b0;

    s_axi_bready  = 1'b0;

    s_axi_araddr  = '0;
    s_axi_arvalid = 1'b0;
    s_axi_rready  = 1'b0;
    rd_data       = '0;
  end


  task automatic do_reset();
    begin
      s_axi_aresetn = 1'b0;
      repeat (3) @(posedge s_axi_aclk);
      s_axi_aresetn = 1'b1;
      @(posedge s_axi_aclk);
    end
  endtask




task automatic do_write_fast(
  input logic [ADDR_WIDTH-1:0] addr,
  input logic [DATA_WIDTH-1:0] data,
  input logic [STRB_WIDTH-1:0] strb,
  input int bready_delay_cycles = 0
);
  fork
    begin
      send_aw_w_same_cycle(addr, data, strb);
    end
  join


  complete_b(bready_delay_cycles);
endtask


  task automatic send_aw_w_same_cycle(input logic [ADDR_WIDTH-1:0] addr,
                                      input logic [DATA_WIDTH-1:0] data,
                                      input logic [STRB_WIDTH-1:0] strb);
    bit aw_done, w_done;
    begin
      aw_done = 0; w_done = 0;

      s_axi_awaddr  <= addr;
      s_axi_awvalid <= 1'b1;
      s_axi_wdata   <= data;
      s_axi_wstrb   <= strb;
      s_axi_wvalid  <= 1'b1;

      while (!(aw_done && w_done)) begin
        @(posedge s_axi_aclk);
        if (s_axi_awvalid && s_axi_awready) aw_done = 1;
        if (s_axi_wvalid  && s_axi_wready)  w_done  = 1;

        if (aw_done) s_axi_awvalid <= 1'b0;
        if (w_done)  s_axi_wvalid  <= 1'b0;
      end


      @(posedge s_axi_aclk);
      s_axi_awaddr <= '0;
      s_axi_wdata  <= '0;
      s_axi_wstrb  <= '0;
    end
  endtask


  task automatic complete_b(input int delay_cycles = 0);
    begin

      do @(posedge s_axi_aclk); while (!s_axi_bvalid);

      s_axi_bready <= 1'b1;
      @(posedge s_axi_aclk);

      while (s_axi_bvalid) @(posedge s_axi_aclk);
      s_axi_bready <= 1'b0;
    end
  endtask







 initial begin
  do_reset();

  do_write_fast(6'h01, 32'h1111_0001, 4'b1111, 0);
  do_write_fast(6'h02, 32'h1111_0002, 4'b1111, 0);
  do_write_fast(6'h03, 32'h1111_0003, 4'b1111, 0);
  do_write_fast(6'h04, 32'h1111_0004, 4'b1111, 0);
  do_write_fast(6'h05, 32'h1111_0005, 4'b1111, 0);

  $display("PASSED");
  $finish;
end

endmodule



 */