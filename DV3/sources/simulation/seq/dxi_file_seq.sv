class dxi_file_seq #(int DW=72) extends uvm_sequence #(dxi_transation#(DW));
  `uvm_object_param_utils(dxi_file_seq#(DW))

  localparam int WIDTH  = 256;
  localparam int HEIGHT = 194;

  typedef byte unsigned image_t    [HEIGHT][WIDTH];
  typedef byte unsigned extended_t [HEIGHT+2][WIDTH+2];

  // Optional handles/controls passed in by the test.
  virtual config_if cfg_vif;
  string input_file = "../DV2/FilterDXI/simulation/input_256_194.txt";
  logic [1:0] config_sel = 2'b11;

  function new(string name="dxi_file_seq");
    super.new(name);
  endfunction

  // Convert two ASCII hex characters into a byte.
  function automatic byte unsigned hex_to_byte(byte unsigned char1, byte unsigned char2);
    byte unsigned hi;
    byte unsigned lo;
    if (char1 >= "a") hi = char1 - "a" + 10;
    else              hi = char1 - "0";
    if (char2 >= "a") lo = char2 - "a" + 10;
    else              lo = char2 - "0";
    return (hi << 4) | lo;
  endfunction

  // Pad the image by duplicating the border pixels.
  function automatic void add_padding(
      input  image_t    image,
      output extended_t extended);
    for (int i = 0; i < HEIGHT; i++) begin
      for (int j = 0; j < WIDTH; j++) begin
        extended[i+1][j+1] = image[i][j];
      end
    end

    for (int i = 0; i < HEIGHT; i++) begin
      extended[i+1][0]       = image[i][0];
      extended[i+1][WIDTH+1] = image[i][WIDTH-1];
    end

    for (int j = 0; j < WIDTH; j++) begin
      extended[0][j+1]        = image[0][j];
      extended[HEIGHT+1][j+1] = image[HEIGHT-1][j];
    end

    extended[0][0]               = image[0][0];
    extended[0][WIDTH+1]         = image[0][WIDTH-1];
    extended[HEIGHT+1][0]        = image[HEIGHT-1][0];
    extended[HEIGHT+1][WIDTH+1]  = image[HEIGHT-1][WIDTH-1];
  endfunction

  // Pack a 3x3 window into DW bits with little-endian pixel order.
  function automatic logic [DW-1:0] pack_3x3(
      input extended_t extended,
      input int row,
      input int col);
    logic [DW-1:0] packed;
    packed = '0;
    for (int r = -1; r <= 1; r++) begin
      for (int c = -1; c <= 1; c++) begin
        packed = (packed << 8) | extended[row + r][col + c];
      end
    end
    return packed;
  endfunction

  task body();
    dxi_transation#(DW) tr;
    image_t    image;
    extended_t ext_img;
    string hex_line;
    int file_in;
    string arg_file;

    if (starting_phase != null)
      starting_phase.raise_objection(this);

    if (cfg_vif == null) begin
      `uvm_fatal(get_type_name(), "cfg_vif is not set for file sequence")
    end

    if (DW != 72) begin
      `uvm_fatal(get_type_name(), $sformatf("File sequence expects DW=72, got %0d", DW))
    end

    if ($value$plusargs("IMG_FILE=%s", arg_file))
      input_file = arg_file;

    file_in = $fopen(input_file, "r");
    if (!file_in) begin
      `uvm_fatal(get_type_name(), $sformatf("Cannot open input image file %s", input_file))
    end

    for (int i = 0; i < HEIGHT; i++) begin
      if ($fscanf(file_in, "%s", hex_line) != 1) begin
        `uvm_fatal(get_type_name(), $sformatf("Unexpected EOF reading line %0d from %s", i, input_file))
      end
      if (hex_line.len() < 2*WIDTH) begin
        `uvm_fatal(get_type_name(), $sformatf("Line %0d too short (%0d chars) in %s", i, hex_line.len(), input_file))
      end
      for (int j = 0; j < WIDTH; j++) begin
        image[i][j] = hex_to_byte(hex_line[j*2], hex_line[j*2+1]);
      end
    end

    $fclose(file_in);

    add_padding(image, ext_img);
    cfg_vif.config_select <= config_sel;
    @(posedge cfg_vif.clk);

    foreach (image[r]) begin
      for (int c = 0; c < WIDTH; c++) begin
        tr = dxi_transation#(DW)::type_id::create($sformatf("file_tr_r%0d_c%0d", r, c));
        start_item(tr);
        tr.data      = pack_3x3(ext_img, r+1, c+1);
        tr.use_delay = 0;
        tr.delay     = 1;
        finish_item(tr);
      end
    end

    if (starting_phase != null)
      starting_phase.drop_objection(this);
  endtask
endclass
