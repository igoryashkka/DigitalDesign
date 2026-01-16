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

  task run_phase(uvm_phase phase);
    if (rst_vif == null)
      return;

    forever begin
      @(negedge rst_vif.rstn);
      pixel_queue.delete();
      img_counter = 0;
      `uvm_info("FILE_SCB", "Reset detected, clearing pixel queue and counter", UVM_LOW)
    end
  endtask

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
      $display("[FILE SCB] ERROR: cannot open %s", output_filename);
      return;
    end

    foreach (pixel_queue[i]) begin
      $fwrite(file_out, "%02x", pixel_queue[i]);
      idx++;
      if ((idx % img_width) == 0)
        $fwrite(file_out, "\n");
    end

    $fclose(file_out);
    $display("[FILE SCB] Saved image %s", output_filename);
    pixel_queue.delete();
  endfunction
endclass
