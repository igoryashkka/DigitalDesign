module lcd_ctrl (
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

    typedef enum logic [3:0] {
        RESET,
        INIT1,
        INIT2,
        INIT3,
        INIT4,
        INIT5,
        SET_WINDOW,
        WRITE_RAM,
        STREAM_HI,
        STREAM_LO
    } state_t;

    state_t state;

    logic [15:0] pixel;
    logic [23:0] color_cnt;

    // =============================
    // COLOR GENERATOR (RGB cycling)
    // =============================
    always_ff @(posedge clk) begin
        color_cnt <= color_cnt + 1;

        case (color_cnt[23:22])
            2'b00: pixel <= 16'hF800; // RED
            2'b01: pixel <= 16'h07E0; // GREEN
            2'b10: pixel <= 16'h001F; // BLUE
            default: pixel <= 16'hFFFF; // WHITE
        endcase
    end

    // =============================
    // CONTROL FSM
    // =============================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= RESET;
            lcd_res <= 0;
            lcd_blk <= 1;
            lcd_cs  <= 1;
            spi_start <= 0;
        end else begin
            spi_start <= 0;

            case (state)

                RESET: begin
                    lcd_res <= 1;
                    state <= INIT1;
                end

                INIT1: begin
                    // Sleep out (0x11)
                    lcd_cs <= 0;
                    lcd_dc <= 0;
                    spi_data <= 8'h11;
                    spi_start <= 1;
                    state <= INIT2;
                end

                INIT2: if (spi_done) begin
                    // COLMOD (0x3A)
                    lcd_dc <= 0;
                    spi_data <= 8'h3A;
                    spi_start <= 1;
                    state <= INIT3;
                end

                INIT3: if (spi_done) begin
                    lcd_dc <= 1;
                    spi_data <= 8'h55; // 16-bit
                    spi_start <= 1;
                    state <= INIT4;
                end

                INIT4: if (spi_done) begin
                    // Display ON (0x29)
                    lcd_dc <= 0;
                    spi_data <= 8'h29;
                    spi_start <= 1;
                    state <= INIT5;
                end

                INIT5: if (spi_done) begin
                    state <= WRITE_RAM;
                end

                WRITE_RAM: begin
                    // RAM write (0x2C)
                    lcd_dc <= 0;
                    spi_data <= 8'h2C;
                    spi_start <= 1;
                    state <= STREAM_HI;
                end

                STREAM_HI: if (!spi_busy) begin
                    lcd_dc <= 1;

                    // send pixel high byte
                    spi_data <= pixel[15:8];
                    spi_start <= 1;
                    state <= STREAM_LO;
                end

                STREAM_LO: if (spi_done) begin
                    spi_data <= pixel[7:0];
                    spi_start <= 1;
                    state <= STREAM_HI;
                end

            endcase
        end
    end

endmodule