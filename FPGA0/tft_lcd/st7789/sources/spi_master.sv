module spi_master #(
    parameter CLK_DIV = 4
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

    logic [7:0] shift_reg;
    logic [2:0] bit_cnt;
    logic [15:0] clk_cnt;

    typedef enum logic [1:0] {
        IDLE,
        TRANSFER,
        DONE
    } state_t;

    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            scl <= 0;
            sda <= 0;
            busy <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        shift_reg <= data_in;
                        bit_cnt <= 7;
                        busy <= 1;
                        clk_cnt <= 0;
                        state <= TRANSFER;
                    end
                end

                TRANSFER: begin
                    clk_cnt <= clk_cnt + 1;

                    if (clk_cnt == CLK_DIV) begin
                        scl <= ~scl;
                        clk_cnt <= 0;

                        if (scl == 0) begin
                            sda <= shift_reg[bit_cnt];
                        end else begin
                            if (bit_cnt == 0) begin
                                state <= DONE;
                            end else begin
                                bit_cnt <= bit_cnt - 1;
                            end
                        end
                    end
                end

                DONE: begin
                    busy <= 0;
                    done <= 1;
                    scl <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule