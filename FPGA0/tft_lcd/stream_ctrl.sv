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

  // Stream out (valid/ready)
  output logic        item_valid,
  output wr_item_t    item,
  input  logic        item_ready,

  // Backpressure hint (optional): FIFO fullness from downstream
  input  logic        sink_can_accept
);

  typedef enum logic [2:0] {D_IDLE, D_SEND, D_MEMWR, D_STREAM} d_e;
  d_e st;
  int step;

  // Latch window
  logic [15:0] x0, y0, x1, y1;

  // RGB565 low-byte pending
  logic        have_low;
  logic [7:0]  low_b;

  // Registered stream outputs (SINGLE DRIVER)
  wr_item_t item_q;
  logic     item_valid_q;

  assign item       = item_q;
  assign item_valid = item_valid_q;

  // We can push a new byte only if:
  //   - downstream is ready,
  //   - downstream can accept (hint),
  //   - we're NOT already holding a valid byte waiting to fire
  wire can_push = item_ready && sink_can_accept && !item_valid_q;

  // pix_ready when we are in streaming state, no low byte pending,
  // and we can present the high byte of a new pixel right now
  assign pix_ready = (st == D_STREAM) && !have_low && can_push;

  // helper: present one byte (holds valid until handshake fires)
  task automatic send_byte(input logic is_cmd, input logic [7:0] b);
    if (!item_valid_q) begin
      item_q       <= '{is_cmd:is_cmd, byte_pack:b};
      item_valid_q <= 1'b1;
    end
  endtask

  // handshake success (byte consumed)
  wire fire = item_valid_q && item_ready;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st           <= D_IDLE;
      step         <= 0;
      x0 <= '0; y0 <= '0; x1 <= '0; y1 <= '0;
      have_low     <= 1'b0;
      low_b        <= 8'h00;
      item_q       <= '{is_cmd:1'b0, byte_pack:8'h00};
      item_valid_q <= 1'b0;
    end else begin
      // drop valid on handshake
      if (fire) item_valid_q <= 1'b0;

      unique case (st)
        // ----------------------------------------------------------
        D_IDLE: begin
          have_low <= 1'b0;
          if (win_set_stb) begin
            x0 <= win_x0; y0 <= win_y0; x1 <= win_x1; y1 <= win_y1;
            step <= 0;
            st   <= D_SEND;
          end else if (stream_start) begin
            st <= D_MEMWR;
          end
        end

        // ----------------------------------------------------------
        // Send window: 2A x0H x0L x1H x1L, then 2B y0H y0L y1H y1L
        D_SEND: begin
          case (step)
            0:  if (can_push) begin send_byte(1'b1, 8'h2A);        step <= 1; end
            1:  if (can_push) begin send_byte(1'b0, x0[15:8]);     step <= 2; end
            2:  if (can_push) begin send_byte(1'b0, x0[7:0]);      step <= 3; end
            3:  if (can_push) begin send_byte(1'b0, x1[15:8]);     step <= 4; end
            4:  if (can_push) begin send_byte(1'b0, x1[7:0]);      step <= 5; end
            5:  if (can_push) begin send_byte(1'b1, 8'h2B);        step <= 6; end
            6:  if (can_push) begin send_byte(1'b0, y0[15:8]);     step <= 7; end
            7:  if (can_push) begin send_byte(1'b0, y0[7:0]);      step <= 8; end
            8:  if (can_push) begin send_byte(1'b0, y1[15:8]);     step <= 9; end
            9:  if (can_push) begin send_byte(1'b0, y1[7:0]);      st   <= D_IDLE; end
            default: st <= D_IDLE;
          endcase
        end

        // ----------------------------------------------------------
        // MEMORY WRITE (2C)
        D_MEMWR: begin
          if (can_push) begin
            send_byte(1'b1, 8'h2C);
            // move to STREAM after the byte is accepted
            if (fire) begin
              have_low <= 1'b0;
              st       <= D_STREAM;
            end
          end
        end

        // ----------------------------------------------------------
        // Stream RGB565: high byte, then low byte
        D_STREAM: begin
          // If a low byte is pending, send it
          if (have_low) begin
            if (can_push) begin
              send_byte(1'b0, low_b);
              if (fire) have_low <= 1'b0;
            end
          end else begin
            // No low pending: accept a new pixel when ready
            if (pix_valid && pix_ready) begin
              // push high byte now, queue low for next transfer
              send_byte(1'b0, pix_data[15:8]);
              if (can_push) begin
                // byte is now presented; the sink may accept later
                low_b    <= pix_data[7:0];
                have_low <= 1'b1;
              end
            end
          end

          // exit when producer paused and no pending low byte
          if (!pix_valid && !have_low) begin
            st <= D_IDLE;
          end
        end
      endcase
    end
  end
endmodule
