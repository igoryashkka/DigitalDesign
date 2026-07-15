class config_agent extends uvm_agent;
  `uvm_component_utils(config_agent)

  uvm_sequencer #(config_transation) seqr;
  config_driver                     drv;
  config_monitor                    mon;
  virtual config_if                 vif;

  confg_agent_cfg cfg;
  bit is_master;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(confg_agent_cfg)::get(this, "", "cfg", cfg)) begin
      cfg = confg_agent_cfg::type_id::create("cfg");
    end

    vif = cfg.vif;
    is_master = cfg.is_master;

    if (vif == null) begin
      `uvm_fatal("NOVIF", $sformatf("No vif for %s", get_full_name()))
    end

    mon = config_monitor::type_id::create("mon", this);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = uvm_sequencer#(config_transation)::type_id::create("seqr", this);
      drv  = config_driver::type_id::create("drv", this);
    end

    uvm_config_db#(bit)::set(this, "drv", "is_master", is_master);
    uvm_config_db#(bit)::set(this, "mon", "is_master", is_master);
    uvm_config_db#(virtual config_if)::set(this, "drv", "vif", vif);
    uvm_config_db#(virtual config_if)::set(this, "mon", "vif", vif);
  endfunction

  function void connect_phase(uvm_phase phase);
    if (cfg.is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction
endclass
