class confg_agent_cfg extends uvm_object;
  `uvm_object_utils(confg_agent_cfg)

  virtual interface config_if vif;
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  bit is_master = 1'b1;
  

  function new(string name = "confg_agent_cfg");
    super.new(name);
  endfunction
endclass : confg_agent_cfg
