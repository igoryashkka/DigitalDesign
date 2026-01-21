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

    if (!uvm_config_db#(virtual config_if)::get(this, "", "cfg_vif", cfg_vif)) begin
      `uvm_fatal("NO_CFG_VIF", $sformatf("No cfg_vif for %s", get_full_name()))
    end

    // ============================================================================
    // config agent config setup
    cfg_agent_cfg = confg_agent_cfg::type_id::create("cfg_agent_cfg");
    cfg_agent_cfg.vif = cfg_vif;
    cfg_agent_cfg.is_active = UVM_ACTIVE;
    cfg_agent_cfg.is_master = 1'b1;
    uvm_config_db#(confg_agent_cfg)::set(this, "cfg_agent", "cfg", cfg_agent_cfg);
    // ============================================================================
    // dxi agent configs setup
    in_agent_cfg = dxi_agent_cfg#(72)::type_id::create("in_agent_cfg");
    in_agent_cfg.is_active = UVM_ACTIVE;
    in_agent_cfg.is_master = 1'b1; // master
    uvm_config_db#(dxi_agent_cfg#(72))::set(this, "in_agent", "cfg", in_agent_cfg);

    out_agent_cfg = dxi_agent_cfg#(8)::type_id::create("out_agent_cfg");
    out_agent_cfg.is_active = UVM_ACTIVE;
    out_agent_cfg.is_master = 1'b0; // slave
    uvm_config_db#(dxi_agent_cfg#(8))::set(this, "out_agent", "cfg", out_agent_cfg);
    // ============================================================================
    // env components creation
    in_agent  = dxi_agent#(72)::type_id::create("in_agent",this);
    out_agent = dxi_agent#(8) ::type_id::create("out_agent",this);
    cfg_agent = config_agent::type_id::create("cfg_agent", this);
    scoreboard = dxi_scoreboard::type_id::create("scoreboard", this);

    uvm_config_db#(virtual config_if)::set(this, "scoreboard", "cfg_vif", cfg_vif);
    // ============================================================================
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    in_agent.mon.ap.connect(scoreboard.in_imp);
    out_agent.mon.ap.connect(scoreboard.out_imp);
  endfunction
endclass
