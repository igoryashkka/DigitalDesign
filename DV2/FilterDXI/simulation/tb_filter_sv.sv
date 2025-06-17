`timescale 1ns/1ps

module tb_filter_sv;

  typedef logic [7:0] pixel_t;
  typedef pixel_t pixel_window_t[0:8];

  logic clk = 0;
  logic rstn = 0;
  localparam clk_period = 10;
  always #(clk_period / 2) clk = ~clk;


  interface dxi_if(input logic clk);
    logic        valid;
    logic [71:0] data;
    logic        ready;

    logic        out_valid;
    logic        out_ready;
    logic [7:0]  master_data;

    logic [1:0]  config_select;
  endinterface

  dxi_if vif(clk);

  dxi_top dut (
    .i_clk(clk),
    .i_rstn(rstn),
    .i_dxi_valid(vif.valid),
    .i_dxi_data(vif.data),
    .o_dxi_ready(vif.ready),
    .i_dxi_out_ready(vif.out_ready),
    .o_dxi_out_valid(vif.out_valid),
    .o_master_data(vif.master_data),
    .config_select(vif.config_select)
  );


  logic [71:0] test_inputs[4] = '{
    72'h000102030405060708,
    72'h080706050403020100,
    72'hFFFFFFFFFFFFFFFFFF,
    72'hA5A5A5A5A5A5A5A5A5
  };

  logic [1:0] test_cfgs[4] = '{2'b00, 2'b01, 2'b10, 2'b11};
  logic [7:0] expected_outputs[4] = '{8'h00, 8'h00, 8'hFF, 8'hA5};


  task automatic reset_dut();
    rstn = 0;
    vif.valid = 0;
    vif.data = 0;
    vif.config_select = 0;
    vif.out_ready = 1;
    repeat (3) @(posedge clk);
    rstn = 1;
    @(posedge clk);
  endtask

  task automatic send_once(input [71:0] data, input [1:0] cfg);
    @(posedge clk);
    vif.data = data;
    vif.config_select = cfg;
    vif.valid = 1;
    @(posedge clk);
    while (!vif.ready)
      @(posedge clk);
    vif.valid = 0;
  endtask

  task automatic send_clock_by_clock(input logic [71:0] data_array[], input logic [1:0] cfg_array[]);
    vif.valid = 1;
    for (int i = 0; i < data_array.size(); i++) begin
      @(posedge clk);
      vif.data = data_array[i];
      vif.config_select = cfg_array[i];
      while (!vif.ready)
        @(posedge clk);
    end
    @(posedge clk);
    vif.valid = 0;
  endtask



  task automatic testcase_functional();
    for (int i = 0; i < 4; i++) begin
      send_once(test_inputs[i], test_cfgs[i]);
    end
  endtask

  task automatic testcase_clock_by_clock();
    logic [71:0] data_seq[4] = '{test_inputs[3], test_inputs[2], test_inputs[1], test_inputs[0]};
    logic [1:0]  cfg_seq[4]  = '{test_cfgs[3], test_cfgs[2], test_cfgs[3], test_cfgs[2]};
    send_clock_by_clock(data_seq, cfg_seq);
  endtask

  initial begin
    reset_dut();
    $display("Running functional tests...");
    testcase_functional();
    repeat (3) @(posedge clk);
    $display("Running clock-by-clock transaction test...");
    testcase_clock_by_clock();
    #50;
    $display("Simulation complete.");
    $finish;
  end
endmodule
