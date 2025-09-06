module Control
  import packConv::*;
  import data::*;
#(
    parameter int NADDR         = 12,
    parameter int NBITS         = 20,
    parameter int LATENCY       = 1,
    parameter int ROM           = 0,
    parameter int QUANT         = 8,
    parameter int N_WINDOW      = 10,
    parameter int N_CHANNEL_IN  = 1,
    parameter int N_CHANNEL_OUT = 1,
    parameter int FEAT_IN_SIZE  = 32,
    parameter int FEAT_OUT_SIZE = 30,
    parameter int LAST_WINDOW   = 0
) (
    input logic clk,
    input logic reset,

    input  logic p_start,
    output logic p_end,
    output logic p_start_conv,
    output logic p_reuse,
    input  logic p_end_conv[2:0],

    output logic p_wh_en,
    output logic p_wh_valid,

    output logic p_fin_en,
    output logic p_fin_valid,

    input logic p_fout_en,
    input logic p_fout_valid,

    output logic_vector p_out_data,
    input  logic_vector p_in_data
);

  timeunit 1ns; timeprecision 1ps;

  typedef enum {
    IDLE,
    BIAS,
    WEIGHT,
    ADDR_IN,
    FEAT_IN,
    CONV,
    ADDR_OUT,
    FEAT_OUT
  } state_type;

  state_type current_st, next_st;

  logic r_start_conv;
  logic r_fout_en;
  logic r_data_end;
  logic r_conv_end;
  logic r_wh_en;
  logic r_fin_en;
  logic r_chip_en;
  logic r_end_wh;
  logic r_end_fin;
  logic r_reuse;

  int r_count_wh;
  int r_count_fin;
  int r_count_fout;
  int r_addr_bias;
  int r_addr_wh;
  int r_addr_fin_base;
  int r_addr_fin[25:0];
  int r_addr_fout_base;
  int r_addr_fout[9:0];
  int r_count_window;
  int r_count_horizontal;
  int r_count_vertical;

  logic_vector data_out;
  logic_vector data_in;

  logic chip_en;
  logic wr_en;
  logic data_valid_out;
  logic[NADDR-1:0] address;
  logic w_horizontal_end;

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
    .data_in(data_in),
    .data_out(data_out),
    .data_valid(data_valid_out)
  );

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st <= IDLE;
    end else begin
      current_st <= next_st;
    end
  end

  always_comb begin
    p_start_conv <= r_start_conv;
    p_reuse      <= r_reuse;
    // State Machine
    unique case (current_st)
      // IDLE:     if (p_start)      next_st = BIAS;
      IDLE:
        if (p_start)
          next_st = WEIGHT;
      BIAS:
          next_st = WEIGHT;
      WEIGHT:
        if (p_end_conv[0])
          next_st = ADDR_IN;
      ADDR_IN:
        next_st = FEAT_IN;
      FEAT_IN:
        if (p_end_conv[1])
          next_st = CONV;
      CONV:
        if (r_start_conv)
          next_st = ADDR_OUT;
      ADDR_OUT:
        next_st = FEAT_OUT;
      FEAT_OUT: begin
        if (p_end_conv[2]) begin
          if (r_count_window == N_WINDOW * N_WINDOW)
            next_st = WEIGHT;
          // else
          // if (r_count_window == N_WINDOW * N_WINDOW * N_CHANNEL_OUT)
          //  next_st = BIAS;
          else
          if (r_count_window == N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN)
            next_st = IDLE;
          else
            next_st = ADDR_IN;
        end
      end
    endcase

    chip_en <= r_chip_en;
    // Wire control
    unique case (current_st)
      BIAS: begin
        address <= r_addr_bias;
        // chip_en <= r_bias_en;
        // p_bias_en <= r_bias_en;
        p_out_data <= data_out;
        // p_bias_valid <= data_valid_out;
      end
      WEIGHT: begin
        address     <= r_addr_wh;
        chip_en     <= r_wh_en;
        p_wh_en     <= r_wh_en;
        p_fin_en    <= r_fin_en;
        p_out_data  <= data_out;
        p_wh_valid  <= data_valid_out;
        p_fin_valid <= 0;
      end
      default: begin
        address     <= r_addr_fin[r_count_fin];
        chip_en     <= r_fin_en;
        p_wh_en     <= r_wh_en;
        p_fin_en    <= r_fin_en;
        p_out_data  <= data_out;
        p_wh_valid  <= 0;
        p_fin_valid <= data_valid_out;
      end
      FEAT_OUT: begin
        address     <= r_addr_fout[r_count_fout];
        chip_en     <= r_fout_en;
        wr_en       <= r_fout_en;
        data_in     <= p_in_data;
        p_wh_en     <= r_wh_en;
        p_fin_en    <= r_fin_en;
        p_wh_valid  <= 0;
        p_fin_valid <= 0;
      end
    endcase

    if (r_count_horizontal < N_WINDOW - 1)
      w_horizontal_end <= 1'b0;
    else
      w_horizontal_end <= 1'b1;
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      r_addr_bias      <= 0;
      r_addr_wh        <= N_CHANNEL_OUT;
      r_addr_fin_base  <= N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT;
      r_addr_fout_base <= N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT + N_CHANNEL_IN * FEAT_IN_SIZE * FEAT_IN_SIZE;
      r_count_wh       <= 0;
      r_count_fin      <= 0;
      r_count_fout     <= 0;
      r_count_window   <= 0;
      r_reuse          <= 1'b0;
      r_wh_en          <= 1'b0;
      r_fin_en         <= 1'b0;
      r_end_wh         <= 1'b0;
      r_end_fin        <= 1'b0;
      r_start_conv     <= 1'b0;
    end else begin
      unique case (current_st)
        IDLE: begin
          r_addr_bias      <= 0;
          r_addr_wh        <= N_CHANNEL_OUT;
          r_addr_fin_base  <= N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT;
          r_addr_fout_base <= N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT + N_CHANNEL_IN * FEAT_IN_SIZE * FEAT_IN_SIZE;
          r_count_wh       <= 0;
          r_count_fin      <= 0;
          r_count_fout     <= 0;
          r_count_window   <= 0;
          r_reuse          <= 1'b0;
          r_wh_en          <= 1'b0;
          r_fin_en         <= 1'b0;
          r_end_wh         <= 1'b0;
          r_end_fin        <= 1'b0;
          r_start_conv     <= 1'b0;
        end
        BIAS: begin
          r_chip_en   <= 1'b1;
          r_addr_bias <= r_addr_bias + 1;
        end
        WEIGHT: begin
          r_fin_en     <= 1'b0;
          r_count_fin  <= 0;
          r_count_fout <= 0;
          if (data_valid_out)
            r_addr_wh  <= r_addr_wh + 1;
          if (p_end_conv[1]) begin
            r_wh_en <= 1'b0;
            r_addr_wh  <= 0;
          end
          else
            r_wh_en <= 1'b1;
        end
        ADDR_IN: begin
          // TODO: Implement address generation logic using if else statements and remove
          // Addresses ordered by column and not by row to facilitate reading
          // when reusing, which reuses the last two columns
          // multiple registers, using one register
          r_addr_fin[00] <= r_addr_fin_base + 0; // 00
          r_addr_fin[01] <= r_addr_fin_base + FEAT_IN_SIZE + 0; // 05
          r_addr_fin[02] <= r_addr_fin_base + FEAT_IN_SIZE * 2 + 0; // 10
          r_addr_fin[03] <= r_addr_fin_base + FEAT_IN_SIZE * 3 + 0; // 15
          r_addr_fin[04] <= r_addr_fin_base + FEAT_IN_SIZE * 4 + 0; // 20

          r_addr_fin[05] <= r_addr_fin_base + 1; // 01
          r_addr_fin[06] <= r_addr_fin_base + FEAT_IN_SIZE + 1; // 06
          r_addr_fin[07] <= r_addr_fin_base + FEAT_IN_SIZE * 2 + 1; // 11
          r_addr_fin[08] <= r_addr_fin_base + FEAT_IN_SIZE * 3 + 1; // 16
          r_addr_fin[09] <= r_addr_fin_base + FEAT_IN_SIZE * 4 + 1; // 21

          r_addr_fin[10] <= r_addr_fin_base + 2; // 02
          r_addr_fin[11] <= r_addr_fin_base + FEAT_IN_SIZE + 2; // 07
          r_addr_fin[12] <= r_addr_fin_base + FEAT_IN_SIZE * 2 + 2; // 12
          r_addr_fin[13] <= r_addr_fin_base + FEAT_IN_SIZE * 3 + 2; // 17
          r_addr_fin[14] <= r_addr_fin_base + FEAT_IN_SIZE * 4 + 2; // 22

          r_addr_fin[15] <= r_addr_fin_base + 3; // 03
          r_addr_fin[16] <= r_addr_fin_base + FEAT_IN_SIZE + 3; // 08
          r_addr_fin[17] <= r_addr_fin_base + FEAT_IN_SIZE * 2 + 3; // 13
          r_addr_fin[18] <= r_addr_fin_base + FEAT_IN_SIZE * 3 + 3; // 18
          r_addr_fin[19] <= r_addr_fin_base + FEAT_IN_SIZE * 4 + 3; // 23

          r_addr_fin[20] <= r_addr_fin_base + 4; // 04
          r_addr_fin[21] <= r_addr_fin_base + FEAT_IN_SIZE + 4; // 09
          r_addr_fin[22] <= r_addr_fin_base + FEAT_IN_SIZE * 2 + 4; // 14
          r_addr_fin[23] <= r_addr_fin_base + FEAT_IN_SIZE * 3 + 4; // 19
          r_addr_fin[24] <= r_addr_fin_base + FEAT_IN_SIZE * 4 + 4; // 24

          if (w_horizontal_end) begin
            r_addr_fin_base <= r_addr_fin_base + C1_SIZE + FEAT_IN_SIZE * (A1_SIZE - 1);
          end else begin
            r_addr_fin_base <= r_addr_fin_base + A1_SIZE;
          end
        end
        FEAT_IN: begin
          r_wh_en      <= 1'b0;
          r_count_wh   <= 0;
          r_count_fout <= 0;
          if (data_valid_out)
            r_count_fin <= r_count_fin + 1;
          if (p_end_conv[1])
            r_fin_en <= 1'b0;
          else
            r_fin_en <= 1'b1;
        end
        CONV: begin
          r_wh_en      <= 1'b0;
          r_fin_en     <= 1'b0;
          r_start_conv <= 1'b1;
        end
        ADDR_OUT: begin
          // TODO: Implement address generation logic using if else statements and remove
          // multiple registers, using one register
          r_addr_fout[0] <= r_addr_fout_base + 0;
          r_addr_fout[1] <= r_addr_fout_base + 1;
          r_addr_fout[2] <= r_addr_fout_base + 2;

          r_addr_fout[3] <= r_addr_fout_base + FEAT_OUT_SIZE + 0;
          r_addr_fout[4] <= r_addr_fout_base + FEAT_OUT_SIZE + 1;
          r_addr_fout[5] <= r_addr_fout_base + FEAT_OUT_SIZE + 2;

          r_addr_fout[6] <= r_addr_fout_base + FEAT_OUT_SIZE * 2 + 0;
          r_addr_fout[7] <= r_addr_fout_base + FEAT_OUT_SIZE * 2 + 1;
          r_addr_fout[8] <= r_addr_fout_base + FEAT_OUT_SIZE * 2 + 2;

          if (w_horizontal_end)
            r_addr_fout_base <= r_addr_fout_base + A1_SIZE + FEAT_OUT_SIZE * (A1_SIZE - 1);
          else
            r_addr_fout_base <= r_addr_fout_base + A1_SIZE;
        end
        FEAT_OUT: begin
          r_start_conv <= 1'b0;
          r_fout_en    <= 1'b1;
          r_count_wh   <= 0;
          r_count_fin  <= 0;
          if (p_fout_valid) begin
            r_count_fout <= r_count_fout + 1;
          end
          if (p_end_conv[2]) begin
            if (w_horizontal_end) begin
              r_count_fin <= 0;
              r_reuse     <= 1'b0;
            end else begin
              r_count_fin <= 10;
              r_reuse     <= 1'b1;
            end
            if (w_horizontal_end) begin
              r_count_horizontal <= 0;
              r_count_vertical <= r_count_vertical + 1;
            end
            else begin
              r_count_window <= r_count_window + 1;
              r_count_horizontal <= r_count_horizontal + 1;
            end
          end
        end
      endcase
    end
  end
endmodule
