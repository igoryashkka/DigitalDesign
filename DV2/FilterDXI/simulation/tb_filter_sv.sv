`timescale 1ns/1ps
`define USE_RANDOM_DATA 1


package tb_cfg;
  parameter int WIDTH  = 256;
  parameter int HEIGHT = 194;
  localparam int NUM_TEST_VECTORS = WIDTH * HEIGHT;

  localparam int lap1 [0:8]  = '{0, -1, 0, -1, 4, -1, 0, -1, 0};
  localparam int lap2 [0:8]  = '{-1, -1, -1, -1, 8, -1, -1, -1, -1};
  localparam int gauss[0:8]  = '{1, 2, 1, 2, 4, 2, 1, 2, 1};
  localparam int avg  [0:8]  = '{1, 1, 1, 1, 1, 1, 1, 1, 1};

  function automatic logic [7:0] apply_filter(input logic [71:0] pixels, input logic [1:0] sel);
    int acc = 0, norm, result;
    int kernel[0:8];
    logic [7:0] px[0:8];
    for (int i = 0; i < 9; i++)
      px[i] = pixels[i*8 +: 8];

    case (sel)
      2'b00: begin kernel = lap1;  norm = 1;  end
      2'b01: begin kernel = lap2;  norm = 1;  end
      2'b10: begin kernel = gauss; norm = 16; end
      default: begin kernel = avg; norm = 9;  end
    endcase

    for (int i = 0; i < 9; i++)
      acc += kernel[i] * px[i];

    result = acc / norm;
    if (result < 0)       result = 0;
    else if (result > 255) result = 255;
    return result[7:0];
  endfunction
endpackage : tb_cfg

import tb_cfg::*;

// ------------------------------
// Interfaces
// ------------------------------
interface dxi_if #(parameter WIDTH = 72)(input logic clk);
  logic valid;
  logic ready;
  logic [WIDTH-1:0] data;
endinterface

interface config_if(input logic clk);
  logic [1:0] config_select;
endinterface

// ------------------------------
// Transactions
// ------------------------------
class config_transaction;
  rand bit [1:0] config_val;
endclass

class dxi_transaction #(parameter int DW = 72);
  rand logic [DW-1:0] data;
  rand int unsigned   delay;
  rand bit            use_delay;
  int unsigned        delay_max  = 2;
  int unsigned        dist_delay = 3;

  constraint constraint_delay_prob {
    use_delay dist {1 := dist_delay, 0 := 10 - dist_delay};
  }
  constraint constraint_delay {
    if (use_delay) delay inside {[1:delay_max]};
    else           delay == 1;
  }
endclass

// ------------------------------
// Agent
// ------------------------------
class dxi_agent #(parameter int DW = 72);
  typedef dxi_transaction#(DW) dxi_tr_t;

  virtual dxi_if #(DW) dxi_vif;
  virtual config_if    config_vif;
  bit is_master;

  function new(virtual dxi_if #(DW) vif,
               virtual config_if     cfg_vif,
               bit                   is_master_mode);
    dxi_vif   = vif;
    config_vif = cfg_vif;
    is_master = is_master_mode;
  endfunction

  task automatic dxi_monitor(output logic [DW-1:0] data);
    forever begin
      @(posedge dxi_vif.clk);
      if (dxi_vif.valid && dxi_vif.ready) begin
        data = dxi_vif.data;
        if (DW == 72)
          $display("[MONITOR-IN ] @%0t IN  : data=%h | cfg=%0b", $time, data, config_vif.config_select);
        else
          $display("[MONITOR-OUT] @%0t OUT : data=%h", $time, data[7:0]);
        break;
      end
    end
  endtask

  task drive(input dxi_tr_t tr, input config_transaction cfg);
    $display("[DRIVE] @%0t is_master=%0b | delay=%0d", $time, is_master, tr.delay);
    if (is_master) drive_mst(tr.data, cfg);
    else           drive_slv();
  endtask

  task drive_mst(input logic [DW-1:0] data, input config_transaction cfg);
    config_vif.config_select <= cfg.config_val;
    dxi_vif.data  <= data;
    dxi_vif.valid <= 1'b1;
    @(posedge dxi_vif.clk);
    while (!dxi_vif.ready) @(posedge dxi_vif.clk);
    dxi_vif.valid <= 1'b0;
  endtask

  task drive_slv();
    dxi_vif.ready <= 1'b1;
    do @(posedge dxi_vif.clk); while (!dxi_vif.valid);
    dxi_vif.ready <= 1'b0;
  endtask
endclass


class base_test;
  virtual dxi_if #(72) vif_mst;
  virtual dxi_if #(8)  vif_slv;
  virtual config_if    config_vif;

  dxi_agent #(72)      master_agent;
  dxi_agent #(8)       slave_agent;
  config_transaction   cfg_tr;

  function new(virtual dxi_if #(72) vif_mst,
               virtual dxi_if #(8)  vif_slv,
               virtual config_if    config_vif);
    this.vif_mst    = vif_mst;
    this.vif_slv    = vif_slv;
    this.config_vif = config_vif;
  endfunction

  virtual task build();
    master_agent = new(vif_mst, config_vif, 1);
    slave_agent  = new(vif_slv, config_vif, 0);
    cfg_tr       = new();
  endtask

  virtual task run_testcase(); endtask

  task run();
    build();
    run_testcase();
  endtask
endclass

class random_test extends base_test;
  dxi_transaction #(72) tr_mst;
  dxi_transaction #(8)  tr_slv;
  logic [7:0]           expected;

   function new(virtual dxi_if #(72) vif_mst,
               virtual dxi_if #(8)  vif_slv,
               virtual config_if    config_vif);
    super.new(vif_mst, vif_slv, config_vif ); 
  endfunction


  virtual task run_testcase();
    logic [7:0] processed_image[];
    processed_image = new[NUM_TEST_VECTORS];

    fork

      begin : drive_loop
        for (int i = 0; i < NUM_TEST_VECTORS; i++) begin
          tr_mst = new();
          assert(tr_mst.randomize());
          cfg_tr.config_val = 2'b01;
          repeat (tr_mst.delay) @(posedge vif_mst.clk);
          master_agent.drive(tr_mst, cfg_tr);
        end
      end


      begin : slave_loop
        for (int j = 0; j < NUM_TEST_VECTORS; j++) begin
          tr_slv = new();
          assert(tr_slv.randomize());
          repeat (tr_slv.delay) @(posedge vif_slv.clk);
          slave_agent.drive(tr_slv, null);
        end
      end

  
      begin : checker_loop
        logic [71:0] din;
        logic [7:0]  dout;
        for (int i = 0; i < NUM_TEST_VECTORS; i++) begin
          master_agent.dxi_monitor(din);
          slave_agent.dxi_monitor(dout);
          expected = apply_filter(din, config_vif.config_select);
          processed_image[i] = dout;
          //$fwrite(file_out, "%02x", processed_image[i]);
          //if ((i + 1) % WIDTH == 0) $fwrite(file_out, "\n");
          $display("[CHECK] @%0t [%0d] exp=%02x got=%02x %s",
                   $time, i, expected, dout, (dout === expected) ? "[OK]" : "[FAIL]");
        end
      end
    join
  endtask
endclass


class boundary_test extends base_test;
  dxi_transaction #(72) tr_mst;
  dxi_transaction #(8)  tr_slv;

  function new(virtual dxi_if #(72) vif_mst,
               virtual dxi_if #(8)  vif_slv,
               virtual config_if    config_vif);
    super.new(vif_mst, vif_slv, config_vif);
  endfunction
              
  virtual task run_testcase();
    logic [71:0] boundary_patterns[3] = '{72'h0, 72'hFFFF_FFFF_FFFF, 72'hAAAA_AAAA_AAAA};
    logic [7:0] expected;
    fork
      begin : drive_loop
        for (int i = 0; i < 3; i++) begin
          tr_mst        = new();
          tr_mst.data   = boundary_patterns[i];
          tr_mst.delay  = 1;
          cfg_tr.config_val = i[1:0];
          @(posedge vif_mst.clk);
          master_agent.drive(tr_mst, cfg_tr);
        end
      end

      begin : slave_loop
        for (int j = 0; j < 3; j++) begin
          tr_slv       = new();
          tr_slv.delay = 1;
          @(posedge vif_slv.clk);
          slave_agent.drive(tr_slv, null);
        end
      end

      begin : checker_loop
        logic [71:0] din;
        logic [7:0]  dout;
        for (int i = 0; i < 3; i++) begin
          master_agent.dxi_monitor(din);
          slave_agent.dxi_monitor(dout);
          expected = apply_filter(din, config_vif.config_select);
          $display("[BOUNDARY] [%0d] exp=%0h got=%0h %s",i, expected, dout, (expected === dout) ? "[OK]" : "[FAIL]");
        end
      end
    join
  endtask
endclass


module tb_filter_sv;
 
  logic clk = 1'b1;
  logic rstn = 1'b0;
  localparam int clk_period = 10;
  always #(clk_period/2) clk = ~clk;


  dxi_if  #(72) dxi_in (clk);
  dxi_if  #(8)  dxi_out(clk);
  config_if     config_vif(clk);


  dxi_top dut (
    .i_clk           (clk),
    .i_rstn          (rstn),
    .i_dxi_valid     (dxi_in.valid),
    .i_dxi_data      (dxi_in.data),
    .o_dxi_ready     (dxi_in.ready),
    .i_dxi_out_ready (dxi_out.ready),
    .o_dxi_out_valid (dxi_out.valid),
    .o_master_data   (dxi_out.data),
    .config_select   (config_vif.config_select)
  );

  task automatic reset_dut();
    rstn = 0;
    @(posedge clk);
    rstn = 1;
    @(posedge clk);
  endtask

   random_test rt;

  initial begin
    reset_dut();

    rt = new(dxi_in, dxi_out, config_vif);
    rt.run(); 
  end
endmodule
