class boundary_uvm_test extends uvm_test;
  `uvm_component_utils(boundary_uvm_test)

  uvm_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = uvm_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    dxi_boundary_seq#(72) mseq;
    dxi_slave_seq   #(8)  sseq;

    phase.raise_objection(this);

    mseq = dxi_boundary_seq#(72)::type_id::create("mseq");
    sseq = dxi_slave_seq   #(8) ::type_id::create("sseq");

    mseq.cfg_vif = env.cfg_vif;

    fork
      sseq.start(env.out_agent.seqr);
    join_none

    mseq.start(env.in_agent.seqr);

    phase.drop_objection(this);
  endtask
endclass
