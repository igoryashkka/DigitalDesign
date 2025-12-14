module tb_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  logic clk = 0;
  always #5 clk = ~clk;

  logic rstn;

  dxi_if #(72) dxi_in (clk);
  dxi_if #(8)  dxi_out(clk);
  config_if    cfg_if(clk);

  dxi_top dut (
    .i_clk(clk),
    .i_rstn(rstn),
    .i_dxi_valid(dxi_in.valid),
    .i_dxi_data(dxi_in.data),
    .o_dxi_ready(dxi_in.ready),
    .i_dxi_out_ready(dxi_out.ready),
    .o_dxi_out_valid(dxi_out.valid),
    .o_master_data(dxi_out.data),
    .config_select(cfg_if.config_select)
  );

  // reset
  initial begin
    rstn = 0;
    dxi_in.valid   = 0;
    dxi_in.data    = '0;
    dxi_out.ready  = 0;
    cfg_if.config_select = 2'b11; 
    repeat (3) @(posedge clk);
    rstn = 1;
  end

  initial begin

    uvm_config_db#(virtual dxi_if#(72))::set(null, "uvm_test_top.env.in_agent",  "vif", dxi_in);
    uvm_config_db#(virtual dxi_if#(8)) ::set(null, "uvm_test_top.env.out_agent", "vif", dxi_out);
    uvm_config_db#(virtual config_if)  ::set(null, "uvm_test_top.env",           "cfg_vif", cfg_if);

    uvm_config_db#(bit)::set(null, "uvm_test_top.env.in_agent",  "is_master", 1);
    uvm_config_db#(bit)::set(null, "uvm_test_top.env.out_agent", "is_master", 0);

    run_test("random_uvm_test");
  end
endmodule
