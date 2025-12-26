class dxi_env extends uvm_env;
  `uvm_component_utils(dxi_env)

  dxi_agent #(72) in_agent;
  dxi_agent #(8)  out_agent;

  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    in_agent  = dxi_agent#(72)::type_id::create("in_agent",this);
    out_agent = dxi_agent#(8) ::type_id::create("out_agent",this);
  endfunction
endclass