`include "driver.svh"

module driver #(
    parameter int CLK_DIV = 1
)(
    input clk_i,
    input porb_i,
    input sync_reset_i,
    input logic [7:0] digits_i [0:3],
    input disp_strobe_i,
    output busy_o,
    output sda_out,
    input  sda_in,
    output sda_out_en,
    output seg_scl_o
);

typedef enum logic [2:0] {
    IDLE,
    SEND_ADDR_MODE_CMD,
    SEND_ADDR_AND_DIGITS,
    SEND_DISPLAY_CMD,
    DONE
} state_t;

state_t fsm_state_ff, fsm_next;

logic seg_start, seg_busy, seg_done;
logic [7:0] seg_data [0:7]; 
logic [2:0] seg_byte_num;
logic busy;

// FSM state FF
always_ff @(negedge porb_i, posedge clk_i ) begin : state_ff
    if(!porb_i)begin
        fsm_state_ff <= IDLE;
    end else if (clk_i) begin
        if(sync_reset_i) begin
            fsm_state_ff <= IDLE;
        end else begin
            fsm_state_ff <= fsm_next;
        end
    end 
end

// State transition logic
always_comb begin : next_state
    fsm_next = fsm_state_ff;
    case (fsm_state_ff)
        IDLE: 
            if (disp_strobe_i) begin
                fsm_next = SEND_ADDR_MODE_CMD;
            end
        SEND_ADDR_MODE_CMD:
            if (seg_done) begin
                fsm_next = SEND_ADDR_AND_DIGITS;
            end
        SEND_ADDR_AND_DIGITS:
            if (seg_done) begin
                fsm_next = SEND_DISPLAY_CMD;
            end
        SEND_DISPLAY_CMD:
            if (seg_done) begin
                fsm_next = DONE;
            end
        DONE:
            fsm_next = IDLE;
        default: fsm_next = fsm_state_ff;
    endcase
end

// Output logic (handling of i2c_master inputs)
always_comb begin
    seg_start = 'b0;
    seg_byte_num = 'd0;
    busy = 'b1;
    for (int i = 0; i < 8; i++) begin
            seg_data[i] = 8'd0;
    end

    case (fsm_state_ff)
        IDLE: 
            begin
                if (fsm_next == SEND_ADDR_MODE_CMD) begin
                    seg_byte_num = 'd1; // One byte
                    seg_data[0] = `ADRR_INCR_MODE; // address mode -- incremental (set all tile values at once, beginning from first tile)
                    seg_start = 'b1;
                end else begin
                    busy = 'b0;
                end
            end
        SEND_ADDR_MODE_CMD:
            begin
                if (fsm_next == SEND_ADDR_AND_DIGITS) begin
                    seg_byte_num = 'd5; // 5 bytes (start addr(first tile) + 4digits)
                    seg_data[0] = `FIRST_TILE_ADDR;

                    // Actual digits data (bitmasks) to be displayed on 4 tiles
                    seg_data[1] = digits_i[0];
                    seg_data[2] = digits_i[1];
                    seg_data[3] = digits_i[2];
                    seg_data[4] = digits_i[3];
                    seg_start = 'b1;
                end
            end
        SEND_ADDR_AND_DIGITS:
            begin
                if (fsm_next == SEND_DISPLAY_CMD) begin
                    seg_byte_num = 'd1; // One byte
                    seg_data[0] = `CMD_DISPLAY; 
                    seg_start = 'b1;    
                end
            end
        DONE:
            busy = 'b0;
        default:
            begin
                seg_start = 'b0;
                seg_byte_num = 'd0;
                busy = 'b1;
                for (int i = 0; i < 8; i++) begin
                    seg_data[i] = 8'd0;
                end
            end
    endcase
end

assign busy_o = busy; 

i2c_simple_master i2c_simple_master_u(
    .clk(clk_i),
    .rst_n(porb_i),
    .start(seg_start),
    .data_array(seg_data),
    .num_bytes(seg_byte_num),
    .busy(seg_busy),
    .done(seg_done),
    .ack_error(),
    .sda_out(sda_out),
    .sda_in(sda_in),
    .sda_out_en(sda_out_en),
    .scl(seg_scl_o)
);

endmodule
