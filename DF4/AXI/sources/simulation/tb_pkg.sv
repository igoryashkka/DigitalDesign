package tb_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // AXI agent
  `include "env/agent_axi/seq/axi_transaction.sv"
  `include "env/agent_axi/seq/axi_write_seq.sv"
  `include "env/agent_axi/seq/axi_read_seq.sv"
  `include "env/agent_axi/seq/axi_direct_seq.sv"
  `include "env/agent_axi/axi_agent_cfg.sv"
  `include "env/agent_axi/axi_driver.sv"
  `include "env/agent_axi/axi_monitor.sv"
  `include "env/agent_axi/axi_agent.sv"

  // AXI environment
  `include "env/axi_scoreboard.sv"
  `include "env/uvm_env.sv"

  // Tests
  `include "tests/direct_uvm_test.sv"
  `include "tests/random_uvm_test.sv"

endpackage