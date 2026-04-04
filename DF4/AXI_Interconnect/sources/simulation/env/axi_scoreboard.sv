import uvm_pkg::*;
`include "uvm_macros.svh"
`uvm_analysis_imp_decl(_mst)
`uvm_analysis_imp_decl(_slv)

class axi_scoreboard extends uvm_component;
  `uvm_component_utils(axi_scoreboard)

  uvm_analysis_imp_mst #(axi_transaction#(32), axi_scoreboard) mst_imp;
  uvm_analysis_imp_slv #(axi_transaction#(32), axi_scoreboard) slv_imp;

  int unsigned mst_cnt;
  int unsigned slv_cnt;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    mst_imp = new("mst_imp", this);
    slv_imp = new("slv_imp", this);
    mst_cnt = 0;
    slv_cnt = 0;
  endfunction

  function void write_mst(axi_transaction#(32) t);
    mst_cnt++;
    `uvm_info("AXI_SCB", $sformatf("MST txn seen: count=%0d type=%s", mst_cnt, t.get_type_name()), UVM_LOW)
  endfunction

  function void write_slv(axi_transaction#(32) t);
    slv_cnt++;
    `uvm_info("AXI_SCB", $sformatf("SLV txn seen: count=%0d type=%s", slv_cnt, t.get_type_name()), UVM_LOW)
  endfunction
endclass
