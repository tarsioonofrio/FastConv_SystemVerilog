module Conv
  import pack_def::*;
  import pack_param::*;
  import pack_typedef::*;
  import pack_mux_mult::*;
#(
    parameter int QUANT = 8,
    parameter int NBITS = 20
) (
    input logic clk, reset,

    input  logic p_start,
    output logic p_end,
    output logic p_idle,
    input  type_input  p_input,
    input  type_weight p_weight,
    output type_output p_output
);

  timeunit 1ns;
  timeprecision 1ps;

  typedef enum {
    IDLE_CONV,
    MATRIX_C,
    HADAMARD,
    MATRIX_A
  } state_type;

  state_type current_state, next_state;

  type_weight r_feat;

  type_weight w_prod_c;
  type_output w_prod_a;

  logic [$clog2(SMULT-1):0] r_idx_in;
  logic [$clog2(SMULT*NMULT-1):0] r_idx_out[0:NMULT-1];

  logic signed [NBITS-1+QUANT:0] product [0:NMULT-1];

  logic w_matrix_c_enable;
  logic w_hadamard_enable;
  logic w_matrix_a_enable;
  logic w_idx_in_enable;
  logic w_feat_load_enable;
  logic w_feat_hadamard_enable;

  type_input  w_trf_input;
  type_weight w_inv_input;

  //
  // BLOCK: Control FSM
  //

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_state   <= IDLE_CONV;
    end else begin
      current_state   <= next_state;
    end
  end

  always_comb begin
    next_state  = current_state;

    unique case (current_state)
      IDLE_CONV:
        if (p_start) next_state = MATRIX_C;
      MATRIX_C:
        next_state = HADAMARD;
      HADAMARD:
        if (r_idx_in == (SMULT - 1))
          next_state = MATRIX_A;
      MATRIX_A:
        next_state = IDLE_CONV;
    endcase
  end

  assign w_matrix_c_enable = (current_state == MATRIX_C);
  assign w_hadamard_enable = (current_state == HADAMARD);
  assign w_matrix_a_enable = (current_state == MATRIX_A);
  assign w_idx_in_enable = w_hadamard_enable;
  assign w_feat_load_enable = (current_state == IDLE_CONV) && p_start;
  assign w_feat_hadamard_enable = w_hadamard_enable;

  always_ff @(posedge clk) begin
    if (reset) begin
      r_idx_in <= 1'b0;
      r_feat <= '{default: '0};
    end else begin
      if (current_state == IDLE_CONV) begin
        r_idx_in <= 1'b0;
      end else if (w_idx_in_enable) begin
        r_idx_in <= r_idx_in + 1;
      end

      if (w_feat_load_enable) begin
        r_feat[C1_SIZE*C1_SIZE-1:0] <= p_input;
      end else if (w_matrix_c_enable) begin
        r_feat <= w_prod_c;
      end else if (w_feat_hadamard_enable) begin
        for (int i = 0; i < NMULT; i++) begin
          r_feat[r_idx_out[i]] <= product[i];
        end
      end
    end
  end

  // Block Data path with operand isolation

  assign w_trf_input = w_matrix_c_enable ? r_feat[C1_SIZE*C1_SIZE-1:0] : '{default: '0};
  assign w_inv_input = w_matrix_a_enable ? r_feat : '{default: '0};

  // Instance of matrix multiplier "C"
  Transform trf (
      .pin (w_trf_input),
      .pout(w_prod_c)
  );

  MuxMult mux_mult(
    .idx_in(w_hadamard_enable ? r_idx_in : '0),
    .idx_out(r_idx_out)
  );

  generate
    for (genvar i = 0; i < NMULT; i++) begin
      logic_vector w_mult_register;
      logic_vector w_mult_weight;

      assign w_mult_register = w_hadamard_enable ? r_feat[r_idx_out[i]] : '0;
      assign w_mult_weight   = w_hadamard_enable ? p_weight[r_idx_out[i]] : '0;

      Multip #(
        .QUANT(QUANT),
        .NBITS(NBITS)
      )
      multip(
        .register_input(w_mult_register),
        .weight_input(w_mult_weight),
        .product(product[i])
      );
    end
  endgenerate

  // Instance of matrix multiplier "A"
  Inverse inv (
      .pin (w_inv_input),
      .pout(w_prod_a)
  );

  always_comb begin
    p_idle = (current_state == IDLE_CONV) ? 1'b1 : 1'b0;
    p_end = (current_state == MATRIX_A) ? 1'b1 : 1'b0;
    p_output = w_matrix_a_enable ? w_prod_a : '{default: '0};
  end
endmodule


module Multip
  import pack_typedef::*;
#(
    parameter int QUANT = 8,
    parameter int NBITS = 20
) (
    input logic_vector register_input,
    input logic_vector weight_input,
    output logic signed [NBITS-1+QUANT:0] product
);
  timeunit 1ns; timeprecision 1ps;
  logic signed [NBITS-1+QUANT:0] partial_product;

  assign partial_product = (NBITS + QUANT)'($signed(register_input) * $signed(weight_input));
  assign product = (NBITS)'(partial_product[NBITS-1+QUANT:QUANT]);
endmodule
