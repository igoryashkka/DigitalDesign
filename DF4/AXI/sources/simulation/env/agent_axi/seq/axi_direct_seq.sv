class axi_direct_seq #(int DW=32) extends uvm_sequence #(axi_transaction#(DW));
  `uvm_object_param_utils(axi_direct_seq#(DW))

  logic [DW-1:0] wr_data = 32'h0000_00A5;
  logic [(DW/8)-1:0] wr_strb = '1;
  logic [2:0]    wr_prot = 3'b000;
  logic [DW-1:0] wr_data_step = 32'h1;

  bit do_check = 1'b1;

  function new(string name="axi_direct_seq");
    super.new(name);
  endfunction

  task body();
    axi_write_transaction#(DW) wtr;
    logic [DW-1:0] cur_data;
    logic [DW-1:0] wr_addresses [0:3];

    cur_data = wr_data;
    wr_addresses[0] = 32'h4000_0000;
    wr_addresses[1] = 32'h4000_0000;
    wr_addresses[2] = 32'h4000_0004;
    wr_addresses[3] = 32'h4000_0004;

    for (int i = 0; i < 4; i++) begin
      wtr = axi_write_transaction#(DW)::type_id::create("wtr");
      start_item(wtr);
      wtr.kind      = AXI_OP_WRITE;
      wtr.aw.addr   = wr_addresses[i];
      wtr.aw.prot   = wr_prot;
      wtr.w.data    = cur_data;
      wtr.w.strb    = wr_strb;
      wtr.use_delay = 0;
      wtr.delay     = 1;
      finish_item(wtr);

      cur_data = cur_data + wr_data_step;
    end
  endtask
endclass
