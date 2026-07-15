module lcd_uart_ctrl #(
    parameter int unsigned CLK_HZ    = 40_000_000,
    parameter int unsigned UART_BAUD = 921_600,
    parameter int unsigned LCD_W     = 320,
    parameter int unsigned LCD_H     = 240,
    parameter int unsigned STRIPE_H  = 4
)(
    input  logic clk,
    input  logic rst_n,
    input  logic uart_rx_i,

    output logic [7:0] spi_data,
    output logic       spi_start,
    input  logic       spi_busy,
    input  logic       spi_done,

    output logic lcd_cs,
    output logic lcd_dc,
    output logic lcd_res,
    output logic lcd_blk
);

    localparam int unsigned CYCLES_PER_MS       = CLK_HZ / 1000;
    localparam int unsigned T_RESET_LOW_CYCLES  = 20  * CYCLES_PER_MS;
    localparam int unsigned T_RESET_HIGH_CYCLES = 120 * CYCLES_PER_MS;
    localparam int unsigned CYCLES_PER_SEC      = CLK_HZ;
    localparam int unsigned FONT_SCALE          = 2;
    localparam int unsigned FONT_W              = 5;
    localparam int unsigned FONT_H              = 7;
    localparam int unsigned FONT_ADV            = (FONT_W + 1) * FONT_SCALE;
    localparam int unsigned FPS_LABEL_X         = 88;
    localparam int unsigned FPS_LABEL_Y         = 16;
    localparam int unsigned FPS_LABEL_LEN       = 3;

    localparam logic [8:0] LCD_X_END = LCD_W - 1;
    localparam logic [6:0] INIT_LEN = 7'd47;

    localparam logic [7:0] SOF0 = 8'h55;
    localparam logic [7:0] SOF1 = 8'hAA;
    localparam logic [7:0] SOF2 = 8'h5A;
    localparam logic [7:0] SOF3 = 8'hA5;

    typedef enum logic [4:0] {
        ST_RESET_LOW,
        ST_RESET_HIGH_WAIT,
        ST_INIT_FETCH,
        ST_INIT_SEND,
        ST_INIT_WAIT,
        ST_INIT_DELAY,
        ST_WAIT_SOF,
        ST_WAIT_Y_HI,
        ST_WAIT_Y_LO,
        ST_WIN_FETCH,
        ST_WIN_SEND,
        ST_WIN_WAIT,
        ST_PIX_HI_WAIT,
        ST_PIX_HI_SEND,
        ST_PIX_HI_DONE,
        ST_PIX_LO_WAIT,
        ST_PIX_LO_SEND,
        ST_PIX_LO_DONE
    } state_t;

    state_t state;

    logic [31:0] delay_cnt;
    logic [6:0]  init_idx;

    logic        init_is_delay;
    logic        init_dc;
    logic [7:0]  init_byte;
    logic [7:0]  init_delay_ms;

    logic        win_dc;
    logic [7:0]  win_byte;
    logic [3:0]  win_idx;

    logic [8:0]  x_pos;
    logic [8:0]  y_pos;
    logic [7:0]  pix_hi;
    logic [7:0]  pix_lo;

    logic [7:0]  uart_data;
    logic        uart_valid;
    logic [1:0]  sof_idx;

    logic [8:0]  y_start;
    logic [8:0]  stripe_h_cur;
    logic [8:0]  y_end;
    logic [31:0] sec_cycle_cnt;
    logic [9:0]  stripe_cnt_sec;
    logic [9:0]  fps_value;

    logic [8:0]  draw_y;
    logic        fps_ovl_on;
    logic [15:0] fps_ovl_color;

    function automatic logic [6:0] seg_map(input logic [3:0] d);
        begin
            case (d)
                4'd0: seg_map = 7'b1111110;
                4'd1: seg_map = 7'b0110000;
                4'd2: seg_map = 7'b1101101;
                4'd3: seg_map = 7'b1111001;
                4'd4: seg_map = 7'b0110011;
                4'd5: seg_map = 7'b1011011;
                4'd6: seg_map = 7'b1011111;
                4'd7: seg_map = 7'b1110000;
                4'd8: seg_map = 7'b1111111;
                4'd9: seg_map = 7'b1111011;
                default: seg_map = 7'b0000001;
            endcase
        end
    endfunction

    function automatic logic [4:0] text_char_fps(input logic [1:0] idx);
        begin
            case (idx)
                2'd0: text_char_fps = 5'd1;
                2'd1: text_char_fps = 5'd2;
                default: text_char_fps = 5'd3;
            endcase
        end
    endfunction

    function automatic logic [4:0] glyph_row_bits(input logic [4:0] ch, input logic [2:0] row);
        begin
            glyph_row_bits = 5'b00000;
            case (ch)
                5'd1: begin // F
                    case (row)
                        3'd0: glyph_row_bits = 5'b11111;
                        3'd1: glyph_row_bits = 5'b10000;
                        3'd2: glyph_row_bits = 5'b10000;
                        3'd3: glyph_row_bits = 5'b11110;
                        3'd4: glyph_row_bits = 5'b10000;
                        3'd5: glyph_row_bits = 5'b10000;
                        default: glyph_row_bits = 5'b10000;
                    endcase
                end
                5'd2: begin // P
                    case (row)
                        3'd0: glyph_row_bits = 5'b11110;
                        3'd1: glyph_row_bits = 5'b10001;
                        3'd2: glyph_row_bits = 5'b10001;
                        3'd3: glyph_row_bits = 5'b11110;
                        3'd4: glyph_row_bits = 5'b10000;
                        3'd5: glyph_row_bits = 5'b10000;
                        default: glyph_row_bits = 5'b10000;
                    endcase
                end
                5'd3: begin // S
                    case (row)
                        3'd0: glyph_row_bits = 5'b01111;
                        3'd1: glyph_row_bits = 5'b10000;
                        3'd2: glyph_row_bits = 5'b10000;
                        3'd3: glyph_row_bits = 5'b01110;
                        3'd4: glyph_row_bits = 5'b00001;
                        3'd5: glyph_row_bits = 5'b00001;
                        default: glyph_row_bits = 5'b11110;
                    endcase
                end
                default: glyph_row_bits = 5'b00000;
            endcase
        end
    endfunction

    uart_rx #(
        .CLK_HZ(CLK_HZ),
        .BAUD(UART_BAUD)
    ) uart_rx_i0 (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx_i),
        .data(uart_data),
        .valid(uart_valid)
    );

    always_comb begin
        if ((y_start + STRIPE_H) > LCD_H) begin
            stripe_h_cur = LCD_H - y_start;
        end else begin
            stripe_h_cur = STRIPE_H[8:0];
        end
    end

    assign y_end = y_start + stripe_h_cur - 1'b1;
    assign draw_y = y_start + y_pos;

    always_comb begin
        logic [9:0] fps_hundreds;
        logic [9:0] fps_tens;
        logic [9:0] fps_ones;
        logic [8:0] fps_x;
        logic [8:0] fps_y;
        logic [3:0] digit;
        logic [6:0] seg;
        logic [5:0] dx;
        logic [5:0] dy;
        logic       seg_on;
        logic [8:0] label_x;
        logic [8:0] label_y;
        logic [1:0] label_idx;
        logic [4:0] glyph_ch;
        logic [4:0] glyph_bits;
        logic [2:0] glyph_row;
        logic [2:0] glyph_col;

        fps_ovl_on    = 1'b0;
        fps_ovl_color = 16'h0000;

        if ((x_pos >= 9'd8) && (x_pos < 9'd132) && (draw_y >= 9'd8) && (draw_y < 9'd42)) begin
            fps_ovl_on    = 1'b1;
            fps_ovl_color = 16'hFFFF;

            fps_hundreds = (fps_value / 10'd100) % 10;
            fps_tens     = (fps_value / 10'd10) % 10;
            fps_ones     = fps_value % 10;

            if ((x_pos >= 9'd12) && (x_pos < 9'd84) && (draw_y >= 9'd12) && (draw_y < 9'd38)) begin
                fps_x = x_pos - 9'd12;
                fps_y = draw_y - 9'd12;

                if (fps_x < 9'd22) begin
                    digit = fps_hundreds[3:0];
                    dx    = fps_x[5:0];
                    dy    = fps_y[5:0];
                end else if (fps_x < 9'd46) begin
                    digit = fps_tens[3:0];
                    dx    = fps_x - 9'd24;
                    dy    = fps_y[5:0];
                end else begin
                    digit = fps_ones[3:0];
                    dx    = fps_x - 9'd48;
                    dy    = fps_y[5:0];
                end

                seg    = seg_map(digit);
                seg_on = 1'b0;

                if (seg[6] && (dy < 6'd3) && (dx >= 6'd3) && (dx < 6'd19)) seg_on = 1'b1;
                if (seg[5] && (dx >= 6'd19) && (dy >= 6'd3) && (dy < 6'd13)) seg_on = 1'b1;
                if (seg[4] && (dx >= 6'd19) && (dy >= 6'd13) && (dy < 6'd23)) seg_on = 1'b1;
                if (seg[3] && (dy >= 6'd23) && (dx >= 6'd3) && (dx < 6'd19)) seg_on = 1'b1;
                if (seg[2] && (dx < 6'd3) && (dy >= 6'd13) && (dy < 6'd23)) seg_on = 1'b1;
                if (seg[1] && (dx < 6'd3) && (dy >= 6'd3) && (dy < 6'd13)) seg_on = 1'b1;
                if (seg[0] && (dy >= 6'd11) && (dy < 6'd14) && (dx >= 6'd3) && (dx < 6'd19)) seg_on = 1'b1;

                if (seg_on) begin
                    fps_ovl_color = 16'h0000;
                end
            end

            if ((x_pos >= FPS_LABEL_X) && (x_pos < (FPS_LABEL_X + FPS_LABEL_LEN * FONT_ADV)) &&
                (draw_y >= FPS_LABEL_Y) && (draw_y < (FPS_LABEL_Y + FONT_H * FONT_SCALE))) begin
                label_x = x_pos - FPS_LABEL_X;
                label_y = draw_y - FPS_LABEL_Y;
                label_idx = label_x / FONT_ADV;
                glyph_row = label_y / FONT_SCALE;
                glyph_col = (label_x % FONT_ADV) / FONT_SCALE;

                if ((glyph_col < FONT_W) && (glyph_row < FONT_H)) begin
                    glyph_ch = text_char_fps(label_idx);
                    glyph_bits = glyph_row_bits(glyph_ch, glyph_row);
                    if (glyph_bits[FONT_W - 1 - glyph_col]) begin
                        fps_ovl_color = 16'h0000;
                    end
                end
            end
        end
    end

    always_comb begin
        win_dc   = 1'b0;
        win_byte = 8'h00;

        case (win_idx)
            4'd0:  begin win_dc = 1'b0; win_byte = 8'h2A; end
            4'd1:  begin win_dc = 1'b1; win_byte = 8'h00; end
            4'd2:  begin win_dc = 1'b1; win_byte = 8'h00; end
            4'd3:  begin win_dc = 1'b1; win_byte = {7'd0, LCD_X_END[8]}; end
            4'd4:  begin win_dc = 1'b1; win_byte = LCD_X_END[7:0]; end
            4'd5:  begin win_dc = 1'b0; win_byte = 8'h2B; end
            4'd6:  begin win_dc = 1'b1; win_byte = {7'd0, y_start[8]}; end
            4'd7:  begin win_dc = 1'b1; win_byte = y_start[7:0]; end
            4'd8:  begin win_dc = 1'b1; win_byte = {7'd0, y_end[8]}; end
            4'd9:  begin win_dc = 1'b1; win_byte = y_end[7:0]; end
            4'd10: begin win_dc = 1'b0; win_byte = 8'h2C; end
            default: begin end
        endcase
    end

    always_comb begin
        init_is_delay = 1'b0;
        init_dc       = 1'b0;
        init_byte     = 8'h00;
        init_delay_ms = 8'd0;

        case (init_idx)
            7'd0: begin init_dc = 1'b0; init_byte = 8'h01; end
            7'd1: begin init_is_delay = 1'b1; init_delay_ms = 8'd120; end
            7'd2: begin init_dc = 1'b0; init_byte = 8'h11; end
            7'd3: begin init_is_delay = 1'b1; init_delay_ms = 8'd120; end
            7'd4: begin init_dc = 1'b0; init_byte = 8'h3A; end
            7'd5: begin init_dc = 1'b1; init_byte = 8'h55; end
            7'd6: begin init_dc = 1'b0; init_byte = 8'h36; end
            7'd7: begin init_dc = 1'b1; init_byte = 8'h60; end

            7'd8:  begin init_dc = 1'b0; init_byte = 8'hB2; end
            7'd9:  begin init_dc = 1'b1; init_byte = 8'h0C; end
            7'd10: begin init_dc = 1'b1; init_byte = 8'h0C; end
            7'd11: begin init_dc = 1'b1; init_byte = 8'h00; end
            7'd12: begin init_dc = 1'b1; init_byte = 8'h33; end
            7'd13: begin init_dc = 1'b1; init_byte = 8'h33; end
            7'd14: begin init_dc = 1'b0; init_byte = 8'hB7; end
            7'd15: begin init_dc = 1'b1; init_byte = 8'h35; end
            7'd16: begin init_dc = 1'b0; init_byte = 8'hBB; end
            7'd17: begin init_dc = 1'b1; init_byte = 8'h20; end
            7'd18: begin init_dc = 1'b0; init_byte = 8'hC0; end
            7'd19: begin init_dc = 1'b1; init_byte = 8'h2C; end
            7'd20: begin init_dc = 1'b0; init_byte = 8'hC2; end
            7'd21: begin init_dc = 1'b1; init_byte = 8'h01; end
            7'd22: begin init_dc = 1'b1; init_byte = 8'hFF; end
            7'd23: begin init_dc = 1'b0; init_byte = 8'hC3; end
            7'd24: begin init_dc = 1'b1; init_byte = 8'h0B; end
            7'd25: begin init_dc = 1'b0; init_byte = 8'hC4; end
            7'd26: begin init_dc = 1'b1; init_byte = 8'h20; end
            7'd27: begin init_dc = 1'b0; init_byte = 8'hC6; end
            7'd28: begin init_dc = 1'b1; init_byte = 8'h0F; end
            7'd29: begin init_dc = 1'b0; init_byte = 8'hD0; end
            7'd30: begin init_dc = 1'b1; init_byte = 8'hA4; end
            7'd31: begin init_dc = 1'b1; init_byte = 8'hA1; end
            7'd32: begin init_dc = 1'b0; init_byte = 8'h13; end
            7'd33: begin init_dc = 1'b0; init_byte = 8'h21; end
            7'd34: begin init_dc = 1'b0; init_byte = 8'h29; end
            7'd35: begin init_is_delay = 1'b1; init_delay_ms = 8'd20; end

            default: begin end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= ST_RESET_LOW;
            delay_cnt <= T_RESET_LOW_CYCLES;
            init_idx  <= 7'd0;

            lcd_cs    <= 1'b1;
            lcd_dc    <= 1'b0;
            lcd_res   <= 1'b0;
            lcd_blk   <= 1'b1;

            spi_data  <= 8'h00;
            spi_start <= 1'b0;

            x_pos     <= 9'd0;
            y_pos     <= 9'd0;
            pix_hi    <= 8'h00;
            pix_lo    <= 8'h00;
            sof_idx   <= 2'd0;
            y_start   <= 9'd0;
            win_idx   <= 4'd0;
            sec_cycle_cnt <= 32'd0;
            stripe_cnt_sec <= 10'd0;
            fps_value      <= 10'd0;
        end else begin
            spi_start <= 1'b0;
            lcd_blk   <= 1'b1;

            if (sec_cycle_cnt == (CYCLES_PER_SEC - 1)) begin
                sec_cycle_cnt <= 32'd0;
                fps_value     <= stripe_cnt_sec;
                stripe_cnt_sec <= 10'd0;
            end else begin
                sec_cycle_cnt <= sec_cycle_cnt + 1'b1;
            end

            case (state)
                ST_RESET_LOW: begin
                    lcd_cs  <= 1'b1;
                    lcd_dc  <= 1'b0;
                    lcd_res <= 1'b0;
                    if (delay_cnt != 0) begin
                        delay_cnt <= delay_cnt - 1'b1;
                    end else begin
                        lcd_res   <= 1'b1;
                        delay_cnt <= T_RESET_HIGH_CYCLES;
                        state     <= ST_RESET_HIGH_WAIT;
                    end
                end

                ST_RESET_HIGH_WAIT: begin
                    lcd_cs  <= 1'b1;
                    lcd_dc  <= 1'b0;
                    lcd_res <= 1'b1;
                    if (delay_cnt != 0) begin
                        delay_cnt <= delay_cnt - 1'b1;
                    end else begin
                        init_idx <= 7'd0;
                        state    <= ST_INIT_FETCH;
                    end
                end

                ST_INIT_FETCH: begin
                    lcd_cs  <= 1'b1;
                    lcd_dc  <= 1'b0;
                    lcd_res <= 1'b1;

                    if (init_idx == INIT_LEN) begin
                        sof_idx <= 2'd0;
                        state   <= ST_WAIT_SOF;
                    end else if (init_is_delay) begin
                        delay_cnt <= init_delay_ms * CYCLES_PER_MS;
                        state     <= ST_INIT_DELAY;
                    end else begin
                        state <= ST_INIT_SEND;
                    end
                end

                ST_INIT_SEND: begin
                    lcd_cs <= 1'b0;
                    lcd_dc <= init_dc;
                    if (!spi_busy) begin
                        spi_data  <= init_byte;
                        spi_start <= 1'b1;
                        state     <= ST_INIT_WAIT;
                    end
                end

                ST_INIT_WAIT: begin
                    lcd_cs <= 1'b0;
                    lcd_dc <= init_dc;
                    if (spi_done) begin
                        init_idx <= init_idx + 1'b1;
                        state    <= ST_INIT_FETCH;
                    end
                end

                ST_INIT_DELAY: begin
                    lcd_cs <= 1'b1;
                    lcd_dc <= 1'b0;
                    if (delay_cnt != 0) begin
                        delay_cnt <= delay_cnt - 1'b1;
                    end else begin
                        init_idx <= init_idx + 1'b1;
                        state    <= ST_INIT_FETCH;
                    end
                end

                ST_WAIT_SOF: begin
                    lcd_cs <= 1'b1;
                    lcd_dc <= 1'b0;
                    if (uart_valid) begin
                        case (sof_idx)
                            2'd0: sof_idx <= (uart_data == SOF0) ? 2'd1 : 2'd0;
                            2'd1: sof_idx <= (uart_data == SOF1) ? 2'd2 : ((uart_data == SOF0) ? 2'd1 : 2'd0);
                            2'd2: sof_idx <= (uart_data == SOF2) ? 2'd3 : ((uart_data == SOF0) ? 2'd1 : 2'd0);
                            default: begin
                                if (uart_data == SOF3) begin
                                    state <= ST_WAIT_Y_HI;
                                end
                                sof_idx <= (uart_data == SOF0) ? 2'd1 : 2'd0;
                            end
                        endcase
                    end
                end

                ST_WAIT_Y_HI: begin
                    if (uart_valid) begin
                        y_start[8] <= uart_data[0];
                        state      <= ST_WAIT_Y_LO;
                    end
                end

                ST_WAIT_Y_LO: begin
                    if (uart_valid) begin
                        y_start[7:0] <= uart_data;
                        if ({y_start[8], uart_data} < LCD_H) begin
                            x_pos   <= 9'd0;
                            y_pos   <= 9'd0;
                            win_idx <= 4'd0;
                            state   <= ST_WIN_FETCH;
                        end else begin
                            sof_idx <= 2'd0;
                            state   <= ST_WAIT_SOF;
                        end
                    end
                end

                ST_WIN_FETCH: begin
                    lcd_cs <= 1'b1;
                    lcd_dc <= 1'b0;
                    if (win_idx == 4'd11) begin
                        state <= ST_PIX_HI_WAIT;
                    end else begin
                        state <= ST_WIN_SEND;
                    end
                end

                ST_WIN_SEND: begin
                    lcd_cs <= 1'b0;
                    lcd_dc <= win_dc;
                    if (!spi_busy) begin
                        spi_data  <= win_byte;
                        spi_start <= 1'b1;
                        state     <= ST_WIN_WAIT;
                    end
                end

                ST_WIN_WAIT: begin
                    lcd_cs <= 1'b0;
                    lcd_dc <= win_dc;
                    if (spi_done) begin
                        win_idx <= win_idx + 1'b1;
                        state   <= ST_WIN_FETCH;
                    end
                end

                ST_PIX_HI_WAIT: begin
                    lcd_cs <= 1'b0;
                    lcd_dc <= 1'b1;
                    if (uart_valid) begin
                        pix_hi <= uart_data;
                        state  <= ST_PIX_HI_SEND;
                    end
                end

                ST_PIX_HI_SEND: begin
                    lcd_cs <= 1'b0;
                    lcd_dc <= 1'b1;
                    if (!spi_busy) begin
                        if (fps_ovl_on) begin
                            spi_data <= fps_ovl_color[15:8];
                        end else begin
                            spi_data <= pix_hi;
                        end
                        spi_start <= 1'b1;
                        state     <= ST_PIX_HI_DONE;
                    end
                end

                ST_PIX_HI_DONE: begin
                    lcd_cs <= 1'b0;
                    lcd_dc <= 1'b1;
                    if (spi_done) begin
                        state <= ST_PIX_LO_WAIT;
                    end
                end

                ST_PIX_LO_WAIT: begin
                    lcd_cs <= 1'b0;
                    lcd_dc <= 1'b1;
                    if (uart_valid) begin
                        pix_lo <= uart_data;
                        state  <= ST_PIX_LO_SEND;
                    end
                end

                ST_PIX_LO_SEND: begin
                    lcd_cs <= 1'b0;
                    lcd_dc <= 1'b1;
                    if (!spi_busy) begin
                        if (fps_ovl_on) begin
                            spi_data <= fps_ovl_color[7:0];
                        end else begin
                            spi_data <= pix_lo;
                        end
                        spi_start <= 1'b1;
                        state     <= ST_PIX_LO_DONE;
                    end
                end

                ST_PIX_LO_DONE: begin
                    lcd_cs <= 1'b0;
                    lcd_dc <= 1'b1;
                    if (spi_done) begin
                        if (x_pos == (LCD_W - 1)) begin
                            x_pos <= 9'd0;
                            if (y_pos == (stripe_h_cur - 1'b1)) begin
                                if (stripe_cnt_sec != 10'd999) begin
                                    stripe_cnt_sec <= stripe_cnt_sec + 1'b1;
                                end
                                sof_idx <= 2'd0;
                                state   <= ST_WAIT_SOF;
                            end else begin
                                y_pos <= y_pos + 1'b1;
                                state <= ST_PIX_HI_WAIT;
                            end
                        end else begin
                            x_pos <= x_pos + 1'b1;
                            state <= ST_PIX_HI_WAIT;
                        end
                    end
                end

                default: begin
                    state <= ST_RESET_LOW;
                end
            endcase
        end
    end

endmodule
