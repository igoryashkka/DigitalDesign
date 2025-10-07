import ili934x_pkg::*;

module ili934x_win_stream #(
  parameter int FIFO_GUARD = 2  // optional headroom guard
)(
  input  logic        clk,
  input  logic        rst_n,

  // Host controls
  input  logic        win_set_stb,
  input  logic [15:0] win_x0, win_y0, win_x1, win_y1,

  input  logic        stream_start,   // start 2C, then accept pixels
  input  logic [15:0] pix_data,       // RGB565
  input  logic        pix_valid,
  output logic        pix_ready,

  // Stream out
  output logic        item_valid,
  output wr_item_t    item,
  input  logic        item_ready,

  // Backpressure hint (optional): FIFO fullness from downstream
  input  logic        sink_can_accept // map to item_ready externally or a lookahead
);

  typedef enum logic [2:0] {D_IDLE, D_SEND, D_MEMWR, D_STREAM} d_e;
  d_e st;
  int step;

  // latch window inputs
  logic [15:0] x0, y0, x1, y1;

  // RGB565 double-byte handling
  logic        have_low;
  logic [7:0]  low_b;

  // defaults
  always_comb begin
    item_valid = 1'b0;
    item       = '{is_cmd:1'b0, byte:8'h00};
    pix_ready  = 1'b0;
  end

  // trivial guard using item_ready (or external fullness)
  wire can_push = item_ready && sink_can_accept;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= D_IDLE; step <= 0;
      x0 <= '0; y0 <= '0; x1 <= '0; y1 <= '0;
      have_low <= 1'b0; low_b <= 8'h00;
    end else begin
      unique case (st)
        D_IDLE: begin
          have_low <= 1'b0;
          if (win_set_stb) begin
            x0 <= win_x0; y0 <= win_y0; x1 <= win_x1; y1 <= win_y1;
            step <= 0; st <= D_SEND;
          end else if (stream_start) begin
            st <= D_MEMWR;
          end
        end

        // 2A x0H x0L x1H x1L, then 2B y0H y0L y1H y1L
        D_SEND: begin
          case (step)
            0:  if (can_push) begin item_valid<=1; item<= '{1,8'h2A};         step<=1; end
            1:  if (can_push) begin item_valid<=1; item<= '{0,x0[15:8]};      step<=2; end
            2:  if (can_push) begin item_valid<=1; item<= '{0,x0[7:0]};       step<=3; end
            3:  if (can_push) begin item_valid<=1; item<= '{0,x1[15:8]};      step<=4; end
            4:  if (can_push) begin item_valid<=1; item<= '{0,x1[7:0]};       step<=5; end
            5:  if (can_push) begin item_valid<=1; item<= '{1,8'h2B};         step<=6; end
            6:  if (can_push) begin item_valid<=1; item<= '{0,y0[15:8]};      step<=7; end
            7:  if (can_push) begin item_valid<=1; item<= '{0,y0[7:0]};       step<=8; end
            8:  if (can_push) begin item_valid<=1; item<= '{0,y1[15:8]};      step<=9; end
            9:  if (can_push) begin item_valid<=1; item<= '{0,y1[7:0]};       st<=D_IDLE; end
            default: st <= D_IDLE;
          endcase
        end

        // MEMORY WRITE (2C)
        D_MEMWR: begin
          if (can_push) begin
            item_valid <= 1'b1;
            item       <= '{is_cmd:1, byte:8'h2C};
            have_low   <= 1'b0;
            st         <= D_STREAM;
          end
        end

        // Stream RGB565 = high, then low
        D_STREAM: begin
          // send pending low byte first
          if (have_low) begin
            if (can_push) begin
              item_valid <= 1'b1;
              item       <= '{is_cmd:0, byte:low_b};
              have_low   <= 1'b0;
            end
          end else begin
            // accept a new pixel when we can push the high byte now
            pix_ready <= can_push;
            if (pix_valid && can_push) begin
              item_valid <= 1'b1;
              item       <= '{is_cmd:0, byte:pix_data[15:8]}; // high first
              low_b      <= pix_data[7:0];
              have_low   <= 1'b1;
            end
          end

          // exit when host stops, nothing pending; the FIFO will drain after
          if (!pix_valid && !have_low) begin
            // Optional: stay in stream until external tells you to quit
            // Here we exit when input pauses and no byte pending
            st <= D_IDLE;
          end
        end
      endcase
    end
  end
endmodule
