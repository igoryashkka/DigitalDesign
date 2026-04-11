typedef enum int {
  AXI_IF_KIND_LITE = 0,
  AXI_IF_KIND_FULL = 1,
  AXI_IF_KIND_ABSTRACT = 2
} axi_if_kind_e;

class axi_agent_cfg #(parameter int DW=32) extends uvm_object;
	`uvm_object_param_utils(axi_agent_cfg#(DW))

	// Backward-compatible alias for existing env/testbench code paths.
	virtual axi_lite_if #(DW) vif;
	virtual axi_lite_if #(DW)    vif_lite;
	virtual axi_if #(DW)         vif_full;
	virtual axi_abstract_if #(DW) vif_abstract;
	axi_if_kind_e if_kind = AXI_IF_KIND_LITE;
	bit is_master = 1'b1;
	uvm_active_passive_enum is_active = UVM_ACTIVE;

	function new(string name = "axi_agent_cfg");
		super.new(name);
	endfunction
endclass
