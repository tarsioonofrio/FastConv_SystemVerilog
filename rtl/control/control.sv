module Control
  import pack_def::*;
  import pack_typedef::*;
  import pack_param::*;
#(
    parameter int NADDR            = 16,
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
    input  logic clk,
    input  logic reset,

    input  logic p_start,
    output logic p_end,
    output logic p_conv_start,
    input  logic p_conv_end,

    output type_input  p_input,
    output type_weight p_weight,
    input  type_output p_output,

    output logic p_read_en,
    output logic[NADDR-1:0] p_read_addr,
    input  logic_vector p_read_data,
    input  logic p_read_valid,

    output logic p_write_en,
    output logic[NADDR-1:0] p_write_addr,
    output logic_vector p_write_data
);

  timeunit 1ns; timeprecision 1ps;

  typedef enum {
    IDLE_CONTROL,
    BIAS,
    WEIGHT,
    FEAT_INPUT,
    END_CONTROL
  } state_input_type;

  typedef enum {
    IDLE_OUTPUT,
    FEAT_OUTPUT
  } state_output_type;

  state_input_type current_st_input, next_st_input;
  state_output_type current_st_output, next_st_output;

  logic r_en_wh;
  logic r_en_fin;
  // logic r_fout_en;

  logic [$clog2(M1_SIZE*M2_SIZE)-1:0] r_count_wh;
  logic [$clog2(C1_SIZE*C2_SIZE)-1:0] r_count_fin;
  logic [$clog2(A1_SIZE*A2_SIZE)-1:0] r_count_fout;
  // logic [$clog2(N_CHANNEL_OUT)-1:0] r_addr_bias;
  logic [2:0] r_addr_bias;
  logic [$clog2(M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT)-1:0] r_addr_wh;
  logic [$clog2(N_CHANNEL_IN * FEAT_INPUT_SIZE * FEAT_INPUT_SIZE)-1:0] r_addr_fin;
  logic [$clog2(N_CHANNEL_OUT * FEAT_OUTPUT_SIZE * FEAT_OUTPUT_SIZE)-1:0] r_addr_fout;
  logic [$clog2(N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN)-1:0] r_count_window;

  logic [$clog2(N_WINDOW):0] r_count_fin_horizontal;
  logic [$clog2(N_WINDOW):0] r_count_fout_horizontal;

  logic w_end_fin_horizontal;
  logic w_end_fout_horizontal;
  logic w_end_fin;
  logic w_end_fout;
  logic[NADDR-1:0] w_read_addr;
  logic[NADDR-1:0] w_addr_fin;

  type_input  r_feat_in;
  type_weight r_weight;
  type_output r_feat_out;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st_input  <= IDLE_CONTROL;
      current_st_output <= IDLE_OUTPUT;
    end else begin
      current_st_input  <= next_st_input;
      current_st_output <= next_st_output;
    end
  end


  always_comb begin
    p_input      = r_feat_in;
    p_weight     = r_weight;
    p_write_data = r_feat_out[r_count_fout];
    p_end        = (current_st_input == END_CONTROL) ? 1'b1 : 1'b0;
    p_conv_start = w_end_fin;

    if (r_count_fin_horizontal < N_WINDOW - 1)
      w_end_fin_horizontal = 1'b0;
    else
      w_end_fin_horizontal = 1'b1;

    if (r_count_fout_horizontal < N_WINDOW - 1)
      w_end_fout_horizontal = 1'b0;
    else
      w_end_fout_horizontal = 1'b1;
  end

  always_comb begin
    next_st_input  = current_st_input;
    next_st_output = current_st_output;

    unique case (current_st_input)
      // IDLE_CONTROL
      default: begin
        w_end_fin = 1'b0;
        if (p_start)
          next_st_input = WEIGHT;
          // next_st_input = BIAS;
      end
      BIAS: begin
        w_end_fin = 1'b0;
        next_st_input = WEIGHT;
      end
      WEIGHT: begin
        w_end_fin = 1'b0;
        if (r_count_wh == (M1_SIZE * M2_SIZE) - 1) begin
          next_st_input = FEAT_INPUT;
        end
      end
      FEAT_INPUT: begin
        if (r_count_fin == (C1_SIZE * C2_SIZE)) begin
          w_end_fin = 1'b1;
          if (r_count_window == N_WINDOW * N_WINDOW * N_CHANNEL_OUT * N_CHANNEL_IN)
            next_st_input = END_CONTROL;
          else
          // if (r_count_window == N_WINDOW * N_WINDOW * N_CHANNEL_OUT)
          //  next_st_input = BIAS;
          // else
          if (r_count_window == N_WINDOW * N_WINDOW)
            next_st_input = WEIGHT;
          else
            next_st_input = FEAT_INPUT;
        end else
          w_end_fin = 1'b0;
      end
    endcase

    unique case (current_st_output)
      IDLE_OUTPUT: begin
        w_end_fout = 1'b0;
        p_write_en = 1'b0;
        if (p_conv_end)
          next_st_output = FEAT_OUTPUT;
      end
      FEAT_OUTPUT: begin
        p_write_en = 1'b1;
        if (r_count_fout == (A1_SIZE * A2_SIZE) - 1) begin
          next_st_output = IDLE_OUTPUT;
          w_end_fout = 1'b1;
        end else
          w_end_fout = 1'b0;
      end
    endcase
  end

  always_comb begin
    unique case (r_count_fout)
      default: p_write_addr = r_addr_fout + 0;
      1: p_write_addr = r_addr_fout + 1;
      2: p_write_addr = r_addr_fout + 2;

      3: p_write_addr = r_addr_fout + FEAT_OUTPUT_SIZE + 0;
      4: p_write_addr = r_addr_fout + FEAT_OUTPUT_SIZE + 1;
      5: p_write_addr = r_addr_fout + FEAT_OUTPUT_SIZE + 2;

      6: p_write_addr = r_addr_fout + FEAT_OUTPUT_SIZE * 2 + 0;
      7: p_write_addr = r_addr_fout + FEAT_OUTPUT_SIZE * 2 + 1;
      8: p_write_addr = r_addr_fout + FEAT_OUTPUT_SIZE * 2 + 2;
    endcase
  end

  always_comb begin
    unique case (r_count_fin)
      default: w_addr_fin = r_addr_fin + 0; // 00
      01: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE + 0; // 05
      02: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 2 + 0; // 10
      03: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 3 + 0; // 15
      04: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 4 + 0; // 20

      05: w_addr_fin = r_addr_fin + 1; // 01
      06: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE + 1; // 06
      07: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 2 + 1; // 11
      08: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 3 + 1; // 16
      09: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 4 + 1; // 21

      10: w_addr_fin = r_addr_fin + 2; // 02
      11: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE + 2; // 07
      12: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 2 + 2; // 12
      13: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 3 + 2; // 17
      14: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 4 + 2; // 22

      15: w_addr_fin = r_addr_fin + 3; // 03
      16: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE + 3; // 08
      17: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 2 + 3; // 13
      18: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 3 + 3; // 18
      19: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 4 + 3; // 23

      20: w_addr_fin = r_addr_fin + 4; // 04
      21: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE + 4; // 09
      22: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 2 + 4; // 14
      23: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 3 + 4; // 19
      24: w_addr_fin = r_addr_fin + FEAT_INPUT_SIZE * 4 + 4; // 24
    endcase
  end

  always_comb begin
    unique case (current_st_input)
      BIAS: begin
        p_read_addr = r_addr_bias;
        p_read_en = 1'b0;
      end
      WEIGHT: begin
        p_read_addr = r_addr_wh;
        p_read_en = r_en_wh;
      end
      FEAT_INPUT: begin
        p_read_addr = w_addr_fin;
        p_read_en = r_en_fin;
      end
      default: begin
        p_read_addr = 0;
        p_read_en = 1'b0;
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      r_addr_bias      <= 0;
      r_addr_wh        <= N_CHANNEL_OUT;
      r_addr_fin       <= N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT;
      r_addr_fout      <= 0;
      r_count_wh       <= 0;
      r_count_fin      <= 0;
      r_count_fout     <= 0;
      r_count_window   <= 0;
      r_count_fin_horizontal <= 0;
      r_count_fout_horizontal <= 0;
      r_en_wh          <= 1'b0;
      r_en_fin         <= 1'b0;
      r_weight         <= '{default: '0};
      r_feat_in        <= '{default: '0};
      r_feat_out       <= '{default: '0};
    end else begin
      unique case (current_st_input)
        default: begin end
        IDLE_CONTROL: begin
          r_addr_bias      <= 0;
          r_addr_wh        <= N_CHANNEL_OUT;
          r_addr_fin       <= N_CHANNEL_OUT + M1_SIZE * M2_SIZE * N_CHANNEL_IN * N_CHANNEL_OUT;
          r_addr_fout      <= 0;
          r_count_wh       <= 0;
          r_count_fin      <= 0;
          r_count_fout     <= 0;
          r_count_window   <= 0;
          r_count_fin_horizontal <= 0;
          r_count_fout_horizontal <= 0;
          r_en_wh          <= 1'b0;
          r_en_fin         <= 1'b0;
          r_weight         <= '{default: '0};
          r_feat_in        <= '{default: '0};
          r_feat_out       <= '{default: '0};
        end
        BIAS: begin
          r_addr_bias <= r_addr_bias + 1;
        end
        WEIGHT: begin
          r_en_wh      <= 1'b1;
          r_en_fin     <= 1'b0;
          r_count_fin  <= 0;
          if (p_read_valid) begin
            r_addr_wh  <= r_addr_wh + 1;
            r_count_wh <= r_count_wh + 1;
            r_weight[r_count_wh] <= p_read_data;
          end
        end
        FEAT_INPUT: begin
          r_en_fin     <= 1'b1;
          r_en_wh      <= 1'b0;
          r_count_wh   <= 0;
          if (p_read_valid) begin
            r_count_fin <= r_count_fin + 1;
            r_feat_in[c_index[r_count_fin]] <= p_read_data;
          end

          if(w_end_fin) begin
            r_count_wh       <= 0;
            r_count_fin      <= 0;
            r_en_wh          <= 1'b0;
            r_en_fin         <= 1'b0;
            // r_end_wh         <= 1'b0;
            // r_end_fin        <= 1'b0;
            if (w_end_fin_horizontal) begin
              r_count_fin_horizontal <= 0;
              r_count_fin <= 0;
              r_addr_fin <= r_addr_fin + C1_SIZE + FEAT_INPUT_SIZE * (A1_SIZE - 1);
            end else begin
              r_count_fin_horizontal <= r_count_fin_horizontal + 1;
              r_count_window <= r_count_window + 1;
              r_addr_fin <= r_addr_fin + A1_SIZE;

              r_count_fin <= 10;
              // TODO perform test using an index table
              r_feat_in[00] <= r_feat_in[03];
              r_feat_in[01] <= r_feat_in[04];
              r_feat_in[05] <= r_feat_in[08];
              r_feat_in[06] <= r_feat_in[09];
              r_feat_in[10] <= r_feat_in[13];
              r_feat_in[11] <= r_feat_in[14];
              r_feat_in[15] <= r_feat_in[18];
              r_feat_in[16] <= r_feat_in[19];
              r_feat_in[20] <= r_feat_in[23];
              r_feat_in[21] <= r_feat_in[24];
            end
          end
        end
      endcase

      unique case (current_st_output)
        IDLE_OUTPUT: begin
          r_count_fout <= 0;
          if (p_conv_end)
            r_feat_out <= p_output;
        end
        FEAT_OUTPUT: begin
          r_count_fout <= r_count_fout + 1;
          if (w_end_fout)
            if (w_end_fout_horizontal) begin
              r_count_fout_horizontal <= 0;
              r_addr_fout <= r_addr_fout + A1_SIZE + FEAT_OUTPUT_SIZE * (A1_SIZE - 1);
            end else begin
              r_addr_fout <= r_addr_fout + A1_SIZE;
              r_count_fout_horizontal <= r_count_fout_horizontal + 1;
            end
        end
      endcase
    end
  end
endmodule
