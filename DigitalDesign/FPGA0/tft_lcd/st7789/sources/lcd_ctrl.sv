module lcd_ctrl #(
    parameter int unsigned CLK_HZ = 40_000_000,
    parameter int unsigned LCD_W  = 240,
    parameter int unsigned LCD_H  = 320,
    parameter int unsigned UPDATE_H = 112
)(
    input  logic clk,
    input  logic rst_n,

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

    localparam int unsigned CYCLES_PER_SEC = CLK_HZ;
    localparam logic [8:0] LCD_X_END = LCD_W - 1;
    localparam logic [8:0] LCD_Y_END = LCD_H - 1;
    localparam int unsigned FONT_SCALE = 2;
    localparam int unsigned FONT_W = 5;
    localparam int unsigned FONT_H = 7;
    localparam int unsigned FONT_ADV = (FONT_W + 1) * FONT_SCALE;
    localparam int unsigned FPS_LABEL_X = 88;
    localparam int unsigned FPS_LABEL_Y = 16;
    localparam int unsigned FPS_LABEL_LEN = 3;

    localparam logic [6:0] INIT_LEN = 7'd47;

    typedef enum logic [3:0] {
        ST_RESET_LOW,
        ST_RESET_HIGH_WAIT,
        ST_INIT_FETCH,
        ST_INIT_SEND,
        ST_INIT_WAIT,
        ST_INIT_DELAY,
        ST_WIN_FETCH,
        ST_WIN_SEND,
        ST_WIN_WAIT,
        ST_PIX_HI,
        ST_PIX_HI_WAIT,
        ST_PIX_LO,
        ST_PIX_LO_WAIT
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
    logic [15:0] pixel;
    logic [8:0]  stripe_base_y;
    logic [8:0]  stripe_h;
    logic [8:0]  stripe_y_end;
    logic [1:0]  frame_phase;
    logic        frame_tick;
    logic [31:0] sec_cycle_cnt;
    logic [9:0]  frame_cnt_sec;
    logic [9:0]  fps_value;

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
                2'd0: text_char_fps = 5'd1;  // F
                2'd1: text_char_fps = 5'd2;  // P
                default: text_char_fps = 5'd3; // S
            endcase
        end
    endfunction

    function automatic logic [4:0] glyph_row_bits(input logic [4:0] ch, input logic [2:0] row);
        begin
            glyph_row_bits = 5'b00000;
            case (ch)
                5'd0: glyph_row_bits = 5'b00000; // space
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
                5'd4: begin // O
                    case (row)
                        3'd0: glyph_row_bits = 5'b01110;
                        3'd1: glyph_row_bits = 5'b10001;
                        3'd2: glyph_row_bits = 5'b10001;
                        3'd3: glyph_row_bits = 5'b10001;
                        3'd4: glyph_row_bits = 5'b10001;
                        3'd5: glyph_row_bits = 5'b10001;
                        default: glyph_row_bits = 5'b01110;
                    endcase
                end
                5'd5: begin // L
                    case (row)
                        3'd0: glyph_row_bits = 5'b10000;
                        3'd1: glyph_row_bits = 5'b10000;
                        3'd2: glyph_row_bits = 5'b10000;
                        3'd3: glyph_row_bits = 5'b10000;
                        3'd4: glyph_row_bits = 5'b10000;
                        3'd5: glyph_row_bits = 5'b10000;
                        default: glyph_row_bits = 5'b11111;
                    endcase
                end
                5'd6: begin // D
                    case (row)
                        3'd0: glyph_row_bits = 5'b11110;
                        3'd1: glyph_row_bits = 5'b10001;
                        3'd2: glyph_row_bits = 5'b10001;
                        3'd3: glyph_row_bits = 5'b10001;
                        3'd4: glyph_row_bits = 5'b10001;
                        3'd5: glyph_row_bits = 5'b10001;
                        default: glyph_row_bits = 5'b11110;
                    endcase
                end
                5'd7: begin // K
                    case (row)
                        3'd0: glyph_row_bits = 5'b10001;
                        3'd1: glyph_row_bits = 5'b10010;
                        3'd2: glyph_row_bits = 5'b10100;
                        3'd3: glyph_row_bits = 5'b11000;
                        3'd4: glyph_row_bits = 5'b10100;
                        3'd5: glyph_row_bits = 5'b10010;
                        default: glyph_row_bits = 5'b10001;
                    endcase
                end
                5'd8: begin // A
                    case (row)
                        3'd0: glyph_row_bits = 5'b01110;
                        3'd1: glyph_row_bits = 5'b10001;
                        3'd2: glyph_row_bits = 5'b10001;
                        3'd3: glyph_row_bits = 5'b11111;
                        3'd4: glyph_row_bits = 5'b10001;
                        3'd5: glyph_row_bits = 5'b10001;
                        default: glyph_row_bits = 5'b10001;
                    endcase
                end
                5'd9: begin // B
                    case (row)
                        3'd0: glyph_row_bits = 5'b11110;
                        3'd1: glyph_row_bits = 5'b10001;
                        3'd2: glyph_row_bits = 5'b10001;
                        3'd3: glyph_row_bits = 5'b11110;
                        3'd4: glyph_row_bits = 5'b10001;
                        3'd5: glyph_row_bits = 5'b10001;
                        default: glyph_row_bits = 5'b11110;
                    endcase
                end
                5'd10: begin // U
                    case (row)
                        3'd0: glyph_row_bits = 5'b10001;
                        3'd1: glyph_row_bits = 5'b10001;
                        3'd2: glyph_row_bits = 5'b10001;
                        3'd3: glyph_row_bits = 5'b10001;
                        3'd4: glyph_row_bits = 5'b10001;
                        3'd5: glyph_row_bits = 5'b10001;
                        default: glyph_row_bits = 5'b01110;
                    endcase
                end
                default: glyph_row_bits = 5'b00000;
            endcase
        end
    endfunction

    always_comb begin
        if ((stripe_base_y + UPDATE_H) > LCD_H) begin
            stripe_h = LCD_H - stripe_base_y;
        end else begin
            stripe_h = UPDATE_H[8:0];
        end
    end

    assign stripe_y_end = stripe_base_y + stripe_h - 1'b1;

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
            4'd6:  begin win_dc = 1'b1; win_byte = {7'd0, stripe_base_y[8]}; end
            4'd7:  begin win_dc = 1'b1; win_byte = stripe_base_y[7:0]; end
            4'd8:  begin win_dc = 1'b1; win_byte = {7'd0, stripe_y_end[8]}; end
            4'd9:  begin win_dc = 1'b1; win_byte = stripe_y_end[7:0]; end
            4'd10: begin win_dc = 1'b0; win_byte = 8'h2C; end
            default: begin end
        endcase
    end

    always_comb begin
        logic [3:0] tile_x;
        logic [2:0] tile_y;
        logic [1:0] palette_idx;
        logic [15:0] scene_color;
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
        logic [8:0] draw_y;
        logic [8:0] label_x;
        logic [8:0] label_y;
        logic [1:0] label_idx;
        logic [4:0] glyph_ch;
        logic [4:0] glyph_bits;
        logic [2:0] glyph_row;
        logic [2:0] glyph_col;

        draw_y = stripe_base_y + y_pos;

        // Storyboard-like tiled scene with per-frame phase shift.
        tile_x = x_pos / 9'd40;
        tile_y = draw_y / 9'd40;
        palette_idx = (tile_x + tile_y + frame_phase) % 3;

        // RGB channels swapped (R <-> B).
        case (palette_idx)
            2'd0: scene_color = 16'h001F; // Blue instead of Red
            2'd1: scene_color = 16'h07E0; // Green unchanged
            default: scene_color = 16'hF800; // Red instead of Blue
        endcase

        pixel = scene_color;

        // Thin black grid to make frame segmentation visible.
        if ((x_pos % 9'd40) == 0 || (draw_y % 9'd40) == 0) begin
            pixel = 16'h0000;
        end

        // FPS overlay area (white background, black digits).
        if ((x_pos >= 9'd8) && (x_pos < 9'd132) && (draw_y >= 9'd8) && (draw_y < 9'd42)) begin
            pixel = 16'hFFFF;

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

                if (seg[6] && (dy < 6'd3) && (dx >= 6'd3) && (dx < 6'd19)) seg_on = 1'b1;     // a
                if (seg[5] && (dx >= 6'd19) && (dy >= 6'd3) && (dy < 6'd13)) seg_on = 1'b1;   // b
                if (seg[4] && (dx >= 6'd19) && (dy >= 6'd13) && (dy < 6'd23)) seg_on = 1'b1;  // c
                if (seg[3] && (dy >= 6'd23) && (dx >= 6'd3) && (dx < 6'd19)) seg_on = 1'b1;   // d
                if (seg[2] && (dx < 6'd3) && (dy >= 6'd13) && (dy < 6'd23)) seg_on = 1'b1;    // e
                if (seg[1] && (dx < 6'd3) && (dy >= 6'd3) && (dy < 6'd13)) seg_on = 1'b1;     // f
                if (seg[0] && (dy >= 6'd11) && (dy < 6'd14) && (dx >= 6'd3) && (dx < 6'd19)) seg_on = 1'b1; // g

                if (seg_on) begin
                    pixel = 16'h0000;
                end
            end

            // FPS text label on the right side of numeric value.
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
                        pixel = 16'h0000;
                    end
                end
            end
        end

    end

    always_comb begin
        init_is_delay = 1'b0;
        init_dc       = 1'b0;
        init_byte     = 8'h00;
        init_delay_ms = 8'd0;

        case (init_idx)
            // SWRESET + mandatory delay 
            7'd0: begin init_dc = 1'b0; init_byte = 8'h01; end
            7'd1: begin init_is_delay = 1'b1; init_delay_ms = 8'd120; end

            // Exit sleep + settle delay 
            7'd2: begin init_dc = 1'b0; init_byte = 8'h11; end
            7'd3: begin init_is_delay = 1'b1; init_delay_ms = 8'd120; end

            // Interface and address control
            7'd4: begin init_dc = 1'b0; init_byte = 8'h3A; end // COLMOD
            7'd5: begin init_dc = 1'b1; init_byte = 8'h55; end // 16bpp MCU
            7'd6: begin init_dc = 1'b0; init_byte = 8'h36; end // MADCTL
            7'd7: begin init_dc = 1'b1; init_byte = 8'h00; end // MY=MX=MV=0

            // default analog/system settings
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

            // Display mode and enable
            7'd32: begin init_dc = 1'b0; init_byte = 8'h13; end // NORON
            7'd33: begin init_dc = 1'b0; init_byte = 8'h21; end // INVON
            7'd34: begin init_dc = 1'b0; init_byte = 8'h29; end // DISPON
            7'd35: begin init_is_delay = 1'b1; init_delay_ms = 8'd20; end

            // Programmable frame window, then RAMWR
            7'd36: begin init_dc = 1'b0; init_byte = 8'h2A; end
            7'd37: begin init_dc = 1'b1; init_byte = 8'h00; end
            7'd38: begin init_dc = 1'b1; init_byte = 8'h00; end
            7'd39: begin init_dc = 1'b1; init_byte = {7'd0, LCD_X_END[8]}; end
            7'd40: begin init_dc = 1'b1; init_byte = LCD_X_END[7:0]; end

            7'd41: begin init_dc = 1'b0; init_byte = 8'h2B; end
            7'd42: begin init_dc = 1'b1; init_byte = 8'h00; end
            7'd43: begin init_dc = 1'b1; init_byte = 8'h00; end
            7'd44: begin init_dc = 1'b1; init_byte = {7'd0, LCD_Y_END[8]}; end
            7'd45: begin init_dc = 1'b1; init_byte = LCD_Y_END[7:0]; end

            7'd46: begin init_dc = 1'b0; init_byte = 8'h2C; end

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
            stripe_base_y <= 9'd0;
            frame_phase  <= 2'd0;
            frame_tick   <= 1'b0;
            sec_cycle_cnt <= 32'd0;
            frame_cnt_sec <= 10'd0;
            fps_value     <= 10'd0;
            win_idx       <= 4'd0;
        end else begin
            spi_start <= 1'b0;
            lcd_blk   <= 1'b1;
            frame_tick <= 1'b0;

            if (sec_cycle_cnt == (CYCLES_PER_SEC - 1)) begin
                sec_cycle_cnt <= 32'd0;
                if (frame_tick) begin
                    if (frame_cnt_sec == 10'd999) begin
                        fps_value <= 10'd999;
                    end else begin
                        fps_value <= frame_cnt_sec + 1'b1;
                    end
                end else begin
                    fps_value <= frame_cnt_sec;
                end
                frame_cnt_sec <= 10'd0;
            end else begin
                sec_cycle_cnt <= sec_cycle_cnt + 1'b1;
                if (frame_tick) begin
                    if (frame_cnt_sec != 10'd999) begin
                        frame_cnt_sec <= frame_cnt_sec + 1'b1;
                    end
                end
            end

            if (frame_tick) begin
                frame_phase <= frame_phase + 1'b1;
            end

            case (state)
                ST_RESET_LOW: begin
                    lcd_cs  <= 1'b1;
                    lcd_dc  <= 1'b0;
                    lcd_res <= 1'b0;
                    if (delay_cnt != 0) begin
                        delay_cnt <= delay_cnt - 1;
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
                        delay_cnt <= delay_cnt - 1;
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
                        x_pos <= 9'd0;
                        y_pos <= 9'd0;
                        stripe_base_y <= 9'd0;
                        win_idx <= 4'd0;
                        state <= ST_WIN_FETCH;
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

                ST_WIN_FETCH: begin
                    lcd_cs <= 1'b1;
                    lcd_dc <= 1'b0;
                    if (win_idx == 4'd11) begin
                        x_pos <= 9'd0;
                        y_pos <= 9'd0;
                        state <= ST_PIX_HI;
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

                ST_PIX_HI: begin
                    lcd_cs <= 1'b0;
                    lcd_dc <= 1'b1;
                    if (!spi_busy) begin
                        spi_data  <= pixel[15:8];
                        spi_start <= 1'b1;
                        state     <= ST_PIX_HI_WAIT;
                    end
                end

                ST_PIX_HI_WAIT: begin
                    lcd_cs <= 1'b0;
                    lcd_dc <= 1'b1;
                    if (spi_done) begin
                        state <= ST_PIX_LO;
                    end
                end

                ST_PIX_LO: begin
                    lcd_cs <= 1'b0;
                    lcd_dc <= 1'b1;
                    if (!spi_busy) begin
                        spi_data  <= pixel[7:0];
                        spi_start <= 1'b1;
                        state     <= ST_PIX_LO_WAIT;
                    end
                end

                ST_PIX_LO_WAIT: begin
                    lcd_cs <= 1'b0;
                    lcd_dc <= 1'b1;
                    if (spi_done) begin
                        if (x_pos == (LCD_W - 1)) begin
                            x_pos <= 9'd0;
                            if (y_pos == (stripe_h - 1'b1)) begin
                                y_pos <= 9'd0;
                                frame_tick <= 1'b1;
                                if ((stripe_base_y + stripe_h) >= LCD_H) begin
                                    stripe_base_y <= 9'd0;
                                end else begin
                                    stripe_base_y <= stripe_base_y + stripe_h;
                                end
                                win_idx <= 4'd0;
                                state <= ST_WIN_FETCH;
                            end else begin
                                y_pos <= y_pos + 1'b1;
                                state <= ST_PIX_HI;
                            end
                        end else begin
                            x_pos <= x_pos + 1'b1;
                            state <= ST_PIX_HI;
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
