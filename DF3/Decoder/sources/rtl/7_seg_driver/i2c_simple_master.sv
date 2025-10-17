module i2c_simple_master #(
    parameter int CLOCK_DIVIDER = 100  // Must be even
)(
    input  logic         clk,
    input  logic         rst_n,
    input  logic         start,
    input  logic [7:0]   data_array [0:7],  // External data
    input  logic [2:0]   num_bytes,         // External number of bytes
    output logic         busy,
    output logic         done,
    output logic         ack_error,
    output logic         sda_out,
    input  logic         sda_in,
    output logic         sda_out_en,
    output logic         scl
);

    typedef enum logic [3:0] {
        IDLE,
        START_COND,
        SEND_BIT_LOW,
        SEND_BIT_HIGH,
        ACK_LOW,
        ACK_HIGH,
        NEXT_BYTE,
        STOP_LOW,
        STOP_HIGH,
        DONE_STATE
    } state_t;

    state_t state, next_state;

    logic [7:0] latched_data [0:7];
    logic [2:0] latched_num_bytes;
    logic [2:0] bit_cnt;
    logic [2:0] byte_idx;
    logic [7:0] shift_reg;
    logic       sda_out_val;
    logic       scl_int;
    logic [9:0] clk_div_cnt;
    logic       scl_tick;
    logic       start_d, start_rising;
    logic       start_req;
    logic       done_pulse;

    assign scl    = scl_int;

    // Detect rising edge of start input
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            start_d <= 0;
        else
            start_d <= start;
    end
    assign start_rising = start & ~start_d;

    // Latch data and byte count on start
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            latched_num_bytes <= 0;
            for (int i = 0; i < 8; i++) latched_data[i] <= 8'd0;
        end else if (start_rising) begin
            latched_num_bytes <= num_bytes;
            for (int i = 0; i < 8; i++) latched_data[i] <= data_array[i];
        end
    end

    // Start request tracking
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            start_req <= 0;
        else if (start_rising)
            start_req <= 1;
        else if (state == START_COND)
            start_req <= 0;
    end

    // Clock divider and scl_tick
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div_cnt <= 0;
            scl_tick    <= 0;
        end else if (state != IDLE || start_req) begin
            if (clk_div_cnt == (CLOCK_DIVIDER/2 - 1)) begin
                clk_div_cnt <= 0;
                scl_tick    <= 1;
            end else begin
                clk_div_cnt <= clk_div_cnt + 1;
                scl_tick    <= 0;
            end
        end else begin
            clk_div_cnt <= 0;
            scl_tick    <= 0;
        end
    end

    // FSM and control
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            scl_int    <= 1;
            sda_out_en <= 0;
            sda_out_val<= 1;
            bit_cnt    <= 0;
            byte_idx   <= 0;
            shift_reg  <= 0;
            ack_error  <= 0;
            done_pulse <= 0;
        end else if (scl_tick) begin
            state <= next_state;
            done_pulse <= (next_state == DONE_STATE);

            case (state)
                IDLE: begin
                    scl_int    <= 1;
                    sda_out_en <= 0;
                    sda_out_val<= 1;
                    bit_cnt    <= 0;
                    byte_idx   <= 0;
                    ack_error  <= 0;
                    done_pulse <= 0;
                    if (start_req) begin
                        shift_reg <= latched_data[0];
                    end
                end

                START_COND: begin
                    // Start condition: SDA goes LOW while SCL is HIGH
                    sda_out_en <= 1;
                    sda_out_val<= 0;
                    scl_int    <= 1;
                end

                SEND_BIT_LOW: begin
                    scl_int    <= 0;
                    sda_out_en <= 1;
                    sda_out_val<= shift_reg[0]; // LSB first
                end

                SEND_BIT_HIGH: begin
                    scl_int <= 1;
                    // Keep SDA stable
                    shift_reg <= {1'b0, shift_reg[7:1]};
                    bit_cnt <= bit_cnt + 1;
                end

                ACK_LOW: begin
                    scl_int    <= 0;
                    sda_out_en <= 0; // release SDA for slave ACK
                end

                ACK_HIGH: begin
                    scl_int <= 1;
                    sda_out_en <= 0;
                    if (sda_in)
                        ack_error <= 1;
                end

                NEXT_BYTE: begin
                    bit_cnt <= 0;
                    byte_idx <= byte_idx + 1;
                    shift_reg <= latched_data[byte_idx + 1];
                end

                STOP_LOW: begin
                    scl_int    <= 0;
                    sda_out_en <= 1;
                    sda_out_val<= 0;
                end

                STOP_HIGH: begin
                    scl_int    <= 1;
                end

                DONE_STATE: begin
                    sda_out_en <= 0;
                    scl_int    <= 1;
                end
            endcase
        end else begin
            done_pulse <= 0;
        end
    end

    // FSM next-state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start_req)
                    next_state = START_COND;
            end

            START_COND:       next_state = SEND_BIT_LOW;
            SEND_BIT_LOW:     next_state = SEND_BIT_HIGH;
            SEND_BIT_HIGH:    next_state = (bit_cnt == 7) ? ACK_LOW : SEND_BIT_LOW;
            ACK_LOW:          next_state = ACK_HIGH;
            ACK_HIGH:         next_state = (byte_idx == latched_num_bytes - 1) ? STOP_LOW : NEXT_BYTE;
            NEXT_BYTE:        next_state = SEND_BIT_LOW;
            STOP_LOW:         next_state = STOP_HIGH;
            STOP_HIGH:        next_state = DONE_STATE;
            DONE_STATE:       next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    assign sda_out = sda_out_val;
    // Outputs
    assign busy = (state != IDLE);
    assign done = done_pulse;

endmodule