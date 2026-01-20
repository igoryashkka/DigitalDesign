class dxi_agent_cfg #(type data_t = int) extends uvm_object;
  `uvm_object_param_utils(dxi_agent_cfg #(data_t))

  virtual interface dxi_if #(data_t) vif;
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  bit is_master = 1; // 1 - master, 0 - slave
  
  function new(string name = "dxi_agent_cfg");
    super.new(name);
  endfunction
endclass : dxi_agent_cfg