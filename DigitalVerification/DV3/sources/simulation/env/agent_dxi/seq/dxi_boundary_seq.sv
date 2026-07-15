class dxi_boundary_seq #(int DW=72) extends uvm_sequence #(dxi_transation#(DW));
  `uvm_object_param_utils(dxi_boundary_seq#(DW))

  localparam logic [71:0] BOUNDARY_PATTERNS [10] = '{
    72'h00_00_00_00_00_00_00_00_00,
    72'hFF_FF_FF_FF_FF_FF_FF_FF_FF,
    72'h00_00_00_00_FF_00_00_00_00,
    72'hFF_FF_FF_FF_00_FF_FF_FF_FF,
    72'h00_00_00_FF_FF_FF_FF_FF_FF,
    72'h00_00_00_FF_FF_FF_FF_FF_FF,
    72'h00_FF_00_FF_00_FF_00_FF_00,
    72'hFF_00_FF_00_FF_00_FF_00_FF,
    72'h00_20_40_60_80_A0_C0_E0_FF,
    72'hFF_E0_C0_A0_80_60_40_20_00
  };

  function new(string name="dxi_boundary_seq");
    super.new(name);
  endfunction

  task body();
    dxi_transation#(DW) tr;
    string tr_name;

    if (DW != 72) begin
      `uvm_fatal(get_type_name(), $sformatf("Boundary sequence expects DW=72, got %0d", DW))
    end

    foreach (BOUNDARY_PATTERNS[i]) begin
      tr_name = $sformatf("boundary_tr_p%0d", i);
      tr = dxi_transation#(DW)::type_id::create(tr_name);

      start_item(tr);
      tr.data      = BOUNDARY_PATTERNS[i];
      tr.use_delay = 0;
      tr.delay     = 1;
      finish_item(tr);
    end

  endtask
endclass
