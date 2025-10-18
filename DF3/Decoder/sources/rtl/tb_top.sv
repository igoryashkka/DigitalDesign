
// module tb_top();

// logic clk, porb, sync_reset;
// tri1 seg_sda, seg_scl;
// logic sda_in;

// initial begin
//     porb = 0;
//     sync_reset = 1;
//     #120ns;
//     @(posedge clk);
//     porb = 1;
//     repeat(20) @(posedge clk);
//     sync_reset = 0;

//     #2ms;
//     $finish();

// end

// initial begin
//     sda_in = 1;
//     forever begin
//         repeat(9) @(negedge seg_scl);
//         #10ns;
//         sda_in = 0;
//         @(negedge seg_scl)
//         #10ns;
//         sda_in = 1;
//     end
// end

// assign seg_sda = sda_out_en ? sda_out : 1'bz;



// initial begin
//     clk = 0;
//     forever #40ns clk = ~clk;
// end


// top top_u(
//     .clk_i(clk),
//     .porb_i(porb),
//     .sync_reset_i(sync_reset),
//     .sda_out(sda_out),
//     .sda_in(sda_in),
//     .sda_out_en(sda_out_en),
//     .seg_scl_o(seg_scl)
// );


// endmodule