
package dxi_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "dxi_sequence.sv"
  `include "dxi_master_seq.sv"
  `include "dxi_slave_seq.sv"
  `include "dxi_driver.sv"
  `include "dxi_monitor.sv"      
  `include "dxi_agent.sv"
  `include "dxi_scoreboard.sv"
  `include "dxi_env.sv"

  // --------- tests ----------
  `include "uvm_random_test.sv"

endpackage
