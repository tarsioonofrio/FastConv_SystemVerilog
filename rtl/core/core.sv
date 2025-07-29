module Core
  import packConv::*;
  import data::*;
#(
    parameter int QUANT = 8,
    parameter int NBITS = 20
) (
    input logic clk, reset,

    input  logic p_start,
    output logic p_end,
    output logic p_debug,

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
    IDLE,
    WEIGHT,
    FEAT_IN,
    CONV_C,
    CONV_H,
    CONV_A,
    FEAT_OUT
  } state_type;

  state_type current_st, next_st;

  type_weight r_weight;
  type_weight r_feat_in;
  type_output r_feat_out;

  type_weight w_prod_c;
  type_output w_prod_a;

  logic r_fout_en;
  logic r_conv_end;
  logic r_end;
  logic r_fout_valid;

  logic w_end_fout;

  int r_count_wh;
  int r_count_fin;
  int r_count_fout;

  logic [6:0] r_mult_idx;

  logic signed [NBITS-1+QUANT:0] product;  // QUANT more bits for the multipliers


  //
  // BLOCK: Control FSM
  //


  always_comb begin
    // p_end = r_end;
    p_fout_en = r_fout_en;
    p_fout_valid = r_fout_valid;
    // saving one register[NBITS] for data output
    p_out_data = r_feat_out[r_count_fout - 1];
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st <= IDLE;
    end else begin
      current_st <= next_st;
    end
  end

  always_comb begin
    p_end = 1'b0;
    w_end_fout = 1'b0;
    unique case (current_st)
      IDLE:
        if (p_wh_en) next_st = WEIGHT;
        // else if (p_fin_en) next_st = FEAT_IN;
        // else if (p_start) next_st = CONV_C;
      WEIGHT: begin
        if (r_count_wh == (M1_SIZE * M2_SIZE - 1)) begin
          next_st = FEAT_IN;
          p_end = 1'b1;
        end
      end
      FEAT_IN: begin
        if (r_count_fin == (C1_SIZE * C2_SIZE - 1)) begin
          next_st = CONV_C;
          p_end = 1'b1;
        end
      end
      CONV_C:
        next_st = CONV_H;
      CONV_H:
      if (r_mult_idx == (M1_SIZE * M2_SIZE - 1))
        next_st = CONV_A;
      CONV_A:
        next_st = FEAT_OUT;
      FEAT_OUT: begin
        if (r_count_fout == (A1_SIZE * A2_SIZE)) begin
          next_st = IDLE;
          w_end_fout = 1'b1;
          p_end = 1'b1;
        end else begin

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
      r_fout_en <= 1'b0;
      r_conv_end <= 1'b0;
      r_mult_idx <= 1'b0;
      r_fout_valid <= 1'b0;
    end else begin
      unique case (current_st)
        IDLE: begin
          r_feat_out <= '{default: '0};
          r_fout_en <= 1'b0;
          r_conv_end <= 1'b0;
          r_mult_idx <= 1'b0;
          r_fout_valid <= 1'b0;
        end
        WEIGHT: begin
          r_count_fin <= 0;
          r_count_fout <= 0;
          if (p_wh_valid) begin
            r_weight[r_count_wh] <= p_in_data;
            r_count_wh <= r_count_wh + 1;
          end
        end
        FEAT_IN: begin
          r_count_wh <= 0;
          r_count_fout <= 0;
          if (p_fin_valid) begin
            r_feat_in[r_count_fin] <= p_in_data;
            r_count_fin            <= r_count_fin + 1;
          end
        end
        CONV_C: begin
          r_feat_in <= w_prod_c;
        end
        CONV_H: begin
          r_feat_in[r_mult_idx] <= product;
          r_mult_idx            <= r_mult_idx + 1;
        end
        CONV_A: begin
          r_feat_out <= w_prod_a;
          r_conv_end <= 1'b1;
        end
        FEAT_OUT: begin
          r_count_wh   <= 0;
          r_count_fin  <= 0;
          r_count_fout <= r_count_fout + 1;
          if (w_end_fout) begin
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
      .register(r_feat_in[r_mult_idx]),
      .weight  (r_weight[r_mult_idx]),
      .product (product)
  );

  // Instance of matrix multiplier "A"
  Inverse inv (
      .pin (r_feat_in),
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
