class config_transation extends uvm_sequence_item;
  `uvm_object_utils(config_transation)
  rand logic [1:0] config_select;

  function new(string name = "config_transation");
    super.new(name);
  endfunction

endclass