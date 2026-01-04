import dxi_pkg::*;

class dxi_agent #(parameter int DW=72) extends uvm_agent;
  `uvm_component_param_utils(dxi_agent#(DW))

  uvm_sequencer #(dxi_sequence#(DW)) seqr;  
  dxi_driver    #(DW)                drv;
  dxi_monitor   #(DW)                mon;
  virtual dxi_if #(DW)               vif;

  bit is_master;

  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual dxi_if#(DW))::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", $sformatf("No vif for %s", get_full_name()))
    end

    void'(uvm_config_db#(bit)::get(this,"","is_master",is_master));

    seqr = uvm_sequencer#(dxi_sequence#(DW))::type_id::create("seqr",this);
    drv  = dxi_driver#(DW)::type_id::create("drv", this);
    mon  = dxi_monitor#(DW)::type_id::create("mon", this);

    uvm_config_db#(bit)::set(this,"drv","is_master",is_master);
    uvm_config_db#(bit)::set(this,"mon","is_master",is_master);
    uvm_config_db#(virtual dxi_if#(DW))::set(this,"drv","vif",vif);
    uvm_config_db#(virtual dxi_if#(DW))::set(this,"mon","vif",vif);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
