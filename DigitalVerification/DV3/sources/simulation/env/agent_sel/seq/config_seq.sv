class sel_base_seq extends uvm_sequence #(config_transation);
  `uvm_object_utils(sel_base_seq)

  logic [1:0] filter_type = 2'b00;

  function new(string name = "sel_spec_seq");
    super.new(name);
  endfunction

  virtual task body();
    config_transation tr;
    tr = config_transation::type_id::create("tr");
    start_item(tr);
    tr.config_select = filter_type;
    `uvm_info(get_type_name(), $sformatf("Sending %s", tr.convert2str()), UVM_MEDIUM)
    finish_item(tr);
    #30;
  endtask
endclass
