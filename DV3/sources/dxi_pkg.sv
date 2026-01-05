
package dxi_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "seq/dxi_transation.sv"
  `include "seq/dxi_master_seq.sv"
  `include "seq/dxi_slave_seq.sv"
  `include "env/dxi_driver.sv"
  `include "env/dxi_monitor.sv"      
  `include "env/dxi_agent.sv"
  `include "env/dxi_scoreboard.sv"
  `include "env/uvm_env.sv"

  // --------- tests ----------
  `include "tests/uvm_random_test.sv"

endpackage
