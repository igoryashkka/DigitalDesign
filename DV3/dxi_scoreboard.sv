`uvm_analysis_imp_decl(_in)
`uvm_analysis_imp_decl(_out)

class dxi_scoreboard extends uvm_component;
  `uvm_component_utils(dxi_scoreboard)

  uvm_analysis_imp_in  #(dxi_sequence#(72), dxi_scoreboard) in_imp;
  uvm_analysis_imp_out #(dxi_sequence#(8),  dxi_scoreboard) out_imp;

  virtual config_if cfg_vif;
  virtual dxi_if #(72) rst_vif;
  logic [7:0] expected_q[$];

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
      `uvm_info("DXI_SCB", "Reset detected, clearing expected queue", UVM_LOW)
    end
  endtask

  function automatic logic [7:0] apply_filter(logic [71:0] data, logic [1:0] sel);
    int kernel   [0:8];
    int pixels   [0:8];
    int acc      = 0;
    int norm     = 1;
    int result;

    // unpack the pixel bus exactly like the DUT (bits 71:64 are pixel[0])
    for (int i = 0; i < 9; i++) begin
      pixels[i] = int'($unsigned(data[71 - i*8 -: 8]));
    end

    case (sel)
      2'b00: kernel = '{ 0, -1,  0,
                        -1,  4, -1,
                         0, -1,  0};
      2'b01: kernel = '{-1, -1, -1,
                        -1,  8, -1,
                        -1, -1, -1};
      2'b10: begin
        kernel = '{1, 2, 1,
                   2, 4, 2,
                   1, 2, 1};
        norm = 16;
      end
      default: begin
        kernel = '{1, 1, 1,
                   1, 1, 1,
                   1, 1, 1};
        norm = 9;
      end
    endcase

    for (int i = 0; i < 9; i++) begin
      acc += kernel[i] * pixels[i];
    end

    result = acc / norm;

    if (result < 0)        result = 0;
    else if (result > 255) result = 255;

    return logic'(result[7:0]);
  endfunction

  function void write_in(dxi_sequence#(72) tr);
    logic [7:0] expected;
    if (rst_vif != null && !rst_vif.rstn) begin
      `uvm_info("DXI_SCB", "Ignoring input during reset", UVM_LOW)
      return;
    end

    if (^tr.data === 1'bX || ^cfg_vif.config_select === 1'bX) begin
      `uvm_warning("DXI_SCB", $sformatf("Skipping input with unknowns: data=%0h sel=%b", tr.data, cfg_vif.config_select))
      return;
    end

    expected = apply_filter(tr.data, cfg_vif.config_select);
    expected_q.push_back(expected);
    `uvm_info("DXI_SCB", $sformatf("Captured input 0x%0h -> expected 0x%0h", tr.data, expected), UVM_LOW)
  endfunction

  function void write_out(dxi_sequence#(8) tr);
    logic [7:0] expected;

    if (rst_vif != null && !rst_vif.rstn) begin
      `uvm_info("DXI_SCB", "Ignoring output during reset", UVM_LOW)
      return;
    end

    if (expected_q.size() == 0) begin
      `uvm_error("DXI_SCB", $sformatf("Unexpected output 0x%0h with no predicted data", tr.data[7:0]))
      return;
    end

    expected = expected_q.pop_front();

    if (expected !== tr.data[7:0]) begin
      `uvm_error("DXI_SCB", $sformatf("Mismatch: expected 0x%0h, got 0x%0h", expected, tr.data[7:0]))
    end else begin
      `uvm_info("DXI_SCB", $sformatf("Output matches expected 0x%0h", expected), UVM_LOW)
    end
  endfunction
endclass
