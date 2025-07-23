module Control
  import packConv::*;
  import data::*;
#(
    parameter int NADDR         = 12,
    parameter int NBITS         = 20,
    parameter int LATENCY       = 1,
    parameter int ROM           = 0,
    parameter int QUANT         = 8,
    parameter int NADDR         = 12,
    parameter int N_WINDOW      = 15,
    parameter int N_CHANNEL_IN  = 1,
    parameter int N_CHANNEL_OUT = 1,
    parameter int FEAT_IN_SIZE  = 32,
    parameter int LAST_WINDOW   = 0
) (
    input logic clk,
    input logic reset,

    input  logic p_start,
    output logic p_end,
    // output logic p_debug,

    output logic p_fin_en,
    output logic p_fin_valid,

    output logic p_wh_en,
    output logic p_wh_valid,

    input logic p_fout_en,
    input logic p_fout_valid,

    output logic_vector p_fin_data,
    input  logic_vector p_fout_data
);

  timeunit 1ns; timeprecision 1ps;

  typedef enum {
    IDLE,
    BIAS,
    WEIGHT,
    FEAT_IN,
    CONV,
    FEAT_OUT
  } state_type;

  state_type current_st, next_st;

  logic r_data_end;
  logic r_fout_en;
  logic r_conv_end;

  int r_count_wh;
  int r_count_fin;
  int r_count_fout;

  int r_addr_bias;
  int r_addr_wh;
  int r_addr_fin;
  int r_addr_fout;
  int r_count_window;

  logic_vector data_fin;
  logic_vector data_fout;

  logic chip_en;
  logic wr_en;
  logic data_valid_fin;
  logic[NADDR-1:0] address;

  Memory #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(ROM)
  ) memory (
    .clk(clk),
    .reset(reset),
    .chip_en(chip_en),
    .wr_en(wr_en),
    .address(address),
    .data_in(data_fout),
    .data_out(data_fin),
    .data_valid(data_valid_fin)
  );

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st <= IDLE;
    end else begin
      current_st <= next_st;
    end
  end

  always_comb begin
    // State Machine
    unique case (current_st)
      IDLE:     if (p_start) next_st = BIAS;
      BIAS:     if (p_fout_valid) next_st = WEIGHT;
      WEIGHT:   if (r_count_wh == M1_SIZE * M2_SIZE) next_st = FEAT_IN;
      FEAT_IN:  if (r_count_fin == C1_SIZE * C2_SIZE) next_st = FEAT_OUT;
      FEAT_OUT: begin
        if (r_count_window == N_WINDOW * N_WINDOW) next_st = WEIGHT;
        else
        if (r_count_window == N_WINDOW * N_WINDOW * N_CHANNEL_OUT) next_st = BIAS;
        else
        if (r_count_window == N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN) next_st = IDLE;
      end
    endcase

    // Wire control
    unique case (current_st)
      BIAS: begin
        address <= r_addr_bias;
        p_fin_en <= chip_en;
        p_fin_data <= data_fin;
        p_fin_valid <= data_valid_fin;
      end
      WEIGHT: begin
        address <= r_addr_wh;
        p_fin_en <= chip_en;
        p_fin_data <= data_fin;
        p_fin_valid <= data_valid_fin;
      end
      FEAT_OUT: begin
        data_fin <= p_fout_data;
        chip_en <= p_fout_en;
        address <= r_addr_fout;
      end
      default: begin
        address <= r_addr_fin;
        p_fin_en <= chip_en;
        p_fin_data <= data_fin;
        p_fin_valid <= data_valid_fin;
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      r_addr_bias    <= 0;
      r_addr_wh      <= N_CHANNEL_OUT;
      r_addr_fin     <= N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT;
      r_addr_fout    <= N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT + N_CHANNEL_IN * FEAT_IN_SIZE * FEAT_IN_SIZE;
      r_count_wh     <= 0;
      r_count_fin    <= 0;
      r_count_fout   <= 0;
      r_count_window <= 0;
    end else begin
      unique case (current_st)
        IDLE: begin
          r_addr_bias    <= 0;
          r_addr_wh      <= N_CHANNEL_OUT;
          r_addr_fin     <= N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT;
          r_addr_fout    <= N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT + N_CHANNEL_IN * FEAT_IN_SIZE * FEAT_IN_SIZE;
          r_count_wh     <= 0;
          r_count_fin    <= 0;
          r_count_fout   <= 0;
          r_count_window <= 0;
        end
        BIAS: begin
          r_addr_bias <= r_addr_bias + 1;
        end
        WEIGHT: begin
          if (data_valid_fin && (r_count_fin < M1_SIZE * M2_SIZE)) begin
            r_count_fin <= r_count_fin + 1;
            r_addr_wh <= r_addr_wh + 1;
          end else
            r_count_fin <= 0;
        end
        FEAT_IN: begin
          if (data_valid_fin && (r_count_fin < C1_SIZE * C2_SIZE)) begin
            r_count_fin <= r_count_fin + 1;
            r_addr_fin <= r_addr_fin + 1;
          end else
            r_count_fin <= 0;
        end
        FEAT_OUT: begin
          if (p_fout_valid && (r_count_fout < (A1_SIZE * A2_SIZE))) begin
            r_count_fout <= r_count_fout + 1;
            r_addr_fout <= r_addr_fout + 1;
          end else begin
            r_count_window <= r_count_window + 1;
            r_count_fout  <= 0;
          end
        end
      endcase
    end
  end
endmodule
