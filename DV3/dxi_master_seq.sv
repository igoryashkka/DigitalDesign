
class dxi_master_seq #(int DW=72) extends uvm_sequence #(dxi_sequence#(DW));
  `uvm_object_param_utils(dxi_master_seq#(DW))

  function new(string name="dxi_master_seq");
    super.new(name);
  endfunction

  task body();
    dxi_sequence#(DW) tr;

    if (starting_phase != null)
      starting_phase.raise_objection(this);

    repeat (tr.delay) begin
      tr = dxi_sequence#(DW)::type_id::create("tr");

      start_item(tr);

      if (!tr.randomize()) begin
        `uvm_fatal(get_type_name(), "Master: tr.randomize() failed")
      end

      finish_item(tr);
    end

    if (starting_phase != null)
      starting_phase.drop_objection(this);
  endtask
endclass
