class file_uvm_test extends uvm_test;
  `uvm_component_utils(file_uvm_test)

  uvm_env env;
  file_collector_scb collector;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = uvm_env::type_id::create("env", this);
    collector = file_collector_scb::type_id::create("collector", this);

    collector.img_width  = 256;
    collector.img_height = 194;
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (env != null && collector != null) begin
      env.out_agent.mon.ap.connect(collector.out_imp);
      collector.rst_vif = env.scoreboard.rst_vif;
    end
  endfunction

  task run_phase(uvm_phase phase);
    dxi_file_seq   #(72) mseq;
    dxi_slave_seq  #(8)  sseq;

    phase.raise_objection(this);

    mseq = dxi_file_seq#(72)::type_id::create("mseq");
    sseq = dxi_slave_seq #(8)::type_id::create("sseq");

    mseq.cfg_vif = env.cfg_vif;

    fork
      mseq.start(env.in_agent.seqr);
      sseq.start(env.out_agent.seqr);
    join

    phase.drop_objection(this);
  endtask
endclass
