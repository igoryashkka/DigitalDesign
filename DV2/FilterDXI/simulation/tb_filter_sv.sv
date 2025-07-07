`timescale 1ns/1ps
`define USE_RANDOM_DATA 0  // 0 - use image data; 1 - use random data


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


  /*  Parameters for image simulation */
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

typedef enum {PADDING, MIRRORING, ZEROING} padding_method_e;
  
function void add_addition_pixels(
    input  logic [7:0] image        [HEIGHT][WIDTH],
    output logic [7:0] extended_img [HEIGHT+2][WIDTH+2],
    input padding_method_e method_);
    int i, j;
    begin

        for (i = 0; i < HEIGHT; i++) begin
            for (j = 0; j < WIDTH; j++) begin
                extended_img[i+1][j+1] = image[i][j];
            end
        end

   case (method_)
     PADDING:begin
        for (i = 0; i < HEIGHT; i++) begin
            extended_img[i+1][0]       = image[i][0];
            extended_img[i+1][WIDTH+1] = image[i][WIDTH-1];
        end
        for (j = 0; j < WIDTH; j++) begin
            extended_img[0][j+1]       = image[0][j];
            extended_img[HEIGHT+1][j+1]= image[HEIGHT-1][j];
        end
        extended_img[0][0]                     = image[0][0];
        extended_img[0][WIDTH+1]              = image[0][WIDTH-1];
        extended_img[HEIGHT+1][0]             = image[HEIGHT-1][0];
        extended_img[HEIGHT+1][WIDTH+1]       = image[HEIGHT-1][WIDTH-1];

         end 
     MIRRORING:begin
         for (i = 0; i < HEIGHT; i++) begin
            extended_img[i+1][0]       = image[i][1];
            extended_img[i+1][WIDTH+1] = image[i][WIDTH-2];
        end
        for (j = 0; j < WIDTH; j++) begin
            extended_img[0][j+1]       = image[1][j];
            extended_img[HEIGHT+1][j+1]= image[HEIGHT-2][j];
        end

        extended_img[0][0]                     = image[1][1];
        extended_img[0][WIDTH+1]              = image[1][WIDTH-2];
        extended_img[HEIGHT+1][0]             = image[HEIGHT-2][1];
        extended_img[HEIGHT+1][WIDTH+1]       = image[HEIGHT-2][WIDTH-2]; 
        end

     ZEROING: begin
        for (i = 0; i < HEIGHT+2; i++) begin
            extended_img[i][0]       = 8'h00;
            extended_img[i][WIDTH+1] = 8'h00;
        end        
        for (j = 0; j < WIDTH+2; j++) begin
            extended_img[0][j]       = 8'h00;
            extended_img[HEIGHT+1][j]= 8'h00;
        end
        end
   endcase

     
    end
endfunction


function automatic [71:0] pack_3x3(input int row, input int col);
    int r, c;
    reg [71:0] packed_;
    begin
        packed_ = 72'd0;
        for (r = -1; r <= 1; r++) begin
            for (c = -1; c <= 1; c++) begin
                packed_ = (packed_ << 8) | extended_image[row + r][col + c];
            end
        end
        return packed_;
    end
endfunction


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



  task automatic reset_dut();
    rstn = 0;
    dxi_mst.valid = 0;
    dxi_mst.data = 0;
    config_select = 0;
    dxi_slv.ready = 1;
    @(posedge clk);
    rstn = 1;
    @(posedge clk);
  endtask

  task automatic drvie_mst(input [71:0] data, input [1:0] cfg);
    dxi_mst.data <= data;
    config_select <= cfg;
    dxi_mst.valid <= 1;
    @(posedge clk);
    while (!dxi_mst.ready)
      @(posedge clk);
    dxi_mst.valid <= 0;
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



task automatic drive_slv();
    dxi_slv.ready <= 1;
    do @(posedge clk); while (!dxi_slv.valid);
    dxi_slv.ready <= 0;
endtask



    
  function [7:0] hex_to_byte(input [7:0] char1, input [7:0] char2);
      begin
        hex_to_byte = (char1 >= "a") ? (char1 - "a" + 10) << 4 : (char1 - "0") << 4;
        hex_to_byte |= (char2 >= "a") ? (char2 - "a" + 10) : (char2 - "0");
      end
  endfunction

initial begin
  logic [7:0] image_2d [HEIGHT][WIDTH];
  reg [7:0] temp_byte;
  int io, j;
  string hex_str, output_filename;
  output_filename = $sformatf("output_%0d_%0d.txt", WIDTH, HEIGHT);

`ifdef USE_RANDOM_DATA
  for (io = 0; io < HEIGHT; io++) begin
    for (j = 0; j < WIDTH; j++) begin
      image_2d[io][j] = $urandom_range(0, 255);
    end
  end
`else
  file_in = $fopen("C:/Users/igor4/trash/Documents/DigitalDesign/DV2/FilterDXI/simulation/image.txt", "r");
  if (!file_in) begin
    $display("Error: Cannot open input file!");
    $finish;
  end
  for (io = 0; io < HEIGHT; io++) begin
    $fscanf(file_in, "%s", hex_str);
    for (j = 0; j < WIDTH; j++) begin
      temp_byte = hex_to_byte(hex_str[j*2], hex_str[j*2+1]);
      image_2d[io][j] = temp_byte;
    end
  end
  $fclose(file_in);
`endif

  file_out = $fopen(output_filename, "w");
  add_addition_pixels(image_2d, extended_image, PADDING);

  for (int i = 0; i < HEIGHT; i++) begin
    for (int j = 0; j < WIDTH; j++) begin
      test_inputs_image[i * WIDTH + j] = pack_3x3(i + 1, j + 1);
    end
  end
end

 logic [1:0] test_cfgs[5] = '{
  2'b00,
  2'b01,
  2'b10,
  2'b11,
  2'b11
 };


int i = 0;
logic [7:0] expected;

task automatic checker_task();
  logic [71:0] din;
  logic [1:0] cfg;
  logic [7:0] dout;
  int i = 0;
  reg [7:0] processed_image [0:WIDTH*HEIGHT-1]; 

  forever begin
    input_data_q.get(din);
    input_cfg_q.get(cfg);
    output_data_q.get(dout);

    expected = apply_filter(din, cfg);
    processed_image[i] = dout;
    $fwrite(file_out, "%02x", processed_image[i]); 
    if ((i + 1) % WIDTH == 0) $fwrite(file_out, "\n"); 
    $display("[CHECKER] @%0t -> CHECK [%0d]: Expected = %02x | Got = %02x %s", $time, i, expected, dout, (dout === expected) ? "[OK]" : "[FAIL]");
    i++;
    if (i == NUM_TEST_VECTORS) disable checker_task;
  end
endtask


  initial begin
    fork
      reset_dut();
      monitor_input();
      monitor_output();
      checker_task();
      


       begin 
      for (int i = 0; i < NUM_TEST_VECTORS; i++) begin
      automatic int num_cycles_mst = $urandom_range(0, 3); 
      repeat(num_cycles_mst) @(posedge clk);
      drvie_mst(test_inputs_image[i], test_cfgs[1]);
      end
       end

      
       begin 
       for (int i = 0; i < NUM_TEST_VECTORS ; i++) begin 
         automatic int num_cycles_slv = $urandom_range(0, 3);
          repeat (num_cycles_slv) @(posedge clk);
          drive_slv();
        end
        end



    join_any


$display("Processing complete!");

  end 

endmodule
   
