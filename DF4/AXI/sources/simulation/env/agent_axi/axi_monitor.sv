class axi_monitor #(parameter int DW = 32) extends uvm_monitor;

  `uvm_component_param_utils(axi_monitor#(DW))

  virtual axi_lite_if #(DW) vif;
  uvm_analysis_port #(axi_transaction#(DW)) ap;
  bit is_master;

  function new(string name, uvm_component parent);
    super.new(name, parent);

  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
      ap = new("ap", this);
    if (!uvm_config_db#(virtual axi_lite_if#(DW))::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", $sformatf("No vif for %s", get_full_name()))
    end

    if (!uvm_config_db#(bit)::get(this, "", "is_master", is_master)) begin
      is_master = 0;
    end
  endfunction

  task run_phase(uvm_phase phase);
    int unsigned tr_count = 0;
    // Wait for reset deassertion before sampling the bus.
    @(posedge vif.aclk);
    wait (vif.aresetn === 1'b1);

    forever begin
      @(posedge vif.aclk);
      if (!vif.aresetn) begin
        tr_count = 0;
        continue;
      end

      if ((vif.awvalid === 1'b1) && (vif.awready === 1'b1)) begin
        axi_write_transaction#(DW) tr;
        tr = axi_write_transaction#(DW)::type_id::create($sformatf("%s_tr", get_full_name()));
        tr_count++;
        tr.aw.addr = vif.awaddr;
        tr.aw.prot = vif.awprot;
        tr.w.data = vif.wdata;
        ap.write(tr);
       `uvm_info("AXI_MON",$sformatf("[%0t][%s] tr#%0d awaddr=0x%0h awprot=0x%0h wdata=0x%0h",$time, (is_master ? "IN " : "OUT"), tr_count, tr.aw.addr, tr.aw.prot, tr.w.data), UVM_MEDIUM)
      end
    end
  endtask
endclass