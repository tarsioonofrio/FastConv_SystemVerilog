module Control
  import pack_def::*;
  import pack_typedef::*;
  import pack_param::*;
#(
    parameter int NADDR            = 12,
    parameter int NBITS            = 20,
    parameter int LATENCY          = 1,
    parameter int ROM              = 0,
    parameter int QUANT            = 8,
    parameter int N_WINDOW         = 10,
    parameter int N_CHANNEL_IN     = 1,
    parameter int N_CHANNEL_OUT    = 1,
    parameter int FEAT_INPUT_SIZE  = 32,
    parameter int FEAT_OUTPUT_SIZE = 30,
    parameter int LAST_WINDOW      = 0
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

  typedef enum {
    IDLE_CONTROL,
    IDLE_INPUT,
    BIAS,
    WEIGHT,
    ADDR_INPUT,
    FEAT_INPUT,
    END_INPUT,
    END_CONTROL
  } state_input_type;

  typedef enum {
    IDLE_CONV,
    CONV,
    END_CONV
  } state_conv_type;

  typedef enum {
    IDLE_OUTPUT,
    ADDR_OUTPUT,
    FEAT_OUTPUT,
    END_OUTPUT
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

  logic [$clog2(M1_SIZE*M2_SIZE)-1:0] r_count_wh;
  logic [$clog2(C1_SIZE*C2_SIZE)-1:0] r_count_fin;
  logic [$clog2(A1_SIZE*A2_SIZE)-1:0] r_count_fout;
  logic [$clog2(N_CHANNEL_OUT)-1:0] r_addr_bias;
  logic [$clog2(M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT)-1:0] r_addr_wh;
  logic [$clog2(N_CHANNEL_IN * FEAT_INPUT_SIZE * FEAT_INPUT_SIZE)-1:0] r_addr_fin_base;
  logic [$clog2(N_CHANNEL_IN * FEAT_INPUT_SIZE * FEAT_INPUT_SIZE)-1:0] r_addr_fin[C1_SIZE*C1_SIZE-1:0];
  logic [$clog2(N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)-1:0] r_addr_fout_base;
  logic [$clog2(N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)-1:0] r_addr_fout[A1_SIZE*A2_SIZE-1:0];
  int r_count_window;
  int r_count_horizontal;
  int r_count_vertical;

  logic_vector w_mem_rd_out;
  logic_vector w_mem_rd_in;
  logic w_mem_rd_chip;
  logic w_mem_rd_wr;
  logic w_mem_rd_valid;
  logic[NADDR-1:0] w_mem_rd_addr;

  logic_vector w_mem_wr_out;
  logic_vector w_mem_wr_in;
  logic w_mem_wr_chip;
  logic w_mem_wr_wr;
  logic w_mem_wr_valid;
  logic[NADDR-1:0] w_mem_wr_addr;

  logic w_end;
  logic w_horizontal_end;
  logic w_wh_end;
  logic w_fin_end;
  logic w_input_end;
  logic w_conv_idle;
  logic w_conv_end;
  logic w_output_idle;


  Memory #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(ROM)
  ) memory_read(
    .clk(clk),
    .reset(reset),
    .chip_en(w_mem_rd_chip),
    .wr_en(w_mem_rd_wr),
    .address(w_mem_rd_addr),
    .data_in(w_mem_rd_in),
    .data_out(w_mem_rd_out),
    .data_valid(w_mem_rd_valid)
  );

  Memory #(
    .NADDR(NADDR),
    .NBITS(NBITS),
    .LATENCY(LATENCY),
    .ROM(0)
  ) memory_write(
    .clk(clk),
    .reset(reset),
    .chip_en(w_mem_wr_chip),
    .wr_en(w_mem_wr_wr),
    .address(w_mem_wr_addr),
    .data_in(w_mem_wr_in),
    .data_out(w_mem_wr_out),
    .data_valid(w_mem_wr_valid)
  );

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st_input  <= IDLE_CONTROL;
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

    w_input_end   = (current_st_input == END_INPUT);
    w_conv_idle   = (current_st_conv == IDLE_CONV);
    w_conv_end    = (current_st_conv == END_CONV);
    w_output_idle = (current_st_output == IDLE_OUTPUT);

    unique case (current_st_input)
      // IDLE:     if (p_start)      next_st = BIAS;
      IDLE_CONTROL: begin
        if (p_start)
          next_st_input = WEIGHT;
          p_end = 1'b0;
      end
      IDLE_INPUT: begin
        if (r_count_window == N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN)
          next_st_input = END_CONTROL;
        else
        // if (r_count_window == N_WINDOW * N_WINDOW * N_CHANNEL_OUT)
        //  next_st_input = BIAS;
        // else
        if (r_count_window == N_WINDOW * N_WINDOW)
          next_st_input = WEIGHT;
        else
          next_st_input = ADDR_INPUT;
      end
      BIAS:
          next_st_input = WEIGHT;
      WEIGHT: begin
        // w_wh_end = 1'b0;
        if (r_count_wh == (M1_SIZE * M2_SIZE)) begin
          next_st_input = ADDR_INPUT;
          w_wh_end = 1'b1;
        end
      end
      ADDR_INPUT:
        next_st_input = FEAT_INPUT;
      FEAT_INPUT: begin
        // w_fin_end = 1'b0;
        if (r_count_fin == (C1_SIZE * C2_SIZE)) begin
          next_st_input = END_INPUT;
          w_fin_end = 1'b1;
        end
      end
      END_INPUT:
        if (w_conv_idle)
          next_st_input = IDLE_INPUT;
    endcase

    unique case (current_st_conv)
      IDLE_CONV:
        if (w_input_end)
          next_st_conv = CONV;
      CONV:
        if (p_end_conv[2])
          next_st_conv = END_CONV;
      default:
        if (w_output_idle)
          next_st_conv = IDLE_CONV;
    endcase

    unique case (current_st_output)
      IDLE_OUTPUT:
        if (w_conv_end)
          next_st_output = FEAT_OUTPUT;
      ADDR_OUTPUT:
        next_st_output = FEAT_OUTPUT;
      FEAT_OUTPUT:
        if (p_end_conv[3])
          next_st_output = END_OUTPUT;
      END_OUTPUT:
        next_st_output = IDLE_OUTPUT;
    endcase

    // p_wh_en    <= r_wh_en;
    // p_fin_en   <= r_fin_en;
    p_out_data <= w_mem_rd_out;

    w_mem_wr_addr <= r_addr_fout[r_count_fout];
    w_mem_wr_chip <= p_fout_en;
    w_mem_wr_wr   <= p_fout_en;
    w_mem_wr_in   <= p_in_data;

    // Wire control
    p_wh_en <= 1'b0;
    p_fin_en <= 1'b0;
    p_wh_valid  <= 1'b0;
    p_fin_valid <= 1'b0;
    w_fin_end = 1'b0;
    w_wh_end = 1'b0;
    unique case (current_st_input)
      BIAS: begin
        w_mem_rd_addr <= r_addr_bias;
        // w_mem_rd_chip   <= r_bias_en;
        // p_bias_en    <= r_bias_en;
        // p_bias_valid <= w_mem_rd_valid;
      end
      WEIGHT: begin
        w_mem_rd_addr  <= r_addr_wh;
        w_mem_rd_chip  <= r_wh_en;
        p_wh_valid  <= w_mem_rd_valid;
        p_wh_en <= 1'b1;
      end
      END_CONTROL:
        p_end = 1'b1;
      FEAT_INPUT: begin
        w_mem_rd_addr  <= r_addr_fin[r_count_fin];
        w_mem_rd_chip  <= r_fin_en;
        p_fin_valid <= w_mem_rd_valid;
        p_fin_en <= 1'b1;
      end
      default: begin end
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
        IDLE_CONTROL: begin
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
        BIAS: begin
          r_addr_bias <= r_addr_bias + 1;
        end
        WEIGHT: begin
          r_wh_en      <= 1'b1;
          r_fin_en     <= 1'b0;
          r_count_fin  <= 0;
          if (w_mem_rd_valid) begin
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
          // TODO: Implement w_mem_rd_addr generation logic using if else statements and remove
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
          if (w_mem_rd_valid)
            r_count_fin <= r_count_fin + 1;
          // if (w_fin_end)
          //   r_fin_en <= 1'b0;
          // else
          //   r_fin_en <= 1'b1;
        end
        default: begin end
      endcase

      unique case (current_st_conv)
        IDLE_CONV: begin
          if (w_input_end)
            r_start_conv <= 1'b1;
          else
            r_start_conv <= 1'b0;
        end
        CONV: begin
          r_start_conv <= 1'b0;
        end
        END_CONV: begin end
      endcase

      unique case (current_st_output)
        IDLE_OUTPUT: begin
          // r_addr_fout_base <= 0;
          // r_reuse          <= 1'b0;
          r_count_fout <= 0;
        // end
        // ADDR_OUTPUT: begin
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
          if (p_fout_valid)
            r_count_fout <= r_count_fout + 1;
        end
        FEAT_OUTPUT: begin
          if (p_fout_valid)
            r_count_fout <= r_count_fout + 1;
          if (p_end_conv[3]) begin
            if (w_horizontal_end)
              r_addr_fout_base <= r_addr_fout_base + A1_SIZE + FEAT_OUTPUT_SIZE * (A1_SIZE - 1);
            else
              r_addr_fout_base <= r_addr_fout_base + A1_SIZE;

          end
        end
        default: begin end
      endcase
    end
  end
endmodule
