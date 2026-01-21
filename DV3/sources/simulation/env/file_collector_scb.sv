class file_collector_scb extends uvm_component;
  `uvm_component_utils(file_collector_scb)

  uvm_analysis_imp #(dxi_transation#(8), file_collector_scb) out_imp;

  virtual dxi_if #(72) rst_vif;

  int img_width  = 256;
  int img_height = 194;
  string file_prefix = "output";
  int img_counter = 0;

  byte unsigned pixel_queue[$];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    out_imp = new("out_imp", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  function void write(dxi_transation#(8) tr);
    pixel_queue.push_back(tr.data[7:0]);
    if (pixel_queue.size() >= img_width * img_height) begin
      save_image();
    end
  endfunction

  function void save_image();
    string output_filename;
    int file_out;
    int idx = 0;

    output_filename = $sformatf("%s_%0d_%0d_%0d.txt",
                                file_prefix, img_width, img_height, img_counter++);
    file_out = $fopen(output_filename, "w");

    if (!file_out) begin
      `uvm_error("FILE_SCB", $sformatf("Cannot open %s", output_filename))
      return;
    end

    foreach (pixel_queue[i]) begin
      $fwrite(file_out, "%02x", pixel_queue[i]);
      idx++;
      if ((idx % img_width) == 0)
        $fwrite(file_out, "\n");
    end

    $fclose(file_out);
    `uvm_info("FILE_SCB",$sformatf("Saved image %s", output_filename),UVM_LOW)
    pixel_queue.delete();
  endfunction
endclass
