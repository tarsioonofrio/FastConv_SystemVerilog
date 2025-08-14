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
    parameter int FEAT_INPUT_SIZE  = 32,
    parameter int FEAT_OUTPUT_SIZE = 30,
    parameter int LAST_WINDOW   = 0
) (
    input logic clk,
    input logic reset,

    input  logic p_start,
    output logic p_end,
    output logic p_start_conv,
    output logic p_reuse,
    input  logic p_end_conv[3:0],

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

  // typedef enum {
  //   IDLE,
  //   BIAS,
  //   WEIGHT,
  //   ADDR_INPUT,
  //   FEAT_INPUT,
  //   CONV,
  //   ADDR_OUTPUT,
  //   FEAT_OUTPUT
  // } state_type;

  typedef enum {
    START,
    IDLE_INPUT,
    BIAS,
    WEIGHT,
    ADDR_INPUT,
    FEAT_INPUT
  } state_input_type;

  typedef enum {
    IDLE_CONV,
    CONV
  } state_conv_type;

  typedef enum {
    IDLE_OUTPUT,
    ADDR_OUTPUT,
    FEAT_OUTPUT
  } state_output_type;

  state_input_type current_st_input, next_st_input;
  state_conv_type current_st_conv, next_st_conv;
  state_output_type current_st_output, next_st_output;

  logic r_start_conv;
  logic r_data_end;
  logic r_conv_end;
  logic r_wh_en;
  logic r_fin_en;
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

  logic_vector w_mrd_out;
  logic_vector w_mrd_in;

  logic_vector w_mwr_out;
  logic_vector w_mwr_in;

  logic w_mrd_chip;
  logic w_mrd_wr;
  logic w_mrd_valid;
  logic[NADDR-1:0] w_mrd_addr;
  logic w_mwr_chip;
  logic w_mwr_wr;
  logic w_mwr_valid;
  logic[NADDR-1:0] w_mwr_addr;

  logic w_horizontal_end;
  logic w_wh_end;
  logic w_fin_end;

  Memory #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(ROM)
  ) memory_read(
    .clk(clk),
    .reset(reset),
    .chip_en(w_mrd_chip),
    .wr_en(w_mrd_wr),
    .address(w_mrd_addr),
    .data_in(w_mrd_in),
    .data_out(w_mrd_out),
    .data_valid(w_mrd_valid)
  );

  Memory #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(0)
  ) memory_write(
    .clk(clk),
    .reset(reset),
    .chip_en(w_mwr_chip),
    .wr_en(w_mwr_wr),
    .address(w_mwr_addr),
    .data_in(w_mwr_in),
    .data_out(w_mwr_out),
    .data_valid(w_mwr_valid)
  );

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st_input  <= START;
      current_st_conv   <= IDLE_CONV;
      current_st_output <= IDLE_OUTPUT;
    end else begin
      current_st_input  <= next_st_input;
      current_st_conv   <= next_st_conv;
      current_st_output <= next_st_output;
    end
  end


  always_comb begin
    p_start_conv <= r_start_conv;
    p_reuse      <= r_reuse;
    // State Machine

    unique case (current_st_input)
      // IDLE:     if (p_start)      next_st = BIAS;
      START:
        if (p_start)
          next_st_input = WEIGHT;
      IDLE_INPUT: begin
        w_fin_end = 1'b0;
        w_wh_end = 1'b0;
        if (p_end_conv[3]) begin
          if (r_count_window == N_WINDOW * N_WINDOW)
            next_st_input = WEIGHT;
          // else
          // if (r_count_window == N_WINDOW * N_WINDOW * N_CHANNEL_OUT)
          //  next_st_input = BIAS;
          else
          if (r_count_window == N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN)
            next_st_input = IDLE_INPUT;
          else
            next_st_input = ADDR_INPUT;
        end
      end
      BIAS:
          next_st_input = WEIGHT;
      WEIGHT: begin
        w_wh_end = 1'b0;
        if (r_count_wh == (M1_SIZE * M2_SIZE)) begin
          next_st_input = ADDR_INPUT;
          w_wh_end = 1'b1;
        end
      end
      ADDR_INPUT:
        next_st_input = FEAT_INPUT;
      FEAT_INPUT: begin
        w_fin_end = 1'b0;
        if (r_count_fin == (C1_SIZE * C2_SIZE)) begin
          next_st_input = IDLE_INPUT;
          w_fin_end = 1'b1;
        end
      end
    endcase

    unique case (current_st_conv)
      IDLE_CONV:
        if (w_fin_end)
          next_st_conv = CONV;
      CONV:
        if (p_end_conv[2])
          next_st_conv = IDLE_CONV;
    endcase

    unique case (current_st_output)
      IDLE_OUTPUT:
        if (p_end_conv[2])
          next_st_output = ADDR_OUTPUT;
      ADDR_OUTPUT:
        next_st_output = FEAT_OUTPUT;
      FEAT_OUTPUT: begin
        if (p_end_conv[3]) begin
          next_st_output = IDLE_OUTPUT;
        end
      end
    endcase

    p_wh_en    <= r_wh_en;
    p_fin_en   <= r_fin_en;
    p_out_data <= w_mrd_out;

    w_mwr_addr <= r_addr_fout[r_count_fout];
    w_mwr_chip <= p_fout_en;
    w_mwr_wr   <= p_fout_en;
    w_mwr_in   <= p_in_data;

    // Wire control
    unique case (current_st_input)
      BIAS: begin
        w_mrd_addr <= r_addr_bias;
        // w_mrd_chip   <= r_bias_en;
        // p_bias_en    <= r_bias_en;
        // p_bias_valid <= w_mrd_valid;
      end
      WEIGHT: begin
        w_mrd_addr  <= r_addr_wh;
        w_mrd_chip  <= r_wh_en;
        p_wh_valid  <= w_mrd_valid;
        p_fin_valid <= 0;
      end
      default: begin
        w_mrd_addr  <= r_addr_fin[r_count_fin];
        w_mrd_chip  <= r_fin_en;
        p_wh_valid  <= 0;
        p_fin_valid <= w_mrd_valid;
      end
      // FEAT_OUTPUT: begin
      //   p_wh_valid  <= 0;
      //   p_fin_valid <= 0;
      // end
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
      r_addr_fout_base <= 0;
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
      unique case (current_st_input)
        START: begin
          r_addr_bias      <= 0;
          r_addr_wh        <= N_CHANNEL_OUT;
          r_addr_fin_base  <= N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT;
          r_addr_fout_base <= 0;
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
        IDLE_INPUT: begin
          r_count_wh       <= 0;
          r_count_fin      <= 0;
          r_wh_en          <= 1'b0;
          r_fin_en         <= 1'b0;
          r_end_wh         <= 1'b0;
          r_end_fin        <= 1'b0;
        end
        BIAS: begin
          r_addr_bias <= r_addr_bias + 1;
        end
        WEIGHT: begin
          r_wh_en      <= 1'b1;
          r_fin_en     <= 1'b0;
          r_count_fin  <= 0;
          r_count_fout <= 0;
          if (w_mrd_valid) begin
            r_addr_wh  <= r_addr_wh + 1;
            r_count_wh <= r_count_wh + 1;
          end
          // if (w_wh_end)
          //   r_wh_en <= 1'b0;
          // else
          //   r_wh_en <= 1'b1;
        end
        ADDR_INPUT: begin
          r_wh_en    <= 1'b0;
          r_count_wh <= 0;
          // TODO: Implement w_mrd_addr generation logic using if else statements and remove
          // Addresses ordered by column and not by row to facilitate reading
          // when reusing, which reuses the last two columns
          // multiple registers, using one register
          r_addr_fin[00] <= r_addr_fin_base + 0; // 00
          r_addr_fin[01] <= r_addr_fin_base + FEAT_INPUT_SIZE + 0; // 05
          r_addr_fin[02] <= r_addr_fin_base + FEAT_INPUT_SIZE * 2 + 0; // 10
          r_addr_fin[03] <= r_addr_fin_base + FEAT_INPUT_SIZE * 3 + 0; // 15
          r_addr_fin[04] <= r_addr_fin_base + FEAT_INPUT_SIZE * 4 + 0; // 20

          r_addr_fin[05] <= r_addr_fin_base + 1; // 01
          r_addr_fin[06] <= r_addr_fin_base + FEAT_INPUT_SIZE + 1; // 06
          r_addr_fin[07] <= r_addr_fin_base + FEAT_INPUT_SIZE * 2 + 1; // 11
          r_addr_fin[08] <= r_addr_fin_base + FEAT_INPUT_SIZE * 3 + 1; // 16
          r_addr_fin[09] <= r_addr_fin_base + FEAT_INPUT_SIZE * 4 + 1; // 21

          r_addr_fin[10] <= r_addr_fin_base + 2; // 02
          r_addr_fin[11] <= r_addr_fin_base + FEAT_INPUT_SIZE + 2; // 07
          r_addr_fin[12] <= r_addr_fin_base + FEAT_INPUT_SIZE * 2 + 2; // 12
          r_addr_fin[13] <= r_addr_fin_base + FEAT_INPUT_SIZE * 3 + 2; // 17
          r_addr_fin[14] <= r_addr_fin_base + FEAT_INPUT_SIZE * 4 + 2; // 22

          r_addr_fin[15] <= r_addr_fin_base + 3; // 03
          r_addr_fin[16] <= r_addr_fin_base + FEAT_INPUT_SIZE + 3; // 08
          r_addr_fin[17] <= r_addr_fin_base + FEAT_INPUT_SIZE * 2 + 3; // 13
          r_addr_fin[18] <= r_addr_fin_base + FEAT_INPUT_SIZE * 3 + 3; // 18
          r_addr_fin[19] <= r_addr_fin_base + FEAT_INPUT_SIZE * 4 + 3; // 23

          r_addr_fin[20] <= r_addr_fin_base + 4; // 04
          r_addr_fin[21] <= r_addr_fin_base + FEAT_INPUT_SIZE + 4; // 09
          r_addr_fin[22] <= r_addr_fin_base + FEAT_INPUT_SIZE * 2 + 4; // 14
          r_addr_fin[23] <= r_addr_fin_base + FEAT_INPUT_SIZE * 3 + 4; // 19
          r_addr_fin[24] <= r_addr_fin_base + FEAT_INPUT_SIZE * 4 + 4; // 24

          if (w_horizontal_end) begin
            r_addr_fin_base <= r_addr_fin_base + C1_SIZE + FEAT_INPUT_SIZE * (A1_SIZE - 1);
          end else begin
            r_addr_fin_base <= r_addr_fin_base + A1_SIZE;
          end
        end
        FEAT_INPUT: begin
          r_fin_en     <= 1'b1;
          r_wh_en      <= 1'b0;
          r_count_wh   <= 0;
          r_count_fout <= 0;
          if (w_mrd_valid)
            r_count_fin <= r_count_fin + 1;
          // if (w_fin_end)
          //   r_fin_en <= 1'b0;
          // else
          //   r_fin_en <= 1'b1;
        end
      endcase

      unique case (current_st_conv)
        IDLE_CONV: begin
          if (w_fin_end)
            r_start_conv <= 1'b1;
          else
            r_start_conv <= 1'b0;
        end
        CONV: begin
          r_start_conv <= 1'b0;
        end
      endcase

      unique case (current_st_output)
        IDLE_OUTPUT: begin
          r_addr_fout_base <= 0;
          // r_reuse          <= 1'b0;
        end
        ADDR_OUTPUT: begin
          // TODO: Implement address generation logic using if else statements and remove
          // multiple registers, using one register
          r_addr_fout[0] <= r_addr_fout_base + 0;
          r_addr_fout[1] <= r_addr_fout_base + 1;
          r_addr_fout[2] <= r_addr_fout_base + 2;

          r_addr_fout[3] <= r_addr_fout_base + FEAT_OUTPUT_SIZE + 0;
          r_addr_fout[4] <= r_addr_fout_base + FEAT_OUTPUT_SIZE + 1;
          r_addr_fout[5] <= r_addr_fout_base + FEAT_OUTPUT_SIZE + 2;

          r_addr_fout[6] <= r_addr_fout_base + FEAT_OUTPUT_SIZE * 2 + 0;
          r_addr_fout[7] <= r_addr_fout_base + FEAT_OUTPUT_SIZE * 2 + 1;
          r_addr_fout[8] <= r_addr_fout_base + FEAT_OUTPUT_SIZE * 2 + 2;

          if (w_horizontal_end)
            r_addr_fout_base <= r_addr_fout_base + A1_SIZE + FEAT_OUTPUT_SIZE * (A1_SIZE - 1);
          else
            r_addr_fout_base <= r_addr_fout_base + A1_SIZE;
        end
        FEAT_OUTPUT: begin
          if (p_fout_valid) begin
            r_count_fout <= r_count_fout + 1;
          end
          if (p_end_conv[3]) begin
            if (w_horizontal_end) begin
              r_count_fin <= 0;
              r_reuse     <= 1'b0;
            end else begin
              r_count_fin <= 10;
              r_reuse     <= 1'b1;
            end
            if (w_horizontal_end) begin
              r_count_horizontal <= 0;
              r_count_vertical   <= r_count_vertical + 1;
            end
            else begin
              r_count_window     <= r_count_window + 1;
              r_count_horizontal <= r_count_horizontal + 1;
            end
          end
        end
      endcase
    end
  end
endmodule
