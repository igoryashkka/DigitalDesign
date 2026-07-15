class dxi_transation #(int DW=72) extends uvm_sequence_item; 
  `uvm_object_param_utils(dxi_transation#(DW))

  rand logic [DW-1:0] data;
  rand int unsigned   delay;
  rand bit            use_delay;

  int unsigned delay_max  = 2;
  int unsigned dist_delay = 3;

  function new(string name="dxi_transation");
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

  constraint c_delay  {
    if (use_delay) delay inside {[1:delay_max]};
    else           delay == 1;
  }

//   function string convert2string();
//     return $sformatf("data=%0h delay=%0d use_delay=%0b", data, delay, use_delay);
//   endfunction
endclass
