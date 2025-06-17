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

  localparam int lap1 [0:8]  = '{0, -1, 0, -1, 4, -1, 0, -1, 0};
  localparam int lap2 [0:8]  = '{-1, -1, -1, -1, 8, -1, -1, -1, -1};
  localparam int gauss[0:8]  = '{1, 2, 1, 2, 4, 2, 1, 2, 1};
  localparam int avg  [0:8]  = '{1, 1, 1, 1, 1, 1, 1, 1, 1};

  function automatic logic [7:0] apply_filter(input logic [71:0] pixels, input logic [1:0] sel);
    int acc = 0;
    int norm;
    int result;
    int kernel[0:8];
    logic [7:0] px[0:8];
    for (int i = 0; i < 9; i++)
      px[i] = pixels[i*8 +: 8];
    case (sel)
      2'b00: begin kernel = lap1;  norm = 1; end
      2'b01: begin kernel = lap2;  norm = 1; end
      2'b10: begin kernel = gauss; norm = 16; end
      default: begin kernel = avg; norm = 9; end
    endcase
    for (int i = 0; i < 9; i++)
      acc += kernel[i] * px[i];
    result = acc / norm;
    if (result < 0) result = 0;
    else if (result > 255) result = 255;
    return logic'(result[7:0]);
  endfunction

  logic [71:0] test_inputs[4] = '{
    72'h5F5F5F5F5F5F5F5F5F,
    72'hfff1f2f3f4f5f6f7f8,
    72'hFFFFFFFFFFFFFFFFFF,
    72'hA5A5A5A5A5A5A5A5A5
  };

  logic [1:0] test_cfgs[4] = '{2'b00, 2'b01, 2'b10, 2'b11};
  logic [7:0] expected_outputs[4];

  initial begin
    for (int i = 0; i < 4; i++)
      expected_outputs[i] = apply_filter(test_inputs[i], test_cfgs[i]);
  end

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
    $display("testcase_functional()");
    testcase_functional();
    repeat (3) @(posedge clk);
    $display("testcase_clock_by_clock()");
    testcase_clock_by_clock();
    #50;
    $display("Simulation complete.");
    $finish;
  end
endmodule
