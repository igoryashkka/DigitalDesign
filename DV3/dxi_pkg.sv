
package dxi_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "dxi_sequence_item.sv"
  `include "dxi_master_seq.sv"
  `include "dxi_slave_ready_seq.sv"
  `include "dxi_driver.sv"
  `include "dxi_monitor.sv"      
  `include "dxi_agent.sv"
  `include "dxi_env.sv"

  // --------- tests ----------
  `include "random_uvm_test.sv"

endpackage
