class random_uvm_test extends uvm_test;
  `uvm_component_utils(random_uvm_test)

  uvm_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = uvm_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    dxi_master_seq#(72)  mseq;
    dxi_slave_seq#(8)    rseq;
    sel_base_seq         sel_seq;
    int                 filter_count;

    phase.raise_objection(this);

    rseq = dxi_slave_seq#(8)  ::type_id::create("rseq");
    sel_seq = sel_base_seq::type_id::create("sel_seq");

    fork
      rseq.start(env.out_agent.seqr);
    join_none

    for (filter_count = 0; filter_count < 4; filter_count++) begin
      sel_seq.filter_type = filter_count[1:0];
      sel_seq.start(env.cfg_agent.seqr);

      mseq = dxi_master_seq#(72)::type_id::create($sformatf("mseq_f%0d", filter_count));
      mseq.start(env.in_agent.seqr);
    end

    phase.drop_objection(this);
  endtask
endclass
