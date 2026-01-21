class config_monitor extends uvm_monitor;

  `uvm_component_utils(config_monitor)

  virtual config_if vif;
  uvm_analysis_port #(config_transation) ap;
  bit is_master;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
      ap = new("ap", this);
    if (!uvm_config_db#(virtual config_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", $sformatf("No vif for %s", get_full_name()))
    end

    // if (!uvm_config_db#(bit)::get(this, "", "is_master", is_master)) begin
    //   is_master = 1;
    // end
  endfunction

  task run_phase(uvm_phase phase);
    logic [1:0] last_config;
    last_config = 'x;

    forever begin
      @(posedge vif.clk);
      if (vif.config_select !== last_config) begin
        config_transation tr;
        tr = config_transation::type_id::create($sformatf("%s_tr", get_full_name()));
        tr.config_select = vif.config_select;
        ap.write(tr);
        last_config = vif.config_select;
        `uvm_info("CFG_MON", $sformatf("[%0t][%s] config_select=0x%0h", $time, (is_master ? "MST" : "SLV"), tr.config_select), UVM_MEDIUM)
      end
    end
  endtask
endclass
