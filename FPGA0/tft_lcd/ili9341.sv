`timescale 1ns/1ps

module ili934x_driver #(
  // Panel / controller selection
  parameter bit   P_ILI9341      = 1'b1,    // set 0 for ILI9325 (adjust init)
  // Clocks and timings
  parameter int   CLK_HZ         = 50_000_000,
  parameter int   WR_PULSE_CYC   = 2,       // WR low pulse width (>=1)
  parameter int   WR_RECOV_CYC   = 1,       // recovery cycles between bytes
  // Geometry
  parameter int   X_RES          = 240,
  parameter int   Y_RES          = 320
)(
  input  logic          clk,
  input  logic          rst_n,

  // --- Simple host control ---
  input  logic          init_start,     // pulse 1 clk to start init
  output logic          init_done,      // goes high when panel ready

  // Set drawing window (inclusive coordinates)
  input  logic          win_set_stb,    // pulse to latch coords & send 2A/2B
  input  logic  [15:0]  win_x0,
  input  logic  [15:0]  win_y0,
  input  logic  [15:0]  win_x1,
  input  logic  [15:0]  win_y1,

  // Start streaming into 0x2C (MEMORY WRITE). Continue while sending pixels.
  input  logic          stream_start,   // pulse once before giving pixels

  // RGB565 pixel input stream
  input  logic  [15:0]  pix_data,       // {R4:0,G5:0,B4:0}
  input  logic          pix_valid,
  output logic          pix_ready,

  // Busy flag (any op in flight)
  output logic          busy,

  // --- 8080-8 parallel LCD interface ---
  output logic          lcd_cs_n,
  output logic          lcd_rd_n,
  output logic          lcd_rst_n,

  output logic          lcd_dc,         // 1=data, 0=cmd
  output logic          lcd_wr_n,

  output logic  [7:0]   lcd_d
);

  // ==========================================================================
  // FIFO for write items (cmd/data bytes)
  // ==========================================================================

  typedef struct packed {
    logic       is_cmd;   // 1=cmd, 0=data
    logic [7:0] pack_byte;
  } wr_item_t;

  localparam int FIFO_DEPTH = 256;

  wr_item_t fifo_mem [FIFO_DEPTH];

  logic [$clog2(FIFO_DEPTH):0] wr_wptr, wr_rptr;
  logic fifo_full, fifo_empty;

  assign fifo_empty = (wr_wptr == wr_rptr);
  assign fifo_full  = ( (wr_wptr[$bits(wr_wptr)-2:0] == wr_rptr[$bits(wr_rptr)-2:0])
                     && (wr_wptr[$bits(wr_wptr)-1]  != wr_rptr[$bits(wr_rptr)-1]) );

  // Push interface (one cycle per byte)
  logic       push_valid;
  logic       push_is_cmd;      // 1=cmd, 0=data
  logic [7:0] push_byte;

  // Enqueue on push
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_wptr <= '0;
    end else if (push_valid && !fifo_full) begin
      fifo_mem[wr_wptr[$bits(wr_wptr)-2:0]].is_cmd   <= push_is_cmd;
      fifo_mem[wr_wptr[$bits(wr_wptr)-2:0]].pack_byte<= push_byte;
      wr_wptr <= wr_wptr + 1;
    end
  end

  // Dequeue peek
  wr_item_t deq_item;
  assign deq_item = fifo_mem[wr_rptr[$bits(wr_rptr)-2:0]];

  // ==========================================================================
  // Low-level 8080 write engine (8080-II timing; WR low window)
  // ==========================================================================

  // 8080 pins default
  assign lcd_rd_n = 1'b1;     // no reads
  assign lcd_cs_n = 1'b0;     // permanently selected (single device)

  // Hardware reset: hold high (external POR recommended)
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) lcd_rst_n <= 1'b0;
    else        lcd_rst_n <= 1'b1;
  end

  typedef enum logic [1:0] {WIDLE, WSETUP, WPULSE, WRECOV} wstate_e;
  wstate_e wstate;
  logic [$clog2(WR_PULSE_CYC+1)-1:0] pulse_cnt;
  logic [$clog2(WR_RECOV_CYC+1)-1:0] recov_cnt;

  // Outputs
  logic [7:0] d_out; logic dc_out; logic wr_n_out;

  assign lcd_d    = d_out;     // Data bus
  assign lcd_dc   = dc_out;    // 0=cmd, 1=data
  assign lcd_wr_n = wr_n_out;  // active-low write strobe

  // Write state machine
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wstate   <= WIDLE;
      wr_rptr  <= '0;
      d_out    <= 8'h00;
      dc_out   <= 1'b0;
      wr_n_out <= 1'b1;
      pulse_cnt<= '0;
      recov_cnt<= '0;
    end else begin
      case (wstate)
        WIDLE: begin
          wr_n_out <= 1'b1;
          if (!fifo_empty) begin
            d_out  <= deq_item.pack_byte;
            dc_out <= ~deq_item.is_cmd; // lcd_dc=0 for cmd, 1 for data
            wstate <= WSETUP;
          end
        end
        WSETUP: begin
          wr_n_out <= 1'b0;           // drive WR low
          pulse_cnt<= '0;
          wstate   <= WPULSE;
        end
        WPULSE: begin
          if (pulse_cnt == WR_PULSE_CYC-1) begin
            wr_n_out <= 1'b1;         // latch inside LCD during low; release
            recov_cnt<= '0;
            wstate   <= WRECOV;
          end else begin
            pulse_cnt<= pulse_cnt + 1;
          end
        end
        WRECOV: begin
          if (recov_cnt == WR_RECOV_CYC-1) begin
            wr_rptr <= wr_rptr + 1;   // pop the FIFO entry
            wstate  <= WIDLE;
          end else begin
            recov_cnt <= recov_cnt + 1;
          end
        end
      endcase
    end
  end

  // ==========================================================================
  // INIT SEQUENCE (synthesizable; cycle-based delays)
  // ==========================================================================

  function automatic int ms_to_cyc(input int ms);
    return (CLK_HZ/1000) * ms;
  endfunction

  typedef enum logic [1:0] {IS_IDLE, IS_SEQ, IS_DONE} is_e;
  is_e istate;
  int  istep;
  int  delay_cnt;

  // ==========================================================================
  // WINDOW + STREAM FSM
  // ==========================================================================
  typedef enum logic [2:0] {DW_IDLE, DW_SEND, DW_MEMWR, DW_STREAM} dw_e;
  dw_e dstate;
  int  dstep;

  // latch window on strobe (so host can change inputs later)
  logic [15:0] x0_l, y0_l, x1_l, y1_l;

  // Pixel streaming: handle two data bytes over two cycles
  logic        have_low;
  logic [7:0]  low_byte;

  // pix_ready when we are streaming, have no pending low byte, and FIFO has space
  always_comb begin
    pix_ready = (dstate==DW_STREAM) && !fifo_full && !have_low;
  end

  // Busy: if any sequencer is active or FIFO not empty
  logic seq_busy;
  assign busy = !fifo_empty || seq_busy;

  // ==========================================================================
  // Main control (produces push_* signals)
  // ==========================================================================
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // defaults
      push_valid <= 1'b0;
      push_is_cmd<= 1'b0;
      push_byte  <= 8'h00;

      istate     <= IS_IDLE;
      istep      <= 0;
      delay_cnt  <= 0;
      init_done  <= 1'b0;

      dstate     <= DW_IDLE;
      dstep      <= 0;
      x0_l <= '0; y0_l <= '0; x1_l <= '0; y1_l <= '0;
      have_low   <= 1'b0; low_byte <= 8'h00;

      seq_busy   <= 1'b0;
    end else begin
      // defaults this cycle
      push_valid <= 1'b0;
      push_is_cmd<= 1'b0;
      push_byte  <= 8'h00;
      init_done  <= 1'b0;
      seq_busy   <= 1'b0;

      // ---------------- INIT FSM ----------------
      case (istate)
        IS_IDLE: begin
          if (init_start) begin
            istate    <= IS_SEQ;
            istep     <= 0;
            delay_cnt <= 0;
          end
        end

        IS_SEQ: begin
          seq_busy <= 1'b1;
          if (delay_cnt != 0) begin
            delay_cnt <= delay_cnt - 1;
          end else begin
            unique case (istep)
              // SWRESET (01h), wait 5ms
              0: if (!fifo_full) begin
                   push_valid <= 1'b1; push_is_cmd <= 1'b1; push_byte <= 8'h01;
                   istep <= 1; delay_cnt <= ms_to_cyc(5);
                 end
              // SLPOUT (11h), wait 120ms
              1: if (!fifo_full) begin
                   push_valid <= 1'b1; push_is_cmd <= 1'b1; push_byte <= 8'h11;
                   istep <= 2; delay_cnt <= ms_to_cyc(120);
                 end
              // COLMOD (3Ah) = 16bpp (55h)
              2: if (!fifo_full) begin
                   push_valid <= 1'b1; push_is_cmd <= 1'b1; push_byte <= 8'h3A;
                   istep <= 3;
                 end
              3: if (!fifo_full) begin
                   push_valid <= 1'b1; push_is_cmd <= 1'b0; push_byte <= 8'h55;
                   istep <= 4;
                 end
              // MADCTL (36h) = 0x48 (MX|BGR portrait)
              4: if (!fifo_full) begin
                   push_valid <= 1'b1; push_is_cmd <= 1'b1; push_byte <= 8'h36;
                   istep <= 5;
                 end
              5: if (!fifo_full) begin
                   push_valid <= 1'b1; push_is_cmd <= 1'b0; push_byte <= 8'h48;
                   istep <= 6;
                 end
              // DISPON (29h), wait 20ms
              6: if (!fifo_full) begin
                   push_valid <= 1'b1; push_is_cmd <= 1'b1; push_byte <= 8'h29;
                   istep <= 7; delay_cnt <= ms_to_cyc(20);
                 end
              default: begin
                   istate <= IS_DONE;
                 end
            endcase
          end
        end

        IS_DONE: begin
          init_done <= 1'b1;
          // remain done
        end
      endcase

      // ---------------- WINDOW/STREAM FSM ----------------
      case (dstate)
        DW_IDLE: begin
          have_low <= have_low; // keep pending if any (should be 0 here)
          if (win_set_stb) begin
            // latch window
            x0_l <= win_x0; y0_l <= win_y0;
            x1_l <= win_x1; y1_l <= win_y1;
            dstep <= 0;
            dstate<= DW_SEND;
          end else if (stream_start) begin
            dstate<= DW_MEMWR;
          end
        end

        // Send: 2A x0H x0L x1H x1L, 2B y0H y0L y1H y1L
        DW_SEND: begin
          seq_busy <= 1'b1;
          unique case (dstep)
            0: if (!fifo_full) begin push_valid<=1; push_is_cmd<=1; push_byte<=8'h2A; dstep<=1; end
            1: if (!fifo_full) begin push_valid<=1; push_is_cmd<=0; push_byte<=x0_l[15:8]; dstep<=2; end
            2: if (!fifo_full) begin push_valid<=1; push_is_cmd<=0; push_byte<=x0_l[7:0];  dstep<=3; end
            3: if (!fifo_full) begin push_valid<=1; push_is_cmd<=0; push_byte<=x1_l[15:8]; dstep<=4; end
            4: if (!fifo_full) begin push_valid<=1; push_is_cmd<=0; push_byte<=x1_l[7:0];  dstep<=5; end
            5: if (!fifo_full) begin push_valid<=1; push_is_cmd<=1; push_byte<=8'h2B; dstep<=6; end
            6: if (!fifo_full) begin push_valid<=1; push_is_cmd<=0; push_byte<=y0_l[15:8]; dstep<=7; end
            7: if (!fifo_full) begin push_valid<=1; push_is_cmd<=0; push_byte<=y0_l[7:0];  dstep<=8; end
            8: if (!fifo_full) begin push_valid<=1; push_is_cmd<=0; push_byte<=y1_l[15:8]; dstep<=9; end
            9: if (!fifo_full) begin push_valid<=1; push_is_cmd<=0; push_byte<=y1_l[7:0];  dstate<=DW_IDLE; end
            default: dstate <= DW_IDLE;
          endcase
        end

        // Issue MEMORY WRITE (2Ch)
        DW_MEMWR: begin
          seq_busy <= 1'b1;
          if (!fifo_full) begin
            push_valid <= 1'b1; push_is_cmd <= 1'b1; push_byte <= 8'h2C;
            dstate <= DW_STREAM;
            have_low <= 1'b0;
          end
        end

        // Stream RGB565: push hi byte, then low byte next cycle
        DW_STREAM: begin
          seq_busy <= 1'b1;

          // If a low byte is pending, send it first
          if (have_low) begin
            if (!fifo_full) begin
              push_valid <= 1'b1; push_is_cmd <= 1'b0; push_byte <= low_byte;
              have_low   <= 1'b0;
            end
          end else begin
            // No pending low byte: accept new pixel if provided
            if (pix_valid && !fifo_full) begin
              // push high byte now, queue low byte for next cycle
              push_valid <= 1'b1; push_is_cmd <= 1'b0; push_byte <= pix_data[15:8];
              low_byte   <= pix_data[7:0];
              have_low   <= 1'b1;
            end
          end

          // Exit condition: host stops driving pixels and nothing pending,
          // and FIFO has drained (so the last bytes are issued)
          if (!pix_valid && !have_low && fifo_empty) begin
            dstate <= DW_IDLE;
          end
        end
      endcase
    end
  end

endmodule
