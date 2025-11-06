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

  logic r_end;

  logic [$clog2(SMULT-1):0] r_idx_in;
  logic [$clog2(SMULT*NMULT-1):0] r_idx_out[0:NMULT-1];

  logic signed [NBITS-1+QUANT:0] product [0:NMULT-1];  // QUANT more bits for the multipliers

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
    p_output = w_prod_a;
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

  always_ff @(posedge clk) begin
    if (reset) begin
      r_idx_in <= 1'b0;
      r_end <= 1'b0;
    end else begin
      unique case (current_state)
        IDLE_CONV: begin
          r_idx_in <= 1'b0;
          if (p_start) begin
            r_feat[C1_SIZE*C1_SIZE-1:0] <= p_input;
          end
        end
        MATRIX_C: begin
          r_feat <= w_prod_c;
          r_end <= 1'b0;
        end
        HADAMARD: begin
          r_idx_in <= r_idx_in + 1;
          for (int i = 0; i < NMULT; i++) begin
            r_feat[r_idx_out[i]] <= product[i];
          end
        end
        MATRIX_A: begin
          r_end <= 1'b1;
        end
      endcase
    end
  end

  // Block Data path

  // Instance of matrix multiplier "C"
  Transform trf (
      .pin (r_feat[C1_SIZE*C1_SIZE-1:0]),
      .pout(w_prod_c)
  );

  MuxMult mux_mult(
    .idx_in(r_idx_in),
    .idx_out(r_idx_out)
  );

  generate
    for (genvar i = 0; i < NMULT; i++) begin
      Multip #(
        .QUANT(QUANT),
        .NBITS(NBITS)
      )
      multip(
        .register(r_feat[r_idx_out[i]]),
        .weight(p_weight[r_idx_out[i]]),
        .product(product[i])
      );
    end
  endgenerate

  // Instance of matrix multiplier "A"
  Inverse inv (
      .pin (r_feat),
      .pout(w_prod_a)
  );

  always_comb begin
    p_idle = (current_state == IDLE_CONV) ? 1'b1 : 1'b0;
    // p_end = (current_state == MATRIX_A) ? 1'b1 : 1'b0;
    p_end = ((current_state == MATRIX_A) || r_end) ? 1'b1 : 1'b0;
  end
endmodule


module Multip
  import pack_typedef::*;
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
