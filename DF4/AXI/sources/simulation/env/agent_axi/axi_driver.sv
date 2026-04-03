class axi_driver #(parameter int DW=32) extends uvm_driver;

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
    uvm_sequence_item req;
    logic [DW-1:0] rd_data;
    logic [1:0]    rd_resp;

    reset_master_outputs();
    wait_reset_release();

    forever begin
      seq_item_port.get_next_item(req);

      if (is_master) begin
        drive_default_write('h0000_0000, 32'hA5A5_0001, 3'b000);
        drive_default_read('h0000_0000, rd_data, rd_resp, 3'b000);
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
    input logic [2:0]    prot
  );
    vif.awaddr  <= addr;
    vif.awprot  <= prot;
    vif.wdata   <= data;
    vif.awvalid <= 1'b1;
    vif.wvalid  <= 1'b1;

    do @(posedge vif.aclk); while (!(vif.awvalid && vif.awready));
    vif.awvalid <= 1'b0;

    do @(posedge vif.aclk); while (!(vif.wvalid && vif.wready));
    vif.wvalid <= 1'b0;

    vif.bready <= 1'b1;
    do @(posedge vif.aclk); while (!vif.bvalid);
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