import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_env extends uvm_env;
  `uvm_component_utils(axi_env)

  axi_agent #(32) mst_agent;
  axi_agent #(32) slv_agent;
  axi_agent_cfg #(32) mst_cfg;
  axi_agent_cfg #(32) slv_cfg;
  axi_scoreboard       scoreboard;

  virtual axi_lite_if #(32) mst_vif;
  virtual axi_lite_if #(32) slv_vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual axi_lite_if#(32))::get(this, "", "mst_vif", mst_vif)) begin
      `uvm_fatal("NO_MST_VIF", "axi_env: mst_vif is not set")
    end
    if (!uvm_config_db#(virtual axi_lite_if#(32))::get(this, "", "slv_vif", slv_vif)) begin
      `uvm_fatal("NO_SLV_VIF", "axi_env: slv_vif is not set")
    end

    mst_cfg = axi_agent_cfg#(32)::type_id::create("mst_cfg");
    slv_cfg = axi_agent_cfg#(32)::type_id::create("slv_cfg");

    mst_cfg.vif = mst_vif;
    mst_cfg.is_master = 1'b1;
    mst_cfg.is_active = UVM_PASSIVE;

    slv_cfg.vif = slv_vif;
    slv_cfg.is_master = 1'b0;
    slv_cfg.is_active = UVM_PASSIVE;

    uvm_config_db#(axi_agent_cfg#(32))::set(this, "mst_agent", "cfg", mst_cfg);
    uvm_config_db#(axi_agent_cfg#(32))::set(this, "slv_agent", "cfg", slv_cfg);

    mst_agent  = axi_agent#(32)::type_id::create("mst_agent", this);
    slv_agent  = axi_agent#(32)::type_id::create("slv_agent", this);
    scoreboard = axi_scoreboard::type_id::create("scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mst_agent.mon.ap.connect(scoreboard.mst_imp);
    slv_agent.mon.ap.connect(scoreboard.slv_imp);
  endfunction
endclass
