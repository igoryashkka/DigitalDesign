class axi_driver #(parameter int DW=32) extends uvm_driver#(axi_transaction#(DW));

  `uvm_component_param_utils(axi_driver#(DW))

  virtual axi_lite_if #(DW) vif;
  bit is_master;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual axi_lite_if#(DW))::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", $sformatf("No vif for %s", get_full_name()))
    end

    if (!uvm_config_db#(bit)::get(this, "", "is_master", is_master)) begin
      is_master = 0;
    end
  endfunction

  task run_phase(uvm_phase phase);
    axi_transaction#(DW) req;
    axi_write_transaction#(DW) wr_req;
    axi_read_transaction#(DW)  rd_req;
    logic [DW-1:0] rd_data;
    logic [1:0]    rd_resp;
    logic [1:0]    wr_resp;

    reset_master_outputs();
    wait_reset_release();

    forever begin
      seq_item_port.get_next_item(req);

      repeat (req.delay) @(posedge vif.aclk);

      if (is_master) begin
        if ($cast(wr_req, req)) begin
          drive_default_write(wr_req.aw.addr, wr_req.w.data, wr_req.w.strb, wr_req.aw.prot, wr_resp);
          wr_req.b.resp = wr_resp;
        end else if ($cast(rd_req, req)) begin
          drive_default_read(rd_req.ar.addr, rd_data, rd_resp, rd_req.ar.prot);
          rd_req.r.data = rd_data;
          rd_req.r.resp = rd_resp;
        end else begin
          `uvm_error("AXI_DRV", $sformatf("Unsupported transaction type: %s", req.get_type_name()))
        end
      end

      seq_item_port.item_done();
    end
  endtask

  task automatic wait_reset_release();
    while (vif.aresetn !== 1'b1) begin
      @(posedge vif.aclk);
      reset_master_outputs();
    end
    @(posedge vif.aclk);
  endtask

  task automatic reset_master_outputs();
    vif.awaddr  <= '0;
    vif.awprot  <= '0;
    vif.awvalid <= 1'b0;
    vif.wdata   <= '0;
    vif.wstrb   <= '0;
    vif.wvalid  <= 1'b0;
    vif.bready  <= 1'b0;
    vif.araddr  <= '0;
    vif.arprot  <= '0;
    vif.arvalid <= 1'b0;
    vif.rready  <= 1'b0;
  endtask

  task automatic drive_default_write(
    input logic [DW-1:0] addr,
    input logic [DW-1:0] data,
    input logic [(DW/8)-1:0] strb,
    input logic [2:0]    prot,
    output logic [1:0]   resp
  );
    vif.awaddr  <= addr;
    vif.awprot  <= prot;
    vif.wdata   <= data;
    vif.wstrb   <= strb;
    vif.awvalid <= 1'b1;
    vif.wvalid  <= 1'b1;

    do @(posedge vif.aclk); while (!(vif.awvalid && vif.awready));
    vif.awvalid <= 1'b0;

    do @(posedge vif.aclk); while (!(vif.wvalid && vif.wready));
    vif.wvalid <= 1'b0;
    vif.wstrb  <= '0;

    vif.bready <= 1'b1;
    do @(posedge vif.aclk); while (!vif.bvalid);
    resp = vif.bresp;
    vif.bready <= 1'b0;
  endtask

  task automatic drive_default_read(
    input  logic [DW-1:0] addr,
    output logic [DW-1:0] data,
    output logic [1:0]    resp,
    input  logic [2:0]    prot
  );
    vif.araddr  <= addr;
    vif.arprot  <= prot;
    vif.arvalid <= 1'b1;

    do @(posedge vif.aclk); while (!(vif.arvalid && vif.arready));
    vif.arvalid <= 1'b0;

    vif.rready <= 1'b1;
    do @(posedge vif.aclk); while (!vif.rvalid);
    data = vif.rdata;
    resp = vif.rresp;
    vif.rready <= 1'b0;
  endtask

endclass