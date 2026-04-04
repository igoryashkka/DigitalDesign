import uvm_pkg::*;
`include "uvm_macros.svh"


class uvm_env extends uvm_pkg::uvm_env;
  `uvm_component_utils(uvm_env)

  dxi_agent #(72) in_agent;
  dxi_agent #(8)  out_agent;
  dxi_agent_cfg #(72) in_agent_cfg;
  dxi_agent_cfg #(8)  out_agent_cfg;
  config_agent    cfg_agent;
  confg_agent_cfg cfg_agent_cfg;
  dxi_scoreboard  scoreboard;
  virtual config_if cfg_vif;

  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);


    // ============================================================================
    // env components creation
    axi_agent  = axi_agent#(32)::type_id::create("in_agent",this);
    // scoreboard = dxi_scoreboard::type_id::create("scoreboard", this);

    // ============================================================================
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    axi_agent.mon.ap.connect(scoreboard.in_imp);
  endfunction
endclass
