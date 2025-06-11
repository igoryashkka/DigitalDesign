`timescale 1ns/1ps

module tb_filter_sv;
  typedef logic [7:0] pixel_t;
  typedef pixel_t pixel_window_t[0:8];

  logic clk = 0;
  logic rstn = 0;

  logic        i_dxi_valid;
  logic [71:0] i_dxi_data;
  logic        o_dxi_ready;
  logic        i_dxi_out_ready = 1;
  logic        o_dxi_out_valid;
  logic [7:0]  o_master_data;
  logic [1:0]  config_select;

  localparam clk_period = 10;
  always #(clk_period / 2) clk = ~clk;

  dxi_top uut (
    .i_clk(clk),
    .i_rstn(rstn),
    .i_dxi_valid(i_dxi_valid),
    .i_dxi_data(i_dxi_data),
    .o_dxi_ready(o_dxi_ready),
    .i_dxi_out_ready(i_dxi_out_ready),
    .o_dxi_out_valid(o_dxi_out_valid),
    .o_master_data(o_master_data),
    .config_select(config_select)
  );


  task automatic reset_dut();
    rstn = 0;
    repeat (3) @(posedge clk);
    rstn = 1;
    @(posedge clk);
  endtask

  task automatic send_window(input [71:0] data, input [1:0] cfg);
    wait(o_dxi_ready);
    @(posedge clk);
    i_dxi_data = data;
    config_select = cfg;
    i_dxi_valid = 1;
    @(posedge clk);
    i_dxi_valid = 0;
  endtask

  task automatic wait_and_check_output(input [7:0] expected);
    wait(o_dxi_out_valid);
    @(posedge clk);
    if (o_master_data !== expected)
      $fatal(1, " [Fail] Expected %0h, got %0h", expected, o_master_data);
    else
      $display(" [Pass] Output = %0h", o_master_data);
  endtask


  task automatic testcase_functional();
    logic [71:0] test_inputs[4] = '{
      72'h000102030405060708,
      72'h080706050403020100,
      72'hFFFFFFFFFFFFFFFFFF,
      72'hA5A5A5A5A5A5A5A5A5
    };
    logic [1:0] test_cfgs[4] = '{2'b00, 2'b01, 2'b10, 2'b11};
    logic [7:0] expected_outputs[4] = '{8'h00, 8'h00, 8'hFF, 8'hA5};

    for (int i = 0; i < 4; i++) begin
      send_window(test_inputs[i], test_cfgs[i]);
      wait_and_check_output(expected_outputs[i]);
    end
  endtask

  //task automatic testcase_image_process();
  // $display("[TODO] Implement reading/image-processing.");
  //endtask


  initial begin
    i_dxi_valid = 0;
    i_dxi_data = 0;
    config_select = 0;

    reset_dut();
    testcase_functional();
    testcase_image_process();

    #50;
    $display("Simulation complete.");
    $finish;
  end
endmodule
