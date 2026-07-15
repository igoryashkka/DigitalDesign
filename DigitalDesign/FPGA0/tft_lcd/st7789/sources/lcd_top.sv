module lcd_top (
    input  logic clk_200_p,
    input  logic clk_200_n,
    input  logic rst_n,
    input  logic uart_rx,
    output logic uart_tx,

    output logic lcd_scl,
    output logic lcd_sda,
    output logic lcd_cs,
    output logic lcd_dc,
    output logic lcd_res,
    output logic lcd_blk
);

    // =============================
    // PARAMETERS
    // =============================
    parameter int unsigned CLK_HZ     = 40_000_000;
    parameter int unsigned PANEL_W    = 320;
    parameter int unsigned PANEL_H    = 240;
    parameter int unsigned STRIPE_H   = 4;
    parameter int unsigned UART_BAUD  = 2_000_000;
    parameter int unsigned TARGET_FPS = 30;

    localparam int unsigned BPP = 16;
    localparam int unsigned SPI_REQ_HZ    = PANEL_W * PANEL_H * BPP * TARGET_FPS;
    localparam int unsigned SPI_MAX_HW_HZ = CLK_HZ / 2;
    localparam int unsigned SPI_SCK_HZ    = (SPI_REQ_HZ > SPI_MAX_HW_HZ) ? SPI_MAX_HW_HZ : SPI_REQ_HZ;

    localparam int unsigned SPI_HALF_PERIOD_RAW =
        (2 * SPI_SCK_HZ == 0) ? 1 : (CLK_HZ / (2 * SPI_SCK_HZ));
    localparam int unsigned SPI_HALF_PERIOD =
        (SPI_HALF_PERIOD_RAW < 1) ? 1 : SPI_HALF_PERIOD_RAW;

    // =============================
    // INTERNAL SIGNALS
    // =============================
    logic [7:0] spi_data;
    logic       spi_start;
    logic       spi_busy;
    logic       spi_done;
    logic       clk_sys;
    logic       clk_locked;
    logic       rst_core_n;
    logic       lcd_blk_ctrl;

    // =============================
    // CLOCKING (200 MHz differential -> 40 MHz internal)
    // =============================
    clk_wiz_0 clk_wiz_i (
        .clk_out1(clk_sys),
        .resetn(rst_n),
        .locked(clk_locked),
        .clk_in1_p(clk_200_p),
        .clk_in1_n(clk_200_n)
    );

    assign rst_core_n = rst_n & clk_locked;
    assign lcd_blk = lcd_blk_ctrl;
    assign uart_tx = 1'b1;

    // =============================
    // SPI MASTER
    // =============================
    spi_master #(
        .CLK_DIV(SPI_HALF_PERIOD)
    ) spi0 (
        .clk(clk_sys),
        .rst_n(rst_core_n),
        .data_in(spi_data),
        .start(spi_start),
        .scl(lcd_scl),
        .sda(lcd_sda),
        .busy(spi_busy),
        .done(spi_done)
    );

    // =============================
    // LCD CONTROLLER
    // =============================
    lcd_uart_ctrl #(
        .CLK_HZ(CLK_HZ),
        .LCD_W(PANEL_W),
        .LCD_H(PANEL_H),
        .STRIPE_H(STRIPE_H),
        .UART_BAUD(UART_BAUD)
    ) lcd0 (
        .clk(clk_sys),
        .rst_n(rst_core_n),
        .uart_rx_i(uart_rx),

        .spi_data(spi_data),
        .spi_start(spi_start),
        .spi_busy(spi_busy),
        .spi_done(spi_done),

        .lcd_cs(lcd_cs),
        .lcd_dc(lcd_dc),
        .lcd_res(lcd_res),
        .lcd_blk(lcd_blk_ctrl)
    );

endmodule