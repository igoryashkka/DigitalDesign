class config_transation extends uvm_sequence_item;
  `uvm_object_utils(config_transation)
  rand logic [1:0] config_select;

  function new(string name = "config_transation");
    super.new(name);
  endfunction

  function string convert2str();
    return $sformatf("config_select=0x%0h", config_select);
  endfunction

endclass
