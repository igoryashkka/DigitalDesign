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
    sel_base_seq           sel_seq;

    localparam logic [1:0] FILTERS [4] = '{2'b00, 2'b01, 2'b10, 2'b11};

    phase.raise_objection(this);

    sseq = dxi_slave_seq   #(8) ::type_id::create("sseq");

    fork
      sseq.start(env.out_agent.seqr);
    join_none

    sel_seq = sel_base_seq::type_id::create("sel_seq");

    foreach (FILTERS[f]) begin
      sel_seq.filter_type = FILTERS[f];
      sel_seq.start(env.cfg_agent.seqr);

      mseq = dxi_boundary_seq#(72)::type_id::create($sformatf("mseq_f%0d", f));
      mseq.start(env.in_agent.seqr);
    end

    phase.drop_objection(this);
  endtask
endclass
