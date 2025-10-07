module ili934x_fill_example #(
  parameter int CLK_HZ = 50_000_000
)(
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start_fill,      
  input  logic [15:0] color_rgb565,    

  // LCD pins
  output logic        lcd_cs_n,
  output logic        lcd_dc,
  output logic        lcd_wr_n,
  output logic        lcd_rd_n,
  output logic        lcd_rst_n,
  output logic [7:0]  lcd_d
);

  // Instantiate driver
  logic init_done, busy;
  logic win_set_stb, stream_start;
  logic [15:0] win_x0, win_y0, win_x1, win_y1;
  logic pix_valid, pix_ready;
  logic [15:0] pix_data;

  ili934x_driver #(
    .CLK_HZ(CLK_HZ),
    .WR_PULSE_CYC(2),
    .WR_RECOV_CYC(1),
    .X_RES(240),
    .Y_RES(320)
  ) u_drv (
    .clk, .rst_n,
    .init_start(start_fill),
    .init_done,
    .win_set_stb, .win_x0, .win_y0, .win_x1, .win_y1,
    .stream_start,
    .pix_data, .pix_valid, .pix_ready,
    .busy,
    .lcd_cs_n, .lcd_dc, .lcd_wr_n, .lcd_rd_n, .lcd_rst_n, .lcd_d
  );

  // Simple FSM: after init_done, set full window, then stream all pixels
  typedef enum logic [1:0] {S_IDLE, S_SETW, S_STREAM, S_DONE} s_e;
  s_e s;
  int pixel_cnt;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s <= S_IDLE;
      win_set_stb <= 1'b0;
      stream_start<= 1'b0;
      pix_valid   <= 1'b0;
      pixel_cnt   <= 0;
    end else begin
      win_set_stb  <= 1'b0;
      stream_start <= 1'b0;

      case (s)
        S_IDLE: begin
          if (init_done && start_fill) begin
            // Set full-screen window
            win_x0 <= 16'd0;   win_y0 <= 16'd0;
            win_x1 <= 16'd239; win_y1 <= 16'd319;
            win_set_stb <= 1'b1;
            s <= S_SETW;
          end
        end

        S_SETW: begin
          // Next, start memory write, then stream
          stream_start <= 1'b1;
          pixel_cnt    <= 240*320;
          s            <= S_STREAM;
        end

        S_STREAM: begin
          if (pixel_cnt > 0) begin
            if (pix_ready) begin
              pix_data  <= color_rgb565;
              pix_valid <= 1'b1;
              pixel_cnt <= pixel_cnt - 1;
            end else begin
              pix_valid <= 1'b0;
            end
          end else begin
            pix_valid <= 1'b0;
            s         <= S_DONE;
          end
        end

        S_DONE: begin
          // stay
        end
      endcase
    end
  end

endmodule
