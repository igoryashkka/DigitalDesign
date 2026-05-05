module spi_master #(
    parameter CLK_DIV = 24
)(
    input  logic clk,
    input  logic rst_n,

    input  logic [7:0] data_in,
    input  logic       start,

    output logic scl,
    output logic sda,
    output logic busy,
    output logic done
);

    localparam int unsigned HALF_PERIOD = (CLK_DIV < 1) ? 1 : CLK_DIV;

    logic [7:0] tx_byte;
    logic [2:0] bit_cnt;
    logic [15:0] clk_cnt;
    logic       sclk_phase;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl        <= 1'b0;
            sda        <= 1'b0;
            busy       <= 1'b0;
            done       <= 1'b0;
            bit_cnt    <= 3'd0;
            clk_cnt    <= 16'd0;
            tx_byte    <= 8'h00;
            sclk_phase <= 1'b0;
        end else begin
            done <= 1'b0;

            if (!busy) begin
                scl        <= 1'b0;
                sclk_phase <= 1'b0;
                clk_cnt    <= 16'd0;

                if (start) begin
                    tx_byte <= data_in;
                    bit_cnt <= 3'd7;
                    sda     <= data_in[7];
                    busy    <= 1'b1;
                end
            end else begin
                if (clk_cnt == (HALF_PERIOD - 1)) begin
                    clk_cnt <= 16'd0;

                    if (!sclk_phase) begin
                        // Rising edge: ST7789 samples MOSI here (SPI mode 0).
                        scl        <= 1'b1;
                        sclk_phase <= 1'b1;
                    end else begin
                        // Falling edge: prepare the next data bit while SCK is low.
                        scl        <= 1'b0;
                        sclk_phase <= 1'b0;

                        if (bit_cnt == 0) begin
                            busy <= 1'b0;
                            done <= 1'b1;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                            sda     <= tx_byte[bit_cnt - 1'b1];
                        end
                    end
                end else begin
                    clk_cnt <= clk_cnt + 1'b1;
                end
            end
        end
    end

endmodule