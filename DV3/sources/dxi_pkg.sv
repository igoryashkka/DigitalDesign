
package dxi_pkg;
  // ---------------- common includes --------------
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  // ---------------- dxi agent --------------
  `include "simulation/env/agent_dxi/seq/dxi_transation.sv"
  `include "simulation/env/agent_dxi/seq/dxi_master_seq.sv"
  `include "simulation/env/agent_dxi/seq/dxi_slave_seq.sv"
  `include "simulation/env/agent_dxi/seq/dxi_boundary_seq.sv"
  `include "simulation/env/agent_dxi/seq/dxi_file_seq.sv"
  `include "simulation/env/agent_dxi/dxi_agent_cfg.sv"
  `include "simulation/env/agent_dxi/dxi_driver.sv"
  `include "simulation/env/agent_dxi/dxi_monitor.sv"      
  `include "simulation/env/agent_dxi/dxi_agent.sv"
 // ---------------- config agent --------------
  `include "simulation/env/agent_sel/config_transation.sv"
  `include "simulation/env/agent_sel/seq/config_seq.sv"
  `include "simulation/env/agent_sel/config_driver.sv"
  `include "simulation/env/agent_sel/config_monitor.sv"
  `include "simulation/env/agent_sel/config_agent_cfg.sv"
  `include "simulation/env/agent_sel/config_agent.sv"
  // ---------------- scoreboard and env --------------
  `include "simulation/env/dxi_scoreboard.sv"
  `include "simulation/env/file_collector_scb.sv"
  `include "simulation/env/uvm_env.sv"
  // --------- tests ----------
  `include "tests/uvm_random_test.sv"
  `include "tests/uvm_boundary_test.sv"
  `include "tests/uvm_file_test.sv"

endpackage
