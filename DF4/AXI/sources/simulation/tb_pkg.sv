package tb_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // AXI agent
  `include "simulation/env/agent_axi/seq/axi_transaction.sv"
  `include "simulation/env/agent_axi/axi_agent_cfg.sv"
  `include "simulation/env/agent_axi/axi_driver.sv"
  `include "simulation/env/agent_axi/axi_monitor.sv"
  `include "simulation/env/agent_axi/axi_agent.sv"

  // AXI environment
  `include "simulation/env/axi_scoreboard.sv"
  `include "simulation/env/uvm_env.sv"

  // Tests
  `include "simulation/tests/direct_uvm_test.sv"
  `include "simulation/tests/random_uvm_test.sv"

endpackage