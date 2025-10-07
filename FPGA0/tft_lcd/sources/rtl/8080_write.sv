`timescale 1ns/1ps
import ili934x_pkg::*;

module lcd8080_writer #(
  parameter int WR_PULSE_CYC = 2,
  parameter int WR_RECOV_CYC = 1
)(
  input  logic       clk,
  input  logic       rst_n,

  // stream in
  input  logic       item_valid,
  input  logic       item_is_cmd,
  input  logic [7:0] item_byte,
  output logic       item_ready,

  // 8080 pins
  output logic       lcd_cs_n,  // tie low inside
  output logic       lcd_rd_n,  // tie high (no reads)
  output logic       lcd_dc,
  output logic       lcd_wr_n,
  output logic [7:0] lcd_d
);

  typedef enum logic [1:0] {IDLE, SETUP, PULSE, RECOV} w_e;
  w_e state;

  logic [7:0] d_lat;
  logic       dc_lat;

  logic [$clog2(WR_PULSE_CYC+1)-1:0] pulse_cnt;
  logic [$clog2(WR_RECOV_CYC+1)-1:0] recov_cnt;

  assign lcd_cs_n = 1'b0;
  assign lcd_rd_n = 1'b1;
  assign lcd_d    = d_lat;
  assign lcd_dc   = dc_lat;

  // ready only in IDLE when we can accept a new item
  assign item_ready = (state == IDLE);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state     <= IDLE;
      lcd_wr_n  <= 1'b1;
      d_lat     <= 8'h00;
      dc_lat    <= 1'b0;
      pulse_cnt <= '0;
      recov_cnt <= '0;
    end else begin
      unique case (state)
        IDLE: begin
          lcd_wr_n <= 1'b1;
          if (item_valid) begin
            d_lat  <= item_byte;
            dc_lat <= ~item_is_cmd;  // lcd_dc=0 for cmd
            state  <= SETUP;
          end
        end
        SETUP: begin
          lcd_wr_n  <= 1'b0;      // start write low
          pulse_cnt <= '0;
          state     <= PULSE;
        end
        PULSE: begin
          if (pulse_cnt == WR_PULSE_CYC-1) begin
            lcd_wr_n  <= 1'b1;    // release
            recov_cnt <= '0;
            state     <= RECOV;
          end else begin
            pulse_cnt <= pulse_cnt + 1;
          end
        end
        RECOV: begin
          if (recov_cnt == WR_RECOV_CYC-1) begin
            state <= IDLE;
          end else begin
            recov_cnt <= recov_cnt + 1;
          end
        end
      endcase
    end
  end
endmodule
