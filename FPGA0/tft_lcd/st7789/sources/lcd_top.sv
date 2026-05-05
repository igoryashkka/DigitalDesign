module lcd_top (
    input  logic clk_200_p,
    input  logic clk_200_n,
    input  logic rst_n,

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
    parameter CLK_DIV = 4; // SPI clock divider

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

    // =============================
    // CLOCKING (200 MHz differential -> 50 MHz internal)
    // =============================
    clk_wiz_0 clk_wiz_i (
        .clk_out1(clk_sys),
        .resetn(rst_n),
        .locked(clk_locked),
        .clk_in1_p(clk_200_p),
        .clk_in1_n(clk_200_n)
    );

    assign rst_core_n = rst_n & clk_locked;

    // =============================
    // SPI MASTER
    // =============================
    spi_master #(
        .CLK_DIV(CLK_DIV)
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
    lcd_ctrl lcd0 (
        .clk(clk_sys),
        .rst_n(rst_core_n),

        .spi_data(spi_data),
        .spi_start(spi_start),
        .spi_busy(spi_busy),
        .spi_done(spi_done),

        .lcd_cs(lcd_cs),
        .lcd_dc(lcd_dc),
        .lcd_res(lcd_res),
        .lcd_blk(lcd_blk)
    );

endmodule