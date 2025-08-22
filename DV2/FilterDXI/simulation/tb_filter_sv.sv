`timescale 1ns/1ps

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


  
  typedef enum {PADDING, MIRRORING, ZEROING} padding_method_e;

  function void add_addition_pixels(
      input  logic [7:0] image        [HEIGHT][WIDTH],
      output logic [7:0] extended_img [HEIGHT+2][WIDTH+2],
      input  padding_method_e method_);
    int i, j;

    
    for (i = 0; i < HEIGHT; i++)
      for (j = 0; j < WIDTH; j++)
        extended_img[i+1][j+1] = image[i][j];

    case (method_)
      PADDING: begin
        for (i = 0; i < HEIGHT; i++) begin
          extended_img[i+1][0]       = image[i][0];
          extended_img[i+1][WIDTH+1] = image[i][WIDTH-1];
        end
        for (j = 0; j < WIDTH; j++) begin
          extended_img[0][j+1]        = image[0][j];
          extended_img[HEIGHT+1][j+1] = image[HEIGHT-1][j];
        end
        extended_img[0][0]                      = image[0][0];
        extended_img[0][WIDTH+1]               = image[0][WIDTH-1];
        extended_img[HEIGHT+1][0]              = image[HEIGHT-1][0];
        extended_img[HEIGHT+1][WIDTH+1]        = image[HEIGHT-1][WIDTH-1];
      end

      MIRRORING: begin
        for (i = 0; i < HEIGHT; i++) begin
          extended_img[i+1][0]       = image[i][1];
          extended_img[i+1][WIDTH+1] = image[i][WIDTH-2];
        end
        for (j = 0; j < WIDTH; j++) begin
          extended_img[0][j+1]        = image[1][j];
          extended_img[HEIGHT+1][j+1] = image[HEIGHT-2][j];
        end
        extended_img[0][0]                      = image[1][1];
        extended_img[0][WIDTH+1]               = image[1][WIDTH-2];
        extended_img[HEIGHT+1][0]              = image[HEIGHT-2][1];
        extended_img[HEIGHT+1][WIDTH+1]        = image[HEIGHT-2][WIDTH-2];
      end

      ZEROING: begin
        for (i = 0; i < HEIGHT+2; i++) begin
          extended_img[i][0]        = 8'h00;
          extended_img[i][WIDTH+1]  = 8'h00;
        end
        for (j = 0; j < WIDTH+2; j++) begin
          extended_img[0][j]        = 8'h00;
          extended_img[HEIGHT+1][j] = 8'h00;
        end
      end
    endcase
  endfunction


  function automatic [71:0] pack_3x3(
      input logic [7:0] extended_img [HEIGHT+2][WIDTH+2],
      input int row, input int col);
    int r, c;
    reg [71:0] packed_;
    packed_ = 72'd0;
    for (r = -1; r <= 1; r++)
      for (c = -1; c <= 1; c++)
        packed_ = (packed_ << 8) | extended_img[row + r][col + c];
    return packed_;
  endfunction

  function [7:0] hex_to_byte(input [7:0] char1, input [7:0] char2);
      begin
        hex_to_byte = (char1 >= "a") ? (char1 - "a" + 10) << 4 : (char1 - "0") << 4;
        hex_to_byte |= (char2 >= "a") ? (char2 - "a" + 10) : (char2 - "0");
      end
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
class dxi_transaction #(parameter int DW = 72);
  rand logic [DW-1:0] data;
  rand int unsigned   delay;
  rand bit            use_delay;
  int unsigned        delay_max  = 2;
  int unsigned        dist_delay = 3;

  function int clamp(input int value, input int lo, input int hi);
  if (value < lo) return lo;
  else if (value > hi) return hi;
  else return value;
  endfunction

  constraint constraint_delay_prob {
    use_delay dist {1 :=      clamp(dist_delay, 0, 10), 
                    0 := 10 - clamp(dist_delay, 0, 10)};
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

  task drive(input dxi_tr_t tr);
    $display("[DRIVE] @%0t is_master=%0b | delay=%0d", $time, is_master, tr.delay);
    if (is_master) begin 
        repeat (tr.delay) @(posedge dxi_vif.clk);
        drive_mst(tr.data);
    end else begin
        repeat (tr.delay) @(posedge dxi_vif.clk);
        drive_slv();
    end
  endtask

  task drive_mst(input logic [DW-1:0] data);
    dxi_vif.data  <= data;
    dxi_vif.valid <= 1'b1;
    @(posedge dxi_vif.clk);
    while (!dxi_vif.ready) @(posedge dxi_vif.clk);
    dxi_vif.valid <= 1'b0;
  endtask

  task drive_slv();
    dxi_vif.ready <= 1'b1;
    @(posedge dxi_vif.clk);
    dxi_vif.ready <= 1'b0;
  endtask
endclass

// ------------------------------
// Scoreboard
// ------------------------------
class checker_scoreboard;


  dxi_agent #(72)      mst_ag;
  dxi_agent #(8)       slv_ag;
  virtual config_if    cfg_vif;

  mailbox mb_gold_tx;
  mailbox mb_out_tx;

  
  int unsigned n_compared;
  int unsigned n_errors;

  function new(dxi_agent #(72) mst_ag,
               dxi_agent #(8)  slv_ag,
               virtual config_if cfg_vif);
    this.mst_ag  = mst_ag;
    this.slv_ag  = slv_ag;
    this.cfg_vif = cfg_vif;
    mb_gold_tx   = new();
    mb_out_tx    = new();
  endfunction


  function automatic logic [7:0] get_gold(input logic [71:0] din,
                                          input logic [1:0]  sel);
    return apply_filter(din, sel);
  endfunction


  task automatic collect_in();
    logic [71:0] din;
    logic [1:0]  sel;
    forever begin
      mst_ag.dxi_monitor(din);           
      sel = cfg_vif.config_select;        
      mb_gold_tx.put(get_gold(din, sel)); 
    end
  endtask


  task automatic collect_out();
    logic [7:0] dout;
    forever begin
      slv_ag.dxi_monitor(dout);
      mb_out_tx.put(dout);       
    end
  endtask


  task automatic compare_streams();
    logic [7:0] gld, out;
    forever begin
      mb_gold_tx.get(gld);
      mb_out_tx.get(out);
      n_compared++;
      if (out !== gld) begin
        n_errors++;
        $display("[SCB][%0t]  MISMATCH #%0d: expected=%02x got=%02x",
               $time, n_compared, gld, out);
      end
      else begin
        $display("[SCB][%0t] MATCH #%0d: expected=%02x got=%02x",
                 $time, n_compared, gld, out);
      end
    end
  endtask

  
  task run();
    fork
      collect_in();
      collect_out();
      compare_streams();
    join_none
  endtask

endclass

class file_collector_scoreboard;
  dxi_agent #(8)      slv_ag;
  int img_width;
  int img_height;
  string file_name;
  int img_counter;

  logic [7:0] pixel_queue[$]; 

  function new(dxi_agent #(8) slv_ag,
               int            width,
               int            height,
               string         base_name);
    this.slv_ag      = slv_ag;
    this.img_width   = width;
    this.img_height  = height;
    this.file_name   = base_name;
    this.img_counter = 0;
  endfunction

  task automatic collect();
    logic [7:0] dout;
    forever begin
      slv_ag.dxi_monitor(dout);  
      pixel_queue.push_back(dout);
      if (pixel_queue.size() == img_width * img_height)
        save_image();
    end
  endtask

  task automatic save_image();
    string output_filename;
    int file_out;
    int i = 0;

    output_filename = $sformatf("output_%0d_%0d.txt", WIDTH, HEIGHT);
    file_out = $fopen(output_filename, "w");
    
    
    if (!file_out) begin
      $display("[FILE SCB] ERROR: cannot open %s", output_filename);
      return;
    end

    foreach (pixel_queue[idx]) begin
    $fwrite(file_out, "%02x", pixel_queue[idx]);
    i++;
    if ((i % WIDTH) == 0) $fwrite(file_out, "\n");
    end

    $fclose(file_out);
    $display("[FILE SCB] Saved image %s", output_filename);
    pixel_queue.delete();
  endtask

  task run();
    collect();
  endtask
endclass


class base_test;
  virtual dxi_if #(72) vif_mst;
  virtual dxi_if #(8)  vif_slv;
  virtual config_if    config_vif;

  dxi_agent #(72)      master_agent;
  dxi_agent #(8)       slave_agent;

  checker_scoreboard scb;

  function new(virtual dxi_if #(72) vif_mst,
               virtual dxi_if #(8)  vif_slv,
               virtual config_if    config_vif);
    this.vif_mst    = vif_mst;
    this.vif_slv    = vif_slv;
    this.config_vif = config_vif;
  endfunction

  virtual task build();
    config_vif.config_select <= 2'b11; // Default configuration
    master_agent = new(vif_mst, config_vif, 1);
    slave_agent  = new(vif_slv, config_vif, 0);
    scb          = new(master_agent, slave_agent, config_vif); 
  endtask

  virtual task run_testcase(); endtask

  task run();
    build();
    fork
      scb.run();
    join_none
    run_testcase();
  endtask
endclass

class file_test extends base_test;
  file_collector_scoreboard fscb;

  function new(virtual dxi_if #(72) vif_mst,
               virtual dxi_if #(8)  vif_slv,
               virtual config_if    config_vif);
    super.new(vif_mst, vif_slv, config_vif);
  endfunction

  virtual task build();
    super.build();
    fscb = new(slave_agent, WIDTH, HEIGHT, "out");
    $display("[FILE TEST] Efscb build ok");
  endtask

  task run();
    build();
    fork
      scb.run();   
      fscb.run();  
    join_none
    run_testcase();
  endtask

  virtual task run_testcase();
    int file_in;
    logic [7:0] image[HEIGHT][WIDTH];
    logic [7:0] extended[HEIGHT+2][WIDTH+2];
    reg [7:0] temp_byte;
    string input_file = "C:/Users/igor4/trash/Documents/DigitalDesign/DV2/FilterDXI/simulation/input_256_194.txt";
    string hex_str;
    file_in = $fopen(input_file, "r");
    if (!file_in) begin
      $display("[FILE TEST] ERROR: cannot open %s", input_file);
      $finish;
    end

      for (int i = 0; i < HEIGHT; i++) begin
      $fscanf(file_in, "%s", hex_str);
       for (int j = 0; j < WIDTH; j++) begin
        temp_byte = hex_to_byte(hex_str[j*2], hex_str[j*2+1]);
        image[i][j] = temp_byte;
       end
    end

    $fclose(file_in);
    add_addition_pixels(image, extended, PADDING);

    fork
    for (int r = 1; r <= HEIGHT; r++) begin
      for (int c = 1; c <= WIDTH; c++) begin
        dxi_transaction #(72) tr = new();
        tr.data = pack_3x3(extended, r, c);  
        master_agent.drive(tr);
      end
    end


      forever begin
        dxi_transaction #(8) tr_slv = new();
        assert(tr_slv.randomize());
        slave_agent.drive(tr_slv);
      end
     join_any
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
          master_agent.drive(tr_mst);
        end
      end

    
      begin : slave_loop
        forever begin 
          tr_slv = new();
          assert(tr_slv.randomize());
          repeat (tr_slv.delay) @(posedge vif_slv.clk);
          slave_agent.drive(tr_slv);
        end
      end
    join_any 
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
    localparam logic [71:0] boundary_patterns [10] = '{
    72'h00_00_00_00_00_00_00_00_00,
    72'hFF_FF_FF_FF_FF_FF_FF_FF_FF,
    72'h00_00_00_00_FF_00_00_00_00,
    72'hFF_FF_FF_FF_00_FF_FF_FF_FF,
    72'h00_00_00_FF_FF_FF_FF_FF_FF,
    72'h00_00_00_FF_FF_FF_FF_FF_FF,
    72'h00_FF_00_FF_00_FF_00_FF_00,
    72'hFF_00_FF_00_FF_00_FF_00_FF,
    72'h00_20_40_60_80_A0_C0_E0_FF,
    72'hFF_E0_C0_A0_80_60_40_20_00
  };

  logic [1:0] filters [4] = '{2'b00, 2'b01, 2'b10, 2'b11};

  task automatic set_filter(input logic [1:0] sel);
    config_vif.sel <= sel;
    @(posedge vif_mst.clk);
  endtask
  
    fork
      begin : drive_loop
       foreach (filters[f]) begin
        set_filter(filters[f]);

        for (int i = 0; i < 10; i++) begin
         tr_mst       = new();
         tr_mst.data  = boundary_patterns[i];

          @(posedge vif_mst.clk);
          master_agent.drive(tr_mst);
      end
    end
      end

      begin : slave_loop
        forever begin 
          tr_slv       = new();
          tr_slv.delay = 1;
          @(posedge vif_slv.clk);
          slave_agent.drive(tr_slv);
        end
      end
    join_any  
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
   file_test ft;
   boundary_test bt;

  initial begin
    reset_dut();

`ifdef RUN_FILE_TEST
    ft = new(dxi_in, dxi_out, config_vif);
    ft.run();
`elsif RUN_RANDOM_TEST
    rt = new(dxi_in, dxi_out, config_vif);
    rt.run();
`elsif RUN_BOUNDARY_TEST
    bt = new(dxi_in, dxi_out, config_vif);
    bt.run();
`else
    $display("[TB] ERROR: select test to run.");
`endif
  end
endmodule
