module uart_rx #(
    parameter int unsigned CLK_HZ = 40_000_000,
    parameter int unsigned BAUD   = 921_600
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       rx,
    output logic [7:0] data,
    output logic       valid
);

    localparam int unsigned CLKS_PER_BIT = (BAUD == 0) ? 1 : (CLK_HZ / BAUD);
    localparam int unsigned HALF_BIT     = (CLKS_PER_BIT > 1) ? (CLKS_PER_BIT / 2) : 1;

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_START,
        ST_DATA,
        ST_STOP
    } state_t;

    state_t state;

    logic [31:0] clk_cnt;
    logic [2:0]  bit_idx;
    logic [7:0]  shift_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= ST_IDLE;
            clk_cnt   <= 32'd0;
            bit_idx   <= 3'd0;
            shift_reg <= 8'h00;
            data      <= 8'h00;
            valid     <= 1'b0;
        end else begin
            valid <= 1'b0;

            case (state)
                ST_IDLE: begin
                    clk_cnt <= 32'd0;
                    bit_idx <= 3'd0;
                    if (!rx) begin
                        state <= ST_START;
                    end
                end

                ST_START: begin
                    if (clk_cnt == (HALF_BIT - 1)) begin
                        clk_cnt <= 32'd0;
                        if (!rx) begin
                            state <= ST_DATA;
                        end else begin
                            state <= ST_IDLE;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                ST_DATA: begin
                    if (clk_cnt == (CLKS_PER_BIT - 1)) begin
                        clk_cnt <= 32'd0;
                        shift_reg[bit_idx] <= rx;
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 3'd0;
                            state   <= ST_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                ST_STOP: begin
                    if (clk_cnt == (CLKS_PER_BIT - 1)) begin
                        clk_cnt <= 32'd0;
                        if (rx) begin
                            data  <= shift_reg;
                            valid <= 1'b1;
                        end
                        state <= ST_IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
