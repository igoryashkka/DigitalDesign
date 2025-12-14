class dxi_env extends uvm_env;
  `uvm_component_utils(dxi_env)

  dxi_agent #(72) in_agent;
  dxi_agent #(8)  out_agent;
  dxi_scoreboard scb;

  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    in_agent  = dxi_agent#(72)::type_id::create("in_agent",this);
    out_agent = dxi_agent#(8)::type_id::create("out_agent",this);
   // scb       = dxi_scoreboard::type_id::create("scb",this);
  endfunction

  function void connect_phase(uvm_phase phase);
   // in_agent.mon.ap.connect(scb.in_fifo.analysis_export);
   // out_agent.mon.ap.connect(scb.out_fifo.analysis_export);
  endfunction
endclass
