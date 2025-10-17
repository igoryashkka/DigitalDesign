// `timescale 1ns/1ps

// module driver_wrap #(
//   parameter int CLK_DIV = 1024  // forwarded to i2c master via driver
// )(
//   input  logic        clk,
//   input  logic        rst_n,          // active-low POR
//   input  logic        sync_reset,
//   input  logic [31:0] digits_flat,    // {d3,d2,d1,d0}
//   input  logic        disp_strobe,
//   output logic        busy,
//   output logic        sda_out,
//   input  logic        sda_in,
//   output logic        sda_out_en,
//   output logic        scl
// );

//   // Unpack to SV array expected by `driver`
//   logic [7:0] digits [0:3];
//   assign {digits[3], digits[2], digits[1], digits[0]} = digits_flat;

//   driver #(.CLK_DIV(CLK_DIV)) u_drv (
//     .clk_i        (clk),
//     .porb_i       (rst_n),
//     .sync_reset_i (sync_reset),
//     .digits_i     (digits),
//     .disp_strobe_i(disp_strobe),
//     .busy_o       (busy),
//     .sda_out      (sda_out),
//     .sda_in       (sda_in),
//     .sda_out_en   (sda_out_en),
//     .seg_scl_o    (scl)
//   );

// endmodule
