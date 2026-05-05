module lcd_ctrl #(
    parameter int unsigned CLK_HZ = 40_000_000
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

    localparam logic [8:0] LCD_W = 9'd240;
    localparam logic [8:0] LCD_H = 9'd320;

    localparam logic [6:0] INIT_LEN = 7'd47;

    typedef enum logic [3:0] {
        ST_RESET_LOW,
        ST_RESET_HIGH_WAIT,
        ST_INIT_FETCH,
        ST_INIT_SEND,
        ST_INIT_WAIT,
        ST_INIT_DELAY,
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

    logic [8:0]  x_pos;
    logic [8:0]  y_pos;
    logic [15:0] pixel;

    always_comb begin
        if (x_pos < 9'd80) begin
            pixel = 16'hF800;
        end else if (x_pos < 9'd160) begin
            pixel = 16'h07E0;
        end else begin
            pixel = 16'h001F;
        end
    end

    always_comb begin
        init_is_delay = 1'b0;
        init_dc       = 1'b0;
        init_byte     = 8'h00;
        init_delay_ms = 8'd0;

        case (init_idx)
            // SWRESET + mandatory delay (datasheet 9.1.2)
            7'd0: begin init_dc = 1'b0; init_byte = 8'h01; end
            7'd1: begin init_is_delay = 1'b1; init_delay_ms = 8'd120; end

            // Exit sleep + settle delay (datasheet 9.1.12)
            7'd2: begin init_dc = 1'b0; init_byte = 8'h11; end
            7'd3: begin init_is_delay = 1'b1; init_delay_ms = 8'd120; end

            // Interface and address control
            7'd4: begin init_dc = 1'b0; init_byte = 8'h3A; end // COLMOD
            7'd5: begin init_dc = 1'b1; init_byte = 8'h55; end // 16bpp MCU
            7'd6: begin init_dc = 1'b0; init_byte = 8'h36; end // MADCTL
            7'd7: begin init_dc = 1'b1; init_byte = 8'h00; end // MY=MX=MV=0

            // Datasheet default analog/system settings (chapter 9.2)
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

            // Full frame window 240x320, then RAMWR
            7'd36: begin init_dc = 1'b0; init_byte = 8'h2A; end
            7'd37: begin init_dc = 1'b1; init_byte = 8'h00; end
            7'd38: begin init_dc = 1'b1; init_byte = 8'h00; end
            7'd39: begin init_dc = 1'b1; init_byte = 8'h00; end
            7'd40: begin init_dc = 1'b1; init_byte = 8'hEF; end

            7'd41: begin init_dc = 1'b0; init_byte = 8'h2B; end
            7'd42: begin init_dc = 1'b1; init_byte = 8'h00; end
            7'd43: begin init_dc = 1'b1; init_byte = 8'h00; end
            7'd44: begin init_dc = 1'b1; init_byte = 8'h01; end
            7'd45: begin init_dc = 1'b1; init_byte = 8'h3F; end

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
        end else begin
            spi_start <= 1'b0;
            lcd_blk   <= 1'b1;

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
                        state <= ST_PIX_HI;
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
                            if (y_pos == (LCD_H - 1)) begin
                                y_pos <= 9'd0;
                            end else begin
                                y_pos <= y_pos + 1'b1;
                            end
                        end else begin
                            x_pos <= x_pos + 1'b1;
                        end
                        state <= ST_PIX_HI;
                    end
                end

                default: begin
                    state <= ST_RESET_LOW;
                end
            endcase
        end
    end

endmodule
