`timescale 1ns/1ps
`define USE_RANDOM_DATA 1

interface dxi_if #(parameter WIDTH = 72)(input logic clk);
  logic valid;
  logic ready;
  logic [WIDTH-1:0] data;
endinterface

interface config_if(input logic clk);
  logic [1:0] config_select;
endinterface

class config_transaction;
  rand bit [1:0] config_val;
endclass

class dxi_transaction #(parameter int DW = 72);
  rand logic [DW-1:0] data;
  rand int unsigned delay;
  rand bit use_delay;
  int unsigned delay_max = 2;
  int unsigned dist_delay = 3;

  constraint constraint_delay_prob {
    use_delay dist {1 := dist_delay, 0 := 10 - dist_delay};
  }
  constraint constraint_delay {
    if (use_delay)
      delay inside {[1:delay_max]};
    else
      delay == 1;
  }
endclass

class dxi_agent #(parameter int DW = 72);

  virtual dxi_if #(DW) dxi_vif;
  virtual config_if     config_vif;
  bit is_master;

  function new(
    virtual dxi_if #(DW) vif,
    virtual config_if cfg_vif,
    bit is_master_mode
  );
    dxi_vif = vif;
    config_vif = cfg_vif;
    is_master = is_master_mode;
  endfunction

  task automatic dxi_monitor(output logic [DW-1:0] data);
    forever begin
      @(posedge dxi_vif.clk);
      if (dxi_vif.valid && dxi_vif.ready) begin
        data = dxi_vif.data;
        if (DW == 72)
          $display("[MONITOR-IN] @%0t -> IN  : data = %h | config = %0b", $time, data, config_vif.config_select);
        else
          $display("[MONITOR-OUT] @%0t -> OUT : data = %h", $time, data[7:0]);
        break;
      end
    end
  endtask
//$display("[CHECKER] PASSED:time=%0t, current data - %0h, expected data - %0h", $time, data_o, expected_result);
  task drive(input dxi_transaction tr, input config_transaction cfg);
    $display("[DRIVE]time=%0t is_master = %0b | delay = %0d",$time, is_master, tr.delay);
    if (is_master)
      drive_mst(tr.data, cfg);
    else
      drive_slv();
  endtask

  task drive_mst(input logic [DW-1:0] data, input config_transaction cfg);
    dxi_vif.data <= data;
    //config_vif.config_select <= cfg.config_val;
    dxi_vif.valid <= 1;
    @(posedge dxi_vif.clk);
    while (!dxi_vif.ready)
      @(posedge dxi_vif.clk);
    dxi_vif.valid <= 0;
  endtask

  task drive_slv();
    dxi_vif.ready <= 1;
    do @(posedge dxi_vif.clk); while (!dxi_vif.valid);
    dxi_vif.ready <= 0;
  endtask

endclass

module tb_filter_sv;

  parameter int WIDTH = 256;
  parameter int HEIGHT = 194;
  localparam int NUM_TEST_VECTORS = ((HEIGHT)*(WIDTH));

  logic [7:0] extended_image[HEIGHT+2][WIDTH+2];
  logic [71:0] test_inputs_image [(HEIGHT)*(WIDTH)-1:0];

  int file_in, file_out;

  logic clk = 1;
  logic rstn = 0;
  localparam clk_period = 10;
  always #(clk_period / 2) clk = ~clk;

  dxi_if #(72) dxi_in(clk);
  dxi_if #(8)  dxi_out(clk);
  config_if    config_vif(clk);

  dxi_top dut (
    .i_clk(clk),
    .i_rstn(rstn),
    .i_dxi_valid(dxi_in.valid),
    .i_dxi_data(dxi_in.data),
    .o_dxi_ready(dxi_in.ready),
    .i_dxi_out_ready(dxi_out.ready),
    .o_dxi_out_valid(dxi_out.valid),
    .o_master_data(dxi_out.data),
    .config_select(config_vif.config_select)
  );

  task automatic reset_dut();
    rstn = 0;
    @(posedge clk);
    rstn = 1;
    @(posedge clk);
  endtask


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


  logic [7:0] expected;

  dxi_agent #(72) master_agent;
  dxi_agent #(8)  slave_agent;
  dxi_transaction tr_mst;
  config_transaction cfg_tr;
  config_transaction cfg_tr_;
  dxi_transaction tr_slv;

  initial begin
    master_agent = new(dxi_in, config_vif, 1);
    slave_agent  = new(dxi_out, config_vif, 0);



    fork
      reset_dut();

      begin : drive_loop
        for (int i = 0; i < NUM_TEST_VECTORS; i++) begin
          tr_mst = new();
          cfg_tr = new();
          assert(tr_mst.randomize());
          cfg_tr.config_val = 2'b01;
          repeat (tr_mst.delay) @(posedge clk);
          master_agent.drive(tr_mst, cfg_tr);
        end
      end

      begin : slave_loop
        for (int j = 0; j < NUM_TEST_VECTORS; j++) begin
          tr_slv = new();
          //cfg_tr_ = new();
          assert(tr_slv.randomize());
          repeat (tr_slv.delay) @(posedge clk);
          slave_agent.drive(tr_slv, null);
        end
      end

      begin : checker_loop
        automatic int i = 0;
        reg [7:0] processed_image [0:WIDTH*HEIGHT-1];
        logic [71:0] din;
        logic [7:0] dout;
        forever begin
          master_agent.dxi_monitor(din);
          slave_agent.dxi_monitor(dout);
          expected = apply_filter(din, config_vif.config_select);
          processed_image[i] = dout;
          $fwrite(file_out, "%02x", processed_image[i]);
          if ((i + 1) % WIDTH == 0) $fwrite(file_out, "\n");
          $display("[CHECKER] @%0t -> CHECK [%0d]: Expected = %02x | Got = %02x %s", $time, i, expected, dout, (dout === expected) ? "[OK]" : "[FAIL]");
          i++;
        end
      end
    join
  end

endmodule
