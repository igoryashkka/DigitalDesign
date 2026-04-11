typedef enum int {
  AXI_OP_WRITE = 0,
  AXI_OP_READ  = 1
} axi_op_kind_e;

class axi_aw_chan_tr #(int DW=32, int IW=4) extends uvm_object;
  `uvm_object_param_utils(axi_aw_chan_tr#(DW,IW))

  rand logic [IW-1:0] id;
  rand logic [DW-1:0] addr;
  rand logic [2:0]    prot;

  function new(string name="axi_aw_chan_tr");
    super.new(name);
  endfunction
endclass

class axi_w_chan_tr #(int DW=32) extends uvm_object;
  `uvm_object_param_utils(axi_w_chan_tr#(DW))

  rand logic [DW-1:0] data;
  rand logic [(DW/8)-1:0] strb;
  rand logic              last;

  function new(string name="axi_w_chan_tr");
    super.new(name);
  endfunction
endclass

class axi_b_chan_tr #(int IW=4) extends uvm_object;
  `uvm_object_param_utils(axi_b_chan_tr#(IW))

  rand logic [IW-1:0] id;
  rand logic [1:0] resp;

  function new(string name="axi_b_chan_tr");
    super.new(name);
  endfunction
endclass

class axi_ar_chan_tr #(int DW=32, int IW=4) extends uvm_object;
  `uvm_object_param_utils(axi_ar_chan_tr#(DW,IW))

  rand logic [IW-1:0] id;
  rand logic [DW-1:0] addr;
  rand logic [2:0]    prot;

  function new(string name="axi_ar_chan_tr");
    super.new(name);
  endfunction
endclass

class axi_r_chan_tr #(int DW=32, int IW=4) extends uvm_object;
  `uvm_object_param_utils(axi_r_chan_tr#(DW,IW))

  rand logic [IW-1:0] id;
  rand logic [DW-1:0] data;
  rand logic [1:0]    resp;
  rand logic          last;

  function new(string name="axi_r_chan_tr");
    super.new(name);
  endfunction
endclass

class axi_transaction #(int DW=32, int IW=4) extends uvm_sequence_item;
  `uvm_object_param_utils(axi_transaction#(DW,IW))

  rand axi_op_kind_e  kind;
  rand int unsigned   delay;
  rand bit            use_delay;

  int unsigned delay_max  = 2;
  int unsigned dist_delay = 3;

  function new(string name="axi_transaction");
    super.new(name);
  endfunction

  function int clamp(int v, int lo, int hi);
    if (v < lo) return lo;
    else if (v > hi) return hi;
    else return v;
  endfunction

  constraint c_delay_prob {
    use_delay dist {
      1 :=      clamp(dist_delay, 0, 10),
      0 := 10 - clamp(dist_delay, 0, 10)
    };
  }

  constraint c_delay {
    if (use_delay) delay inside {[1:delay_max]};
    else           delay == 1;
  }
endclass

class axi_write_transaction #(int DW=32, int IW=4) extends axi_transaction#(DW,IW);
  `uvm_object_param_utils(axi_write_transaction#(DW,IW))

  rand axi_aw_chan_tr#(DW,IW) aw;
  rand axi_w_chan_tr#(DW)  w;
       axi_b_chan_tr#(IW)  b;

  function new(string name="axi_write_transaction");
    super.new(name);
    kind = AXI_OP_WRITE;
    aw = axi_aw_chan_tr#(DW,IW)::type_id::create("aw");
    w  = axi_w_chan_tr#(DW)::type_id::create("w");
    b  = axi_b_chan_tr#(IW)::type_id::create("b");
  endfunction
endclass

class axi_read_transaction #(int DW=32, int IW=4) extends axi_transaction#(DW,IW);
  `uvm_object_param_utils(axi_read_transaction#(DW,IW))

  rand axi_ar_chan_tr#(DW,IW) ar;
       axi_r_chan_tr#(DW,IW)  r;

  function new(string name="axi_read_transaction");
    super.new(name);
    kind = AXI_OP_READ;
    ar = axi_ar_chan_tr#(DW,IW)::type_id::create("ar");
    r  = axi_r_chan_tr#(DW,IW)::type_id::create("r");
  endfunction
endclass