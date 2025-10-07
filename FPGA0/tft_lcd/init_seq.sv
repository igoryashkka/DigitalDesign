import ili934x_pkg::*;

module ili934x_init_seq #(
  parameter int CLK_HZ = 50_000_000
)(
  input  logic     clk,
  input  logic     rst_n,

  input  logic     start,         // pulse to start init
  output logic     done,          // goes high when finished

  // stream out
  output logic     item_valid,
  output wr_item_t item,
  input  logic     item_ready
);
  function automatic int ms_to_cyc(input int ms);
    return (CLK_HZ/1000) * ms;
  endfunction

  typedef enum logic [1:0] {S_IDLE, S_RUN, S_DONE} s_e;
  s_e  st;
  int  step;
  int  delay_cnt;

  // defaults
  always_comb begin
    item_valid = 1'b0;
    item       = '{is_cmd:1'b0, byte:8'h00};
  end

  // program:
  // 0: SWRESET (01h), wait 5 ms
  // 1: SLPOUT  (11h), wait 120 ms
  // 2: COLMOD  (3Ah), 55h
  // 3: MADCTL  (36h), 48h
  // 4: DISPON  (29h), wait 20 ms
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= S_IDLE; step <= 0; delay_cnt <= 0; done <= 1'b0;
    end else begin
      done <= 1'b0;
      unique case (st)
        S_IDLE: begin
          if (start) begin
            st <= S_RUN; step <= 0; delay_cnt <= 0;
          end
        end
        S_RUN: begin
          if (delay_cnt != 0) begin
            delay_cnt <= delay_cnt - 1;
          end else begin
            unique case (step)
              0: if (item_ready) begin
                   item_valid <= 1;
                   item       <= '{is_cmd:1, byte:8'h01};
                   step       <= 1; delay_cnt <= ms_to_cyc(5);
                 end
              1: if (item_ready) begin
                   item_valid <= 1;
                   item       <= '{is_cmd:1, byte:8'h11};
                   step       <= 2; delay_cnt <= ms_to_cyc(120);
                 end
              2: if (item_ready) begin
                   item_valid <= 1; item <= '{is_cmd:1, byte:8'h3A}; step <= 3;
                 end
              3: if (item_ready) begin
                   item_valid <= 1; item <= '{is_cmd:0, byte:8'h55}; step <= 4;
                 end
              4: if (item_ready) begin
                   item_valid <= 1; item <= '{is_cmd:1, byte:8'h36}; step <= 5;
                 end
              5: if (item_ready) begin
                   item_valid <= 1; item <= '{is_cmd:0, byte:8'h48}; step <= 6;
                 end
              6: if (item_ready) begin
                   item_valid <= 1;
                   item       <= '{is_cmd:1, byte:8'h29};
                   step       <= 7; delay_cnt <= ms_to_cyc(20);
                 end
              default: begin
                   st <= S_DONE;
                 end
            endcase
          end
        end
        S_DONE: begin
          done <= 1'b1; // stay done
        end
      endcase
    end
  end
endmodule
