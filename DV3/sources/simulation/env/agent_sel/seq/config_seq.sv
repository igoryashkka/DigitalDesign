class config_seq extends uvm_sequence #(config_transation);
  `uvm_object_utils(config_seq)

  rand int unsigned n_items;
  constraint c_n_items { n_items inside {[1:50]}; }

  function new(string name = "config_seq");
    super.new(name);
  endfunction

  task body();
    config_transation tr;

    if (starting_phase != null)
      starting_phase.raise_objection(this);

    repeat (n_items) begin
      tr = config_transation::type_id::create("tr");
      start_item(tr);
      if (!tr.randomize()) begin
        `uvm_fatal(get_type_name(), "Config: tr.randomize() failed")
      end
      finish_item(tr);
    end

    if (starting_phase != null)
      starting_phase.drop_objection(this);
  endtask
endclass
