// `timescale 1ns/1ps

// module tb_ops;

  
//   logic [7:0] a, b;

//   wire [15:0] y_add;
//   wire c_add, v_add, n_add, z_add;

//   wire [15:0] y_sub;
//   wire c_sub, v_sub, n_sub, z_sub;

//   wire [15:0] y_mul;
//   wire c_mul, v_mul, n_mul, z_mul;


//   op_add u_add (.a(a), .b(b), .y(y_add), .carry(c_add), .overflow(v_add), .negative(n_add), .zero(z_add));
//   op_sub u_sub (.a(a), .b(b), .y(y_sub), .carry(c_sub), .overflow(v_sub), .negative(n_sub), .zero(z_sub));
//   op_mul u_mul (.a(a), .b(b), .y(y_mul), .carry(c_mul), .overflow(v_mul), .negative(n_mul), .zero(z_mul));




//   task automatic model_add(input  logic [7:0] ai, bi,
//                            output logic [15:0] y,
//                            output logic carry, overflow, negative, zero);
//     logic [8:0] sum9;
//     sum9     = {1'b0, ai} + {1'b0, bi};
//     y        = {7'b0, sum9};           
//     carry    = sum9[8];
//     overflow = (ai[7] == bi[7]) && (sum9[7] != ai[7]);
//     negative = y[7];                   
//     zero     = (y == 16'h0000);
//   endtask

//   task automatic model_sub(input  logic [7:0] ai, bi,
//                            output logic [15:0] y,
//                            output logic carry, overflow, negative, zero);
//     logic [8:0] diff9;
//     diff9    = {1'b0, ai} - {1'b0, bi};
//     y        = {7'b0, diff9};
//     carry    = ~diff9[8];             

//     overflow = (ai[7] ^ bi[7]) & (ai[7] ^ y[7]);
//     negative = y[7];
//     zero     = (y == 16'h0000);
//   endtask

//   task automatic model_mul(input  logic [7:0] ai, bi,
//                            output logic [15:0] y,
//                            output logic carry, overflow, negative, zero);
//     logic [15:0] prod;
//     prod     = ai * bi;
//     y        = prod;
//     carry    = 1'b0;                    
//     overflow = 1'b0;                    
//     negative = y[15];
//     zero     = (y == 16'h0000);
//   endtask

//   // -------- Check helpers --------
//   task automatic check_add(input logic [7:0] ai, bi);
//     logic [15:0] y_exp; logic c_exp, v_exp, n_exp, z_exp;
//     model_add(ai, bi, y_exp, c_exp, v_exp, n_exp, z_exp);
//     a = ai; b = bi; #1;
//     assert(y_add==y_exp && c_add==c_exp && v_add==v_exp && n_add==n_exp && z_add==z_exp)
//       else $fatal(1, "ADD mismatch a=%0d(0x%02h) b=%0d(0x%02h): "
//                       "got y=%h c=%0b v=%0b n=%0b z=%0b  exp y=%h c=%0b v=%0b n=%0b z=%0b",
//                       ai, ai, bi, bi, y_add, c_add, v_add, n_add, z_add, y_exp, c_exp, v_exp, n_exp, z_exp);
//   endtask

//   task automatic check_sub(input logic [7:0] ai, bi);
//     logic [15:0] y_exp; logic c_exp, v_exp, n_exp, z_exp;
//     model_sub(ai, bi, y_exp, c_exp, v_exp, n_exp, z_exp);
//     a = ai; b = bi; #1;
//     assert(y_sub==y_exp && c_sub==c_exp && v_sub==v_exp && n_sub==n_exp && z_sub==z_exp)
//       else $fatal(1, "SUB mismatch a=%0d(0x%02h) b=%0d(0x%02h): "
//                       "got y=%h c=%0b v=%0b n=%0b z=%0b  exp y=%h c=%0b v=%0b n=%0b z=%0b",
//                       ai, ai, bi, bi, y_sub, c_sub, v_sub, n_sub, z_sub, y_exp, c_exp, v_exp, n_exp, z_exp);
//   endtask

//   task automatic check_mul(input logic [7:0] ai, bi);
//     logic [15:0] y_exp; logic c_exp, v_exp, n_exp, z_exp;
//     model_mul(ai, bi, y_exp, c_exp, v_exp, n_exp, z_exp);
//     a = ai; b = bi; #1;
//     assert(y_mul==y_exp && c_mul==c_exp && v_mul==v_exp && n_mul==n_exp && z_mul==z_exp)
//       else $fatal(1, "MUL mismatch a=%0d(0x%02h) b=%0d(0x%02h): "
//                       "got y=%h c=%0b v=%0b n=%0b z=%0b  exp y=%h c=%0b v=%0b n=%0b z=%0b",
//                       ai, ai, bi, bi, y_mul, c_mul, v_mul, n_mul, z_mul, y_exp, c_exp, v_exp, n_exp, z_exp);
//   endtask



//   initial begin
//     a = '0; b = '0;
//     $display("Starting tb_ops...");


// byte A_CASES[$] = '{
//   8'h00, 8'h01, 8'h02, 8'h07, 8'h0F,
//   8'h7E, 8'h7F,       
//   8'h80, 8'h81,        
//   8'hFE, 8'hFF        
// };

// byte B_CASES[$] = '{
//   8'h00, 8'h01, 8'h03, 8'h08, 8'h10,
//   8'h20, 8'h40, 8'h7F,
//   8'h80, 8'hC0, 8'hFF  


//   foreach (A_CASES[i]) begin
//     foreach (B_CASES[j]) begin
//       byte ai = A_CASES[i];
//       byte bi = B_CASES[j];

      
//       check_add(ai, bi);
//       check_sub(ai, bi);
//       check_mul(ai, bi);

//     end
//   end

//     $display("PASSED ✔");
//     $finish;
//   end

// endmodule
