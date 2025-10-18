// `timescale 1ns / 1ps
// //////////////////////////////////////////////////////////////////////////////////
// // Company: 
// // Engineer: 
// // 
// // Create Date: 05/09/2025 06:01:36 PM
// // Design Name: 
// // Module Name: top
// // Project Name: 
// // Target Devices: 
// // Tool Versions: 
// // Description: 
// // 
// // Dependencies: 
// // 
// // Revision:
// // Revision 0.01 - File Created
// // Additional Comments:
// // 
// //////////////////////////////////////////////////////////////////////////////////
// `include "driver.svh"


// module top(
//     input  sys_clk_200_p,
//     input  sys_clk_200_n,
//     input  porb_i,
//     //input  sync_reset_i,
//     inout  sda_io,
//     //output sda_out_en,
//     output seg_scl_o
// );

// typedef enum logic [1:0] {
//     IDLE,
//     SEND_NUMBER,
//     WAIT,
//     DONE
// } state_t;

// state_t fsm_state_ff, fsm_next;
// logic [7:0] digits [3:0];
// logic disp_strobe;
// //logic sda_out, sda_in;
// //logic sda_out_en;

// clk_wiz_0 clknetwork
//     (
//         // Clock out ports
//         .sys_clk_100_out(clk_i),     // output sys_clk_100_out
//         // Status and control signals
//         .resetn(porb_i), // input resetn
//         // Clock in ports
//         .clk_in1_p(sys_clk_200_p),    // input clk_in1_p
//         .clk_in1_n(sys_clk_200_n)    // input clk_in1_n
//     );

// // FSM state FF
// always_ff @(negedge porb_i, posedge clk_i ) begin : state_ff
//     if(!porb_i)begin
//         fsm_state_ff <= IDLE;
//     end else begin
//         fsm_state_ff <= fsm_next;
//     end
// end 


// // State transitioning logic
// always_comb begin : next_state
//     fsm_next = fsm_state_ff;
//     disp_strobe = 1'b0;
//     digits[0] = 8'h00;
//     digits[1] = 8'h00;
//     digits[2] = 8'h00;
//     digits[3] = 8'h00;
//     case (fsm_state_ff)
//         IDLE: 
//             begin
//                 fsm_next = SEND_NUMBER;
//             end
//         SEND_NUMBER:
//             begin
//                 disp_strobe = 1'b1;
//                 digits[0] = `_2;
//                 digits[1] = `_0;
//                 digits[2] = `_2;
//                 digits[3] = `_5;
//                 fsm_next = WAIT;
//             end
//         WAIT:
//             begin
//                 digits[0] = `_2;
//                 digits[1] = `_0;
//                 digits[2] = `_2;
//                 digits[3] = `_5;
//                 if (!busy) begin
//                     fsm_next = DONE;
//                 end
//             end
//         DONE:
//             //fsm_next = fsm_state_ff;
//             fsm_next = IDLE;
//         default: fsm_next = fsm_state_ff;
//     endcase
// end


// driver #(
//     .CLK_DIV(1024)
// )
// driver_u
// (
//     .clk_i(clk_i),
//     .porb_i(porb_i),
//     //.sync_reset_i(sync_reset_i),
//     .sync_reset_i(1'b0),
//     .digits_i(digits),
//     .disp_strobe_i(disp_strobe),
//     .busy_o(busy),
//     .sda_out(sda_out),
//     .sda_in(sda_in),
//     .sda_out_en(sda_out_en),
//     .seg_scl_o(seg_scl_o)
// );

// assign sda_in = sda_io;
// assign sda_io = (!sda_out_en || sda_out) ? 'Z : '0;

// // IOBUF sda_iobuf (
// //         .I ('0),
// //         .O (sda_in),
// //         .T (!sda_out_en || sda_out),
// //         .IO(sda_io)
// //     );

// endmodule