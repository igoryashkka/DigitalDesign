import uvm_pkg::*;
`include "uvm_macros.svh"
`uvm_analysis_imp_decl(_in)
`uvm_analysis_imp_decl(_out)

class dxi_scoreboard extends uvm_component;
  `uvm_component_utils(dxi_scoreboard)

  uvm_analysis_imp_in  #(dxi_transation#(72), dxi_scoreboard) in_imp;
  uvm_analysis_imp_out #(dxi_transation#(8),  dxi_scoreboard) out_imp;

  virtual config_if cfg_vif;
  virtual dxi_if #(72) rst_vif;
  typedef struct {
    logic [7:0] expected;
    int unsigned in_tr_num;
  } expected_t;

  expected_t expected_q[$];
  int unsigned in_count;
  int unsigned out_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    in_imp  = new("in_imp",  this);
    out_imp = new("out_imp", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual config_if)::get(this, "", "cfg_vif", cfg_vif)) begin
      `uvm_fatal("NO_CFG_VIF", $sformatf("No cfg_vif for %s", get_full_name()))
    end
    void'(uvm_config_db#(virtual dxi_if#(72))::get(this, "", "rst_vif", rst_vif));
  endfunction

  task run_phase(uvm_phase phase);
    if (rst_vif == null) return;

    forever begin
      @(negedge rst_vif.rstn);
      expected_q.delete();
      in_count  = 0;
      out_count = 0;
      `uvm_info("DXI_SCB", "Reset detected, clearing expected queue", UVM_LOW)
    end
  endtask

  function automatic logic [7:0] apply_filter(logic [71:0] pixels, logic [1:0] sel);
    int acc = 0;
    int norm;
    int result;
    int kernel[0:8];
    logic [7:0] px[0:8];

    for (int i = 0; i < 9; i++) begin
      px[i] = pixels[i*8 +: 8];
    end

    case (sel)
      2'b00: begin kernel = '{ 0, -1,  0,
                              -1,  4, -1,
                               0, -1,  0}; norm = 1;  end
      2'b01: begin kernel = '{-1, -1, -1,
                              -1,  8, -1,
                              -1, -1, -1}; norm = 1;  end
      2'b10: begin kernel = '{1, 2, 1,
                              2, 4, 2,
                              1, 2, 1};   norm = 16; end
      default: begin kernel = '{1, 1, 1,
                                1, 1, 1,
                                1, 1, 1}; norm = 9;  end
    endcase

    for (int i = 0; i < 9; i++)
      acc += kernel[i] * int'($unsigned(px[i]));

    result = acc / norm;
    if (result < 0)        result = 0;
    else if (result > 255) result = 255;
    return result[7:0];
  endfunction

  function void write_in(dxi_transation#(72) tr);
    logic [7:0] expected;
    expected_t exp_entry;
    if (rst_vif != null && !rst_vif.rstn) begin
      `uvm_info("DXI_SCB", "Ignoring input during reset", UVM_LOW)
      return;
    end

    if (^tr.data === 1'bX || ^cfg_vif.config_select === 1'bX) begin
        `uvm_warning("DXI_SCB", $sformatf("[%0t][IN ] Skipping input with unknowns: data=0x%0h sel=%b",
                $time, tr.data, cfg_vif.config_select))
      return;
    end

    in_count++;
    expected         = apply_filter(tr.data, cfg_vif.config_select);
    exp_entry        = '{expected: expected, in_tr_num: in_count};
    expected_q.push_back(exp_entry);
    `uvm_info("DXI_SCB", $sformatf("[%0t][IN ] tr#%0d expected=0x%0h data=0x%0h sel=%b qsize=%0d",
              $time, in_count, expected, tr.data, cfg_vif.config_select, expected_q.size()),UVM_MEDIUM)
  endfunction

  function void write_out(dxi_transation#(8) tr);
    expected_t exp_entry;

    if (rst_vif != null && !rst_vif.rstn) begin
      `uvm_info("DXI_SCB", "Ignoring output during reset", UVM_LOW)
      return;
    end

    out_count++;
    if (expected_q.size() == 0) begin
      `uvm_error("DXI_SCB",$sformatf("[%0t][OUT] tr#%0d FAIL expected=? got=0x%0h",
                $time, out_count, tr.data[7:0]))
      return;
    end

    exp_entry = expected_q.pop_front();

    if (exp_entry.expected !== tr.data[7:0]) begin
      `uvm_error("DXI_SCB",$sformatf("[DXI_SCB][%0t][OUT] tr#%0d (exp tr#%0d) FAIL expected=0x%0h got=0x%0h",
               $time, out_count, exp_entry.in_tr_num, exp_entry.expected, tr.data[7:0]));
    end else begin
      `uvm_info("DXI_SCB", $sformatf("[DXI_SCB][%0t][OUT] tr#%0d (exp tr#%0d) PASSED expected=0x%0h got=0x%0h",
               $time, out_count, exp_entry.in_tr_num, exp_entry.expected, tr.data[7:0]), UVM_MEDIUM);
    end
  endfunction
endclass
