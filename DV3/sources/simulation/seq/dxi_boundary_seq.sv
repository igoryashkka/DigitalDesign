class dxi_boundary_seq #(int DW=72) extends uvm_sequence #(dxi_transation#(DW));
  `uvm_object_param_utils(dxi_boundary_seq#(DW))

  // Handle used to program DUT filter selection before driving each pattern set.
  virtual config_if cfg_vif;

  // Fixed boundary patterns and filter selections.
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

  localparam logic [1:0] FILTERS [4] = '{2'b00, 2'b01, 2'b10, 2'b11};

  function new(string name="dxi_boundary_seq");
    super.new(name);
  endfunction

  task body();
    dxi_transation#(DW) tr;
    string tr_name;

    if (starting_phase != null)
      starting_phase.raise_objection(this);

    if (cfg_vif == null) begin
      `uvm_fatal(get_type_name(), "cfg_vif is not set for boundary sequence")
    end

    if (DW != 72) begin
      `uvm_fatal(get_type_name(), $sformatf("Boundary sequence expects DW=72, got %0d", DW))
    end

    foreach (FILTERS[f]) begin
      cfg_vif.config_select <= FILTERS[f];
      @(posedge cfg_vif.clk);

      foreach (BOUNDARY_PATTERNS[i]) begin
        tr_name = $sformatf("boundary_tr_f%0d_p%0d", f, i);
        tr = dxi_transation#(DW)::type_id::create(tr_name);

        start_item(tr);
        tr.data      = BOUNDARY_PATTERNS[i];
        tr.use_delay = 0;
        tr.delay     = 1;
        finish_item(tr);
      end
    end

    if (starting_phase != null)
      starting_phase.drop_objection(this);
  endtask
endclass
