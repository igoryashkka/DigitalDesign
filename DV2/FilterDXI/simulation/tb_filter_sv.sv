`timescale 1ns/1ps

mailbox #(logic [71:0]) input_data_q = new();
mailbox #(logic [1:0])  input_cfg_q  = new();
mailbox #(logic [7:0])  output_data_q = new();

interface dxi_mst_if(input logic clk);
  logic valid;
  logic ready;
  logic [71:0] data;
endinterface

interface dxi_slv_if(input logic clk);
  logic valid;
  logic ready;
  logic [7:0] data;
endinterface

module tb_filter_sv;

  typedef logic [7:0] pixel_t;
  typedef pixel_t pixel_window_t[0:8];
  logic [7:0] processed_pixel;

  logic clk = 1;
  logic rstn = 0;
  localparam clk_period = 10;
  always #(clk_period / 2) clk = ~clk;

  dxi_mst_if dxi_mst(clk);
  dxi_slv_if dxi_slv(clk);
  logic [1:0] config_select;

  dxi_top dut (
    .i_clk(clk),
    .i_rstn(rstn),
    .i_dxi_valid(dxi_mst.valid),
    .i_dxi_data(dxi_mst.data),
    .o_dxi_ready(dxi_mst.ready),
    .i_dxi_out_ready(dxi_slv.ready),
    .o_dxi_out_valid(dxi_slv.valid),
    .o_master_data(dxi_slv.data),
    .config_select(config_select)
  );

  localparam int lap1[0:8]  = '{0, -1, 0, -1, 4, -1, 0, -1, 0};
  localparam int lap2[0:8]  = '{-1, -1, -1, -1, 8, -1, -1, -1, -1};
  localparam int gauss[0:8] = '{1, 2, 1, 2, 4, 2, 1, 2, 1};
  localparam int avg[0:8]   = '{1, 1, 1, 1, 1, 1, 1, 1, 1};

  function automatic logic [7:0] apply_filter(input logic [71:0] pixels, input logic [1:0] sel);
    int acc = 0, norm, result;
    int kernel[0:8];
    logic [7:0] px[0:8];
    for (int i = 0; i < 9; i++)
      px[i] = pixels[i*8 +: 8];
    case (sel)
      2'b00: begin kernel = lap1; norm = 1; end
      2'b01: begin kernel = lap2; norm = 1; end
      2'b10: begin kernel = gauss; norm = 16; end
      default: begin kernel = avg; norm = 9; end
    endcase
    for (int i = 0; i < 9; i++)
      acc += kernel[i] * px[i];
    result = acc / norm;
    if (result < 0) result = 0;
    else if (result > 255) result = 255;
    return result[7:0];
  endfunction

// [NOTE] test data is used only for master drv, good todo randomize this data.

logic [71:0] test_inputs[8] = '{
  72'h5F5F5F5F5F5F5F5F5F,
  72'hfff1f2f3f4f5f6f7f8,
  72'hFFFFFFFFFFFFFFFFFF,
  72'hA5A5A5A5A5A5A5A5A5,
  72'hA5A5A5A5A5A5A5A5A5,
  72'hFFFFFFFFFFFFFFFFFF,
  72'hfff1f2f3f4f5f6f7f8,
  72'h5F5F5F5F5F5F5F5F5F
};

logic [1:0] test_cfgs[8] = '{
  2'b00,
  2'b01,
  2'b10,
  2'b11,
  2'b11,
  2'b10,
  2'b11,
  2'b10
};


  task automatic reset_dut();
    rstn = 0;
    dxi_mst.valid = 0;
    dxi_mst.data = 0;
    config_select = 0;
    dxi_slv.ready = 1;
    processed_pixel = 0;
    repeat (3) @(posedge clk);
    rstn = 1;
    @(posedge clk);
  endtask

  // [NOTE] [config_select] , Maybe config_select is not needed here ... will think later 

  task automatic send_once(input [71:0] data, input [1:0] cfg);
    dxi_mst.data <= data;
    config_select <= cfg;
    dxi_mst.valid <= 1;
    @(posedge clk);
    while (!dxi_mst.ready)
      @(posedge clk);
    dxi_mst.valid <= 0;
  endtask 

  // [NOTE] testcase_functional() AND testcase_clock_by_clock() use the same task send_once for re-use style
  // [WARN]  They exist exist at the same time for handle different test cases 
  //          1st - simple transaction where [dxi_mst.valid]  will fall at 0 to indicate just over-clock transaction
  //          2nd - once send , but clock-by-clcok transaction where [dxi_mst.valid] will NOT fall to 0
  //
  // [TODO]   Adding arg [falling_flag] signal and asign :  dxi_mst.valid <= falling_flag;
  // [NOTE]   Syncronization fails for now if call it with diff falling_flag value , but RTL can handle it at all.

  task automatic testcase_functional();
    for (int i = 0; i < 4; i++)
      send_once(test_inputs[i], test_cfgs[i]);
  endtask

  task automatic testcase_clock_by_clock();
    for (int i = 4; i < 8; i++)
      send_once(test_inputs[i], test_cfgs[i]);
  endtask

  task automatic monitor_input();
    forever begin
      @(posedge clk);
      if (dxi_mst.valid && dxi_mst.ready) begin
         input_data_q.put(dxi_mst.data);
         input_cfg_q.put(config_select);
        $display("[MONITOR-IN] @%0t -> IN  : data = %h | config = %0b", $time, dxi_mst.data, config_select);
      end
    end
  endtask

  task automatic monitor_output();
    forever begin
      @(posedge clk);
      if (dxi_slv.valid && dxi_slv.ready) begin
         output_data_q.put(dxi_slv.data);
        $display("[MONITOR-OUT] @%0t -> OUT : data = %h", $time, dxi_slv.data);
      end
    end
  endtask

// [NOTE] Handle drv , there are some ideas... 

task automatic drive_slv();
  int count = 0;
  // forever begin
 // while (count < 8) begin
    dxi_slv.ready <= 1;
    do @(posedge clk); while (!dxi_slv.valid);
    dxi_slv.ready <= 0;
  //  count++;
  //end
endtask

// [NOTE] i = 0 , global idk, it coudn`t compile. todo move to task 
int i = 0;
logic [7:0] expected;

task automatic checker_task();
  logic [71:0] din;
  logic [1:0] cfg;
  logic [7:0] dout;
  int i = 0;

  forever begin
    input_data_q.get(din);
    input_cfg_q.get(cfg);
    output_data_q.get(dout);

    expected = apply_filter(din, cfg);
    $display("[CHECKER] @%0t -> CHECK [%0d]: Expected = %02x | Got = %02x %s", $time, i, expected, dout, (dout === expected) ? "[OK]" : "[FAIL]");
    i++;
    if (i == 8) disable checker_task;
  end
endtask


  initial begin
    fork
      monitor_input();
      monitor_output();
      checker_task();
       begin 
       for (int i = 0; i < 8; i++) begin 
        static  int num_cycles_slv = $urandom_range(2, 3);
          repeat (num_cycles_slv) @(posedge clk);
          drive_slv();
        end
 end
      begin
        reset_dut();
        $display("testcase_functional()");
        testcase_functional();
        $display("testcase_clock_by_clock()");
        testcase_clock_by_clock();
        #50;
        $display("Simulation complete.");
        $finish;
      end

    join_any
  end

endmodule
   
