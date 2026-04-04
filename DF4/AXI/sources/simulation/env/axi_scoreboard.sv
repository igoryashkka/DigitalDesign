import uvm_pkg::*;
`include "uvm_macros.svh"
`uvm_analysis_imp_decl(_in)
`uvm_analysis_imp_decl(_out)


class axi_scoreboard extends uvm_component;
  `uvm_component_utils(axi_scoreboard)
  uvm_analysis_imp_in  #(axi_transation#(32), axi_scoreboard) in_imp;
  uvm_analysis_imp_out #(axi_transation#(32),  axi_scoreboard) out_imp;

  uvm_analysis_port #(axi_transation#(32)) ap_in;
  uvm_analysis_port #(axi_transation#(32))  ap_out;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap_in  = new("ap_in", this);
    ap_out = new("ap_out", this);
    in_imp  = new("in_imp", this);
    out_imp = new("out_imp", this);
  endfunction


  function void write_in(axi_transation#(32) t);
    ap_in.write(t);
  endfunction

  function void write_out(axi_transation#(32) t);
    ap_out.write(t);
  endfunction

endclass
