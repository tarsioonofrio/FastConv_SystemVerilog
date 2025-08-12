module Core
  import packConv::*;
  import data::*;
#(
    parameter int QUANT = 8,
    parameter int NBITS = 20
) (
    input logic clk, reset,

    input  logic p_start,
    input  logic p_reuse,
    output logic p_end[2:0],

    input logic p_fin_en,
    input logic p_fin_valid,

    input logic p_wh_en,
    input logic p_wh_valid,

    output logic p_fout_en,
    output logic p_fout_valid,

    input  logic_vector p_in_data,
    output logic_vector p_out_data
);

  timeunit 1ns; timeprecision 1ps;

  typedef enum {
    IDLE_INPUT,
    WEIGHT,
    FEAT_IN
  } state_input_type;

  typedef enum {
    IDLE_CONV,
    CONV_C,
    CONV_H,
    CONV_A
  } state_conv_type;

  typedef enum {
    IDLE_OUTPUT,
    FEAT_OUT
  } state_output_type;


  state_input_type current_st_input, next_st_input;
  state_conv_type current_st_conv, next_st_conv;
  state_output_type current_st_output, next_st_output;

  type_input  r_feat_in;
  type_weight r_weight;
  type_weight r_temp;
  type_output r_feat_out;

  type_weight w_prod_c;
  type_output w_prod_a;

  logic r_reuse;
  logic r_fout_en;
  logic r_conv_end;
  logic r_end[2:0];
  logic r_fout_valid;

  logic w_end[2:0];
  logic w_end_conv;

  int r_count_wh;
  int r_count_fin;
  int r_count_fout;

  logic [6:0] r_mult_idx;

  logic signed [NBITS-1+QUANT:0] product;  // QUANT more bits for the multipliers

  logic [1:0] w_wh_fin_en;


  const int c_index[5*5] = {
    00, 05, 10, 15, 20,
    01, 06, 11, 16, 21,
    02, 07, 12, 17, 22,
    03, 08, 13, 18, 23,
    04, 09, 14, 19, 24
  };

  //
  // BLOCK: Control FSM
  //


  always_comb begin
    p_end = r_end;
    p_fout_en = r_fout_en;
    p_fout_valid = r_fout_valid;
    // saving one register[NBITS] for data output
    p_out_data = r_feat_out[r_count_fout - 1];
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st_input  <= IDLE_INPUT;
      current_st_conv   <= IDLE_CONV;
      current_st_output <= IDLE_OUTPUT;
    end else begin
      current_st_input  <= next_st_input;
      current_st_conv   <= next_st_conv;
      current_st_output <= next_st_output;
    end
  end

  always_comb begin
    w_end = '{1'b0, 1'b0, 1'b0};

    // if (p_wh_en) next_st_input = WEIGHT;
    // else if (p_fin_en) next_st_input = FEAT_IN;
    // else next_st_input = IDLE_INPUT;

    w_wh_fin_en = {p_wh_en, p_fin_en};
    unique case (w_wh_fin_en)
      2'b10: next_st_input = WEIGHT;
      2'b01: next_st_input = FEAT_IN;
      default: next_st_input = IDLE_INPUT;
    endcase


    // unique case (current_st_input)
    //   IDLE_INPUT: begin
    //     w_end[0] = 1'b0;
    //     w_end[1] = 1'b0;
    //     if (p_wh_en) next_st_input = WEIGHT;
    //     else if (p_fin_en) next_st_input = FEAT_IN;
    //   end
    //   WEIGHT: begin
    //     w_end[1] = 1'b0;
    //     if (r_count_wh == (M1_SIZE * M2_SIZE)) begin
    //       next_st_input = FEAT_IN;
    //       w_end[0] = 1'b1;
    //     end
    //   end
    //   FEAT_IN: begin
    //     w_end[0] = 1'b0;
    //     if (r_count_fin == (C1_SIZE * C2_SIZE)) begin
    //       next_st_input = IDLE_INPUT;
    //       w_end[1] = 1'b1;
    //     end
    //   end
    // endcase

    unique case (current_st_conv)
      IDLE_CONV: begin
        w_end_conv = 1'b0;
        if (p_start) next_st_conv = CONV_C;
      end
      CONV_C:
        next_st_conv = CONV_H;
      CONV_H:
        if (r_mult_idx == (M1_SIZE * M2_SIZE - 1))
          next_st_conv = CONV_A;
      CONV_A: begin
        w_end_conv = 1'b1;
        next_st_conv = IDLE_CONV;
      end
    endcase

    unique case (current_st_output)
      IDLE_OUTPUT: begin
        w_end[2] = 1'b0;
        if (w_end_conv) next_st_output = FEAT_OUT;
      end
      FEAT_OUT: begin
        if (r_count_fout == (A1_SIZE * A2_SIZE)) begin
          next_st_output = IDLE_OUTPUT;
          w_end[2] = 1'b1;
        end
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      r_weight <= '{default: '0};
      r_feat_in <= '{default: '0};
      r_feat_out <= '{default: '0};
      r_count_wh <= 0;
      r_count_fin <= 0;
      r_count_fout <= 0;
      r_reuse <= 1'b0;
      r_fout_en <= 1'b0;
      r_conv_end <= 1'b0;
      r_mult_idx <= 1'b0;
      r_fout_valid <= 1'b0;
      r_end = '{1'b0, 1'b0, 1'b0};
    end else begin
      unique case (current_st_input)
        IDLE_INPUT: begin
          r_end[0] = 1'b0;
          r_end[1] = 1'b0;
          r_count_wh <= 0;
          r_count_fout <= 0;
          r_reuse <= p_reuse;
          if (p_reuse) begin
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
          end else begin
            r_count_fin <= 0;
          end
        end
        WEIGHT: begin
          // r_count_fin <= 0;
          // r_count_fout <= 0;
          r_end[0] <= w_end[0];
          r_end[1] <= w_end[1];
          if (p_wh_valid) begin
            r_weight[r_count_wh] <= p_in_data;
            r_count_wh           <= r_count_wh + 1;
          end
        end
        FEAT_IN: begin
          // r_count_wh <= 0;
          // r_count_fout <= 0;
          r_end[0] <= w_end[0];
          r_end[1] <= w_end[1];
          if (p_fin_valid) begin
            r_feat_in[c_index[r_count_fin]] <= p_in_data;
            r_count_fin                     <= r_count_fin + 1;
          end
        end
      endcase

      unique case (current_st_conv)
        IDLE_CONV: begin
          r_conv_end <= 1'b0;
          r_mult_idx <= 1'b0;
        end
        CONV_C: begin
          r_temp <= w_prod_c;
        end
        CONV_H: begin
          r_temp[r_mult_idx] <= product;
          r_mult_idx         <= r_mult_idx + 1;
        end
        CONV_A: begin
          r_feat_out <= w_prod_a;
          r_conv_end <= 1'b1;
        end
      endcase

      unique case (current_st_output)
        IDLE_OUTPUT: begin
          r_end[2]     <= 1'b0;
          r_fout_en    <= 1'b0;
          r_conv_end   <= 1'b0;
          r_fout_valid <= 1'b0;
          r_count_fout <= 0;
          // r_feat_out   <= '{default: '0};
        end
        FEAT_OUT: begin
          r_end[2]     <= w_end[2];
          r_count_fout <= r_count_fout + 1;
          if (w_end[2]) begin
            r_fout_en    <= 1'b0;
            r_fout_valid <= 1'b0;
          end else begin
            r_fout_en    <= 1'b1;
            r_fout_valid <= 1'b1;
          end
        end
      endcase
    end
  end


  // BLOCK: Convolution
  //
  // Data path
  //

  // Instance of matrix multiplier "C"
  Transform trf (
      .pin (r_feat_in[C1_SIZE*C1_SIZE-1:0]),
      .pout(w_prod_c)
  );

  // assign r_mult_idx = current_st_conv;

  Multip multip0 (
      .register(r_temp[r_mult_idx]),
      .weight  (r_weight[r_mult_idx]),
      .product (product)
  );

  // Instance of matrix multiplier "A"
  Inverse inv (
      .pin (r_temp),
      .pout(w_prod_a)
  );
endmodule


module Multip
  import packConv::*;
#(
    parameter int QUANT = 8,
    parameter int NBITS = 20
) (
    input logic_vector register,
    input logic_vector weight,
    output logic signed [NBITS-1+QUANT:0] product
);
  timeunit 1ns; timeprecision 1ps;
  logic signed [NBITS-1+QUANT:0] partial_product;

  assign partial_product = (NBITS + QUANT)'($signed(register) * $signed(weight));
  assign product = (NBITS)'(partial_product[NBITS-1+QUANT:QUANT]);
endmodule
