class confg_agent_cfg extends uvm_object;
  `uvm_object_utils(confg_agent_cfg)

  virtual interface filter_confg_if vif;
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  

  function new(string name = "confg_agent_cfg");
    super.new(name);
  endfunction
endclass : confg_agent_cfg