import uvm_pkg::*;
`include "uvm_macros.svh"

class direct_uvm_test extends uvm_test;
  `uvm_component_utils(direct_uvm_test)

  axi_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = axi_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    axi_direct_seq#(32) seq;

    phase.raise_objection(this);

    seq = axi_direct_seq#(32)::type_id::create("seq");
    seq.start(env.mst_agent.seqr);

    phase.drop_objection(this);
  endtask
endclass
