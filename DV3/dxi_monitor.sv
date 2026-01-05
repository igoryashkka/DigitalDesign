class dxi_monitor #(parameter int DW = 72) extends uvm_monitor;

  `uvm_component_param_utils(dxi_monitor#(DW))

  virtual dxi_if #(DW) vif;
  uvm_analysis_port #(dxi_sequence#(DW)) ap;
  bit is_master;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
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
    forever begin
      @(posedge vif.clk);
      if (vif.valid && vif.ready && ^vif.data !== 1'bX) begin
        dxi_sequence#(DW) tr;
        tr = dxi_sequence#(DW)::type_id::create($sformatf("%s_tr", get_full_name()));
        tr.data = vif.data;
        ap.write(tr);
        `uvm_info("DXI_MON", $sformatf("%s monitor captured data 0x%0h", is_master ? "Input" : "Output", tr.data), UVM_LOW)
      end
    end
  endtask
endclass
