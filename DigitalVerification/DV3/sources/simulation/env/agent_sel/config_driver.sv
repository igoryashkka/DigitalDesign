class config_driver extends uvm_driver #(config_transation);

  `uvm_component_utils(config_driver)
  virtual config_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual config_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", $sformatf("No vif for %s", get_full_name()))
    end

  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      config_transation tr;
      seq_item_port.get_next_item(tr);
      @(posedge vif.clk);
      vif.config_select <= tr.config_select;
      @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask
endclass