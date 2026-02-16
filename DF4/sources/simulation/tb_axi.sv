// tb_axi_lite_regs_if.sv
`timescale 1ns/1ps

module tb_axi_lite_regs_if;

  localparam int ADDR_WIDTH = 6;
  localparam int DATA_WIDTH = 32;
  localparam int STRB_WIDTH = DATA_WIDTH/8;

  logic s_axi_aclk;
  logic s_axi_aresetn;

  // AXI-Lite write address channel
  logic [ADDR_WIDTH-1:0] s_axi_awaddr;
  logic                  s_axi_awvalid;
  wire                   s_axi_awready;

  // AXI-Lite write data channel
  logic [DATA_WIDTH-1:0] s_axi_wdata;
  logic [STRB_WIDTH-1:0] s_axi_wstrb;
  logic                  s_axi_wvalid;
  wire                   s_axi_wready;

  // AXI-Lite write response channel
  wire [1:0]             s_axi_bresp;
  wire                   s_axi_bvalid;
  logic                  s_axi_bready;

  // AXI-Lite read address channel
  logic [ADDR_WIDTH-1:0] s_axi_araddr;
  logic                  s_axi_arvalid;
  wire                   s_axi_arready;

  // AXI-Lite read data channel
  wire [DATA_WIDTH-1:0]  s_axi_rdata;
  wire [1:0]             s_axi_rresp;
  wire                   s_axi_rvalid;
  logic                  s_axi_rready;

  // Register-file side
  wire                   axi_write_fire;
  wire [ADDR_WIDTH-1:0]  wr_addr;
  wire [DATA_WIDTH-1:0]  wr_data;
  wire [STRB_WIDTH-1:0]  wr_strb;

  wire                   axi_read_fire;
  wire [ADDR_WIDTH-1:0]  rd_addr;
  logic [DATA_WIDTH-1:0] rd_data;

  // ----------------------------
  // DUT
  // ----------------------------
  axi_lite_regs_if #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .s_axi_aclk    (s_axi_aclk),
    .s_axi_aresetn (s_axi_aresetn),

    .s_axi_awaddr  (s_axi_awaddr),
    .s_axi_awvalid (s_axi_awvalid),
    .s_axi_awready (s_axi_awready),

    .s_axi_wdata   (s_axi_wdata),
    .s_axi_wstrb   (s_axi_wstrb),
    .s_axi_wvalid  (s_axi_wvalid),
    .s_axi_wready  (s_axi_wready),

    .s_axi_bresp   (s_axi_bresp),
    .s_axi_bvalid  (s_axi_bvalid),
    .s_axi_bready  (s_axi_bready),

    .s_axi_araddr  (s_axi_araddr),
    .s_axi_arvalid (s_axi_arvalid),
    .s_axi_arready (s_axi_arready),

    .s_axi_rdata   (s_axi_rdata),
    .s_axi_rresp   (s_axi_rresp),
    .s_axi_rvalid  (s_axi_rvalid),
    .s_axi_rready  (s_axi_rready),

    .axi_write_fire(axi_write_fire),
    .wr_addr       (wr_addr),
    .wr_data       (wr_data),
    .wr_strb       (wr_strb),

    .axi_read_fire (axi_read_fire),
    .rd_addr       (rd_addr),
    .rd_data       (rd_data)
  );

  // ----------------------------
  // Clock
  // ----------------------------
  initial begin
    s_axi_aclk = 1'b0;
    forever #5 s_axi_aclk = ~s_axi_aclk; // 100MHz
  end

  // ----------------------------
  // Default init
  // ----------------------------
  initial begin
    s_axi_aresetn  = 1'b0;

    s_axi_awaddr   = '0;
    s_axi_awvalid  = 1'b0;

    s_axi_wdata    = '0;
    s_axi_wstrb    = '0;
    s_axi_wvalid   = 1'b0;

    s_axi_bready   = 1'b0;

    s_axi_araddr   = '0;
    s_axi_arvalid  = 1'b0;
    s_axi_rready   = 1'b0;

    rd_data        = '0;
  end

  // ----------------------------
  // TB reg-file model
  //  - write updates on axi_write_fire (1 pulse per write commit)
  //  - read is COMBINATIONAL from mem[rd_addr]
  // ----------------------------
  logic [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

  function automatic logic [DATA_WIDTH-1:0] apply_wstrb(
    input logic [DATA_WIDTH-1:0] oldv,
    input logic [DATA_WIDTH-1:0] newv,
    input logic [STRB_WIDTH-1:0] strb
  );
    logic [DATA_WIDTH-1:0] res;
    res = oldv;
    for (int i=0; i<STRB_WIDTH; i++) begin
      if (strb[i]) res[i*8 +: 8] = newv[i*8 +: 8];
    end
    return res;
  endfunction

  // reset/init memory + commit writes
  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      for (int i=0; i<(1<<ADDR_WIDTH); i++) mem[i] <= '0;
    end else begin
      if (axi_write_fire) begin
        mem[wr_addr] <= apply_wstrb(mem[wr_addr], wr_data, wr_strb);
      end
    end
  end

  // combinational read mux (no rd_en)
  always_comb begin
    if (!s_axi_aresetn) rd_data = '0;
    else                rd_data = mem[rd_addr];
  end

  // ----------------------------
  // Reset task
  // ----------------------------
  task automatic do_reset();
    begin
      s_axi_aresetn = 1'b0;
      repeat (3) @(posedge s_axi_aclk);
      s_axi_aresetn = 1'b1;
      @(posedge s_axi_aclk);
    end
  endtask

  // ----------------------------
  // B responder: accept write responses ASAP
  // ----------------------------
  task automatic b_responder();
    begin
      s_axi_bready <= 1'b0;
      forever begin
        @(posedge s_axi_aclk);
        if (!s_axi_aresetn) begin
          s_axi_bready <= 1'b0;
        end else begin
          if (s_axi_bvalid) begin
            assert (s_axi_bresp == 2'b00)
              else $fatal(1, "BRESP not OKAY! got %b at time %0t", s_axi_bresp, $time);

            s_axi_bready <= 1'b1;
            @(posedge s_axi_aclk);
            s_axi_bready <= 1'b0;
          end else begin
            s_axi_bready <= 1'b0;
          end
        end
      end
    end
  endtask

  // ----------------------------
  // R responder: accept read responses ASAP
  // ----------------------------
  task automatic r_responder();
    begin
      s_axi_rready <= 1'b0;
      forever begin
        @(posedge s_axi_aclk);
        if (!s_axi_aresetn) begin
          s_axi_rready <= 1'b0;
        end else begin
          if (s_axi_rvalid) begin
            assert (s_axi_rresp == 2'b00)
              else $fatal(1, "RRESP not OKAY! got %b at time %0t", s_axi_rresp, $time);

            s_axi_rready <= 1'b1;
            @(posedge s_axi_aclk);
            s_axi_rready <= 1'b0;
          end else begin
            s_axi_rready <= 1'b0;
          end
        end
      end
    end
  endtask

  // ----------------------------
  // Write driver: AW+W same cycle, then wait for commit + response accepted
  // ----------------------------
  task automatic send_aw_w_same_cycle(
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] data,
    input logic [STRB_WIDTH-1:0] strb
  );
    bit aw_done, w_done;
    begin
      aw_done = 0;
      w_done  = 0;

      s_axi_awaddr  <= addr;
      s_axi_awvalid <= 1'b1;

      s_axi_wdata   <= data;
      s_axi_wstrb   <= strb;
      s_axi_wvalid  <= 1'b1;

      // handshake AW/W independently (can complete in different cycles)
      while (!(aw_done && w_done)) begin
        @(posedge s_axi_aclk);

        if (s_axi_awvalid && s_axi_awready) aw_done = 1;
        if (s_axi_wvalid  && s_axi_wready)  w_done  = 1;

        if (aw_done) s_axi_awvalid <= 1'b0;
        if (w_done)  s_axi_wvalid  <= 1'b0;
      end

      // wait until DUT actually "commits" write to regfile side
      do @(posedge s_axi_aclk); while (!axi_write_fire);

      // also wait until write response handshake completes (b_responder drives bready)
      do @(posedge s_axi_aclk); while (!(s_axi_bvalid && s_axi_bready));

      // cleanup
      @(posedge s_axi_aclk);
      s_axi_awaddr <= '0;
      s_axi_wdata  <= '0;
      s_axi_wstrb  <= '0;
    end
  endtask

  // ----------------------------
  // Read driver: AR handshake + wait for R handshake, then compare to TB mem
  // (expects 1-cycle latency in DUT, but robustly waits for RVALID)
  // ----------------------------
  task automatic send_ar_and_check(input logic [ADDR_WIDTH-1:0] addr);
    logic [DATA_WIDTH-1:0] exp;
    begin
      // expected from TB regfile model
      exp = mem[addr];

      s_axi_araddr  <= addr;
      s_axi_arvalid <= 1'b1;

      // wait AR handshake
      do @(posedge s_axi_aclk); while (!(s_axi_arvalid && s_axi_arready));
      s_axi_arvalid <= 1'b0;
      s_axi_araddr  <= '0;

      // wait R handshake (r_responder drives rready)
      do @(posedge s_axi_aclk); while (!(s_axi_rvalid && s_axi_rready));

      // check returned data
      assert (s_axi_rdata == exp)
        else $fatal(1, "RDATA mismatch @addr %0h exp=%08h got=%08h time=%0t",
                    addr, exp, s_axi_rdata, $time);
    end
  endtask

  // ----------------------------
  // Optional protocol checker: stall AW/W while BVALID=1 (your behavior)
  // ----------------------------
  task automatic assert_stall_when_bvalid();
    begin
      if (s_axi_bvalid) begin
        assert (s_axi_awready == 1'b0)
          else $fatal(1, "AWREADY should be 0 while BVALID=1");
        assert (s_axi_wready == 1'b0)
          else $fatal(1, "WREADY should be 0 while BVALID=1");
      end
    end
  endtask

  always @(posedge s_axi_aclk) begin
    if (s_axi_aresetn) assert_stall_when_bvalid();
  end

  // ----------------------------
  // Test
  // ----------------------------
  initial begin
    do_reset();

    fork
      b_responder();
      r_responder();
    join_none

    // writes
    send_aw_w_same_cycle(6'h01, 32'h1111_0001, 4'b1111);
    send_aw_w_same_cycle(6'h02, 32'h1111_0002, 4'b1111);
    send_aw_w_same_cycle(6'h03, 32'h1111_0003, 4'b1111);
    send_aw_w_same_cycle(6'h04, 32'h1111_0004, 4'b1111);
    send_aw_w_same_cycle(6'h05, 32'h1111_0005, 4'b1111);

  
    send_ar_and_check(6'h01);
    send_ar_and_check(6'h02);
    send_ar_and_check(6'h03);

   
    fork
      begin
        send_ar_and_check(6'h01);
        send_ar_and_check(6'h04);
        send_ar_and_check(6'h05);
      end
      begin
        send_aw_w_same_cycle(6'h04, 32'hAAAA_0004, 4'b1111);
        send_aw_w_same_cycle(6'h06, 32'hBBBB_0006, 4'b1111);
        send_aw_w_same_cycle(6'h01, 32'hCCCC_0001, 4'b1111);
      end
    join

    // verify after parallel ops
    send_ar_and_check(6'h04);
    send_ar_and_check(6'h06);
    send_ar_and_check(6'h01);

    repeat (10) @(posedge s_axi_aclk);
    $display("TB DONE OK");
    $finish;
  end

endmodule
