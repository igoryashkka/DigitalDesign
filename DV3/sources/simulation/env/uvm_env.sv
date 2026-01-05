import uvm_pkg::*;
`include "uvm_macros.svh"


class uvm_env extends uvm_pkg::uvm_env;
  `uvm_component_utils(uvm_env)

  dxi_agent #(72) in_agent;
  dxi_agent #(8)  out_agent;
  dxi_scoreboard  scoreboard;
  virtual config_if cfg_vif;

  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual config_if)::get(this, "", "cfg_vif", cfg_vif)) begin
      `uvm_fatal("NO_CFG_VIF", $sformatf("No cfg_vif for %s", get_full_name()))
    end

    in_agent  = dxi_agent#(72)::type_id::create("in_agent",this);
    out_agent = dxi_agent#(8) ::type_id::create("out_agent",this);
    scoreboard = dxi_scoreboard::type_id::create("scoreboard", this);

    uvm_config_db#(virtual config_if)::set(this, "scoreboard", "cfg_vif", cfg_vif);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    in_agent.mon.ap.connect(scoreboard.in_imp);
    out_agent.mon.ap.connect(scoreboard.out_imp);
  endfunction
endclass
