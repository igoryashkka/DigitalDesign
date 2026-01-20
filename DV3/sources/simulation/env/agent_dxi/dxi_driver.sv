class dxi_driver #(parameter int DW=72) extends uvm_driver #(dxi_transation#(DW));

  `uvm_component_param_utils(dxi_driver#(DW))

  virtual dxi_if #(DW) vif;
  bit is_master;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual dxi_if#(DW))::get(this, "", "vif", vif)) begin
     `uvm_fatal("NOVIF", $sformatf("No vif for %s", get_full_name()))
     end

    if (!uvm_config_db#(bit)::get(this, "", "is_master", is_master)) begin
     is_master = 0;
    end
  endfunction

  task run_phase(uvm_phase phase);
    if (is_master) begin
      vif.valid <= 0;
      vif.data  <= '0;
    end else begin
      vif.ready <= 0;
    end

  forever begin
      dxi_transation#(DW) tr;
      seq_item_port.get_next_item(tr);

      repeat (tr.delay) @(posedge vif.clk);

      if (is_master) drive_mst(tr.data);
      else           drive_slv();

      seq_item_port.item_done();
    end
  endtask

  task drive_mst(logic [DW-1:0] data);
    vif.data  <= data;
    vif.valid <= 1;
    @(posedge vif.clk);
    while (!vif.ready) @(posedge vif.clk);
    vif.valid <= 0;
  endtask

  task drive_slv();
    vif.ready <= 1;
    @(posedge vif.clk);
    vif.ready <= 0;
  endtask
endclass
