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

    input  logic_vector p_fin_data,
    output logic_vector p_fout_data
);

  timeunit 1ns; timeprecision 1ps;

  typedef enum {
    IDLE,
    WEIGHT,
    FEAT_IN,
    CONV,
    FEAT_OUT
  } state_type;

  state_type current_st, next_st;
  state_type_conv current_st_conv, next_st_conv;

  type_weight r_weight;
  type_weight r_feat_in;
  type_output r_feat_out;

  type_weight w_prod_c;
  type_output w_prod_a;

  logic r_fout_en;
  logic r_conv_end;
  logic r_data_end;
  logic r_fout_valid;

  int r_count_in;
  int r_count_out;

  logic [5:0] r_mult_idx;

  logic signed [NBITS-1+QUANT:0] product;  // QUANT more bits for the multipliers


  //
  // BLOCK: Control FSM
  //


  always_comb begin
    p_end = r_data_end;
    p_fout_en = r_fout_en;
    p_fout_valid = r_fout_valid;
    // saving one register[NBITS] for data output
    p_fout_data = r_feat_out[r_count_out-1];
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st <= IDLE;
    end else begin
      current_st <= next_st;
    end
  end

  always_comb begin
    unique case (current_st)
      IDLE:
        if (p_wh_en) next_st = WEIGHT;
        else if (p_fin_en) next_st = FEAT_IN;
        else if (p_start) next_st = CONV;
      WEIGHT:   if (r_data_end) next_st = IDLE;
      FEAT_IN:  if (r_data_end) next_st = IDLE;
      CONV:     if (r_conv_end) next_st = FEAT_OUT;
      FEAT_OUT: if (r_data_end) next_st = IDLE;
    endcase
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      r_weight <= '{default: '0};
      r_feat_in <= '{default: '0};
      r_feat_out <= '{default: '0};
      r_count_out <= 0;
      r_count_in <= 0;
      r_fout_en <= 1'b0;
      r_data_end <= 1'b0;
      r_conv_end <= 1'b0;
      r_mult_idx <= 1'b0;
      r_fout_valid <= 1'b0;
    end else begin
      unique case (current_st)
        IDLE: begin
          r_feat_out <= '{default: '0};
          r_fout_en <= 1'b0;
          r_data_end <= 1'b0;
          r_conv_end <= 1'b0;
          r_mult_idx <= 1'b0;
          r_fout_valid <= 1'b0;
        end
        WEIGHT: begin
          if (p_wh_valid && (r_count_in < M1_SIZE * M2_SIZE)) begin
            r_weight[r_count_in] <= p_fin_data;
            r_count_in <= r_count_in + 1;
            r_data_end <= 1'b0;
          end else begin
            r_count_in <= 1'b0;
            r_data_end <= 1'b1;
          end
        end
        FEAT_IN: begin
          if (p_fin_valid && (r_count_in < C1_SIZE * C2_SIZE)) begin
            r_feat_in[r_count_in] <= p_fin_data;
            r_count_in <= r_count_in + 1;
            r_data_end <= 1'b0;
          end else begin
            r_count_in <= 1'b0;
            r_data_end <= 1'b1;
          end
        end
        CONV: begin
          unique case (current_st_conv)
            WR_MC: r_feat_in <= w_prod_c;
            MU: begin
              r_feat_in[r_mult_idx] <= product;
              r_mult_idx <= r_mult_idx + 1;
            end
            WR_OUT: begin
              r_feat_out <= w_prod_a;
              r_conv_end <= 1'b1;
            end
            default: begin end
          endcase
        end
        FEAT_OUT: begin
          if (r_count_out < (A1_SIZE * A2_SIZE)) begin
            r_count_out  <= r_count_out + 1;
            r_fout_en <= 1'b1;
            r_fout_valid <= 1'b1;
          end else begin
            r_count_out  <= 1'b0;
            r_fout_en <= 1'b0;
            r_data_end <= 1'b1;
            r_fout_valid <= 1'b0;
          end
        end
      endcase
    end
  end


  // BLOCK: Convolution


  //
  // Control FSM
  //

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st_conv <= IDLE1;
    end else begin
      current_st_conv <= next_st_conv;
    end
  end

  always_comb begin
    unique case (current_st_conv)
      IDLE1: next_st_conv = p_start ? WR_MC : IDLE1;
      WR_MC: next_st_conv = MU;
      MU:
        if (r_mult_idx < (M1_SIZE * M2_SIZE - 1))
          next_st_conv = MU;
        else
          next_st_conv = WR_OUT;
      WR_OUT: next_st_conv = IDLE1;
    endcase
  end

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
