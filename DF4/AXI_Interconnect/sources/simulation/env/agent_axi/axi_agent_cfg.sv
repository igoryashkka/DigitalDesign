class axi_agent_cfg #(parameter int DW=32) extends uvm_object;
	`uvm_object_param_utils(axi_agent_cfg#(DW))

	virtual axi_lite_if #(DW) vif;
	bit is_master = 1'b1;
	uvm_active_passive_enum is_active = UVM_ACTIVE;

	function new(string name = "axi_agent_cfg");
		super.new(name);
	endfunction
endclass
