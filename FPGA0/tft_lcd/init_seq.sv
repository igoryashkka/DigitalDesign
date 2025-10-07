import ili934x_pkg::*;

module ili934x_init_seq #(
  parameter int CLK_HZ = 50_000_000
)(
  input  logic     clk,
  input  logic     rst_n,

  input  logic     start,         // pulse to start init
  output logic     done,          // stays high when finished

  // stream out (valid/ready)
  output logic     item_valid,
  output wr_item_t item,
  input  logic     item_ready
);

  // Convert milliseconds to clock cycles
  function automatic int ms_to_cyc(input int ms);
    return (CLK_HZ/1000) * ms;
  endfunction

  typedef enum logic [1:0] {S_IDLE, S_RUN, S_DONE} s_e;

  s_e  st;
  int  step;
  int  delay_cnt;

  // Handshake helper
  wire fire = item_valid && item_ready;

  // Registered output (single driver)
  wr_item_t item_q;
  logic     item_valid_q;

  assign item       = item_q;
  assign item_valid = item_valid_q;

  // ----------------------------------------------------------------------------
  // Program:
  //  0: SWRESET (01h), wait 5 ms
  //  1: SLPOUT  (11h), wait 120 ms
  //  2: COLMOD  (3Ah) -> 55h (16bpp)
  //  3: MADCTL  (36h) -> 48h (MX|BGR portrait)
  //  4: DISPON  (29h), wait 20 ms
  // ----------------------------------------------------------------------------

  // Small task to enqueue one byte when the output buffer is free
  task automatic send_byte(input logic is_cmd, input logic [7:0] byte_pack);
    if (!item_valid_q) begin
      item_q        <= '{is_cmd:is_cmd, byte_pack:byte_pack};
      item_valid_q  <= 1'b1;     // hold valid until sink asserts ready
    end
  endtask

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st           <= S_IDLE;
      step         <= 0;
      delay_cnt    <= 0;
      done         <= 1'b0;
      item_q       <= '{is_cmd:1'b0, byte_pack:8'h00};
      item_valid_q <= 1'b0;
    end else begin
      // Drop valid after a successful handshake
      if (fire) begin
        item_valid_q <= 1'b0;
      end

      // Default: keep done sticky once asserted
      // (If you want restart capability, add logic to clear done on a new start)
      unique case (st)
        S_IDLE: begin
          if (start) begin
            st        <= S_RUN;
            step      <= 0;
            delay_cnt <= 0;
            // clear any leftover valid
            item_valid_q <= 1'b0;
          end
        end

        S_RUN: begin
          if (delay_cnt != 0) begin
            delay_cnt <= delay_cnt - 1;
          end else begin
            // Issue byte for current step when output not busy
            case (step)
              // 0) SWRESET -> wait 5 ms
              0: begin
                   if (!item_valid_q) send_byte(1'b1, 8'h01);
                   if (fire) begin
                     step      <= 1;
                     delay_cnt <= ms_to_cyc(5);
                   end
                 end
              // 1) SLPOUT -> wait 120 ms
              1: begin
                   if (!item_valid_q) send_byte(1'b1, 8'h11);
                   if (fire) begin
                     step      <= 2;
                     delay_cnt <= ms_to_cyc(120);
                   end
                 end
              // 2) COLMOD
              2: begin
                   if (!item_valid_q) send_byte(1'b1, 8'h3A);
                   if (fire) step <= 3;
                 end
              3: begin
                   if (!item_valid_q) send_byte(1'b0, 8'h55); // 16bpp
                   if (fire) step <= 4;
                 end
              // 3) MADCTL
              4: begin
                   if (!item_valid_q) send_byte(1'b1, 8'h36);
                   if (fire) step <= 5;
                 end
              5: begin
                   if (!item_valid_q) send_byte(1'b0, 8'h48); // MX|BGR portrait
                   if (fire) step <= 6;
                 end
              // 4) DISPON -> wait 20 ms
              6: begin
                   if (!item_valid_q) send_byte(1'b1, 8'h29);
                   if (fire) begin
                     step      <= 7;
                     delay_cnt <= ms_to_cyc(20);
                   end
                 end
              default: begin
                   st <= S_DONE;
                 end
            endcase
          end
        end

        S_DONE: begin
          done <= 1'b1; // remain done
          // (Optional) allow restart:
          // if (start) begin st<=S_RUN; step<=0; delay_cnt<=0; done<=1'b0; end
        end
      endcase
    end
  end
endmodule
