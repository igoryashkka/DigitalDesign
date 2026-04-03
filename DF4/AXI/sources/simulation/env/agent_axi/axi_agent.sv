import tb_pkg::*;


class axi_agent #(parameter int DW=32) extends uvm_agent;
  `uvm_component_param_utils(axi_agent#(DW))

    uvm_sequencer #(axi_transation#(DW)) seqr;  
    axi_driver    #(DW)                drv;
    axi_monitor   #(DW)                mon;
    virtual axi_if #(DW)               vif;

    bit is_master;
    axi_agent_cfg #(DW)                cfg;
    uvm_active_passive_enum            is_active;

    function new(string name, uvm_component parent);
      super.new(name, parent);  
    endfunction

    function void build_phase(uvm_phase phase);
     super.build_phase(phase);

    if (uvm_config_db#(axi_agent_cfg#(DW))::get(this, "", "cfg", cfg)) begin
      is_master = cfg.is_master;
      is_active = cfg.is_active;
      vif = cfg.vif;
    end

    if (is_active == UVM_ACTIVE) begin
      seqr = uvm_sequencer#(axi_transation#(DW))::type_id::create("seqr",this);
      drv  = axi_driver#(DW)::type_id::create("drv", this);
    end

    mon  = axi_monitor#(DW)::type_id::create("mon", this);

    uvm_config_db#(bit)::set(this,"drv","is_master",is_master);
    uvm_config_db#(bit)::set(this,"mon","is_master",is_master);
    uvm_config_db#(virtual axi_if#(DW))::set(this,"drv","vif",vif);
    uvm_config_db#(virtual axi_if#(DW))::set(this,"mon","vif",vif);

    endfunction



     function void connect_phase(uvm_phase phase);
        if (is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
        end
    endfunction
endclass