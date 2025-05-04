//-------------------------------------------------------------------------
// FERNANDO MORAES                                          24/October/2024
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------
// FAST CONVOLUTION
//-------------------------------------------------------------------------

module Multip
  import packConv::*;
 #(
  parameter int QUANT = 8,
  parameter int NBITS = 20
  )
  (
    input  logic_vector register,
    input  logic_vector weight,
    output logic signed [NBITS-1+QUANT:0] product
 );
  timeunit 1ns;
  timeprecision 1ps;
  logic signed [NBITS-1+QUANT:0] partial_product;

  assign partial_product = (NBITS+QUANT)'($signed(register) * $signed(weight));
  assign product = (NBITS)'(partial_product[NBITS-1+QUANT:QUANT]);
endmodule


module conv
  import packConv::*;
 #(
    parameter int QUANT = 8,
    parameter int NBITS = 20,
    parameter int NMULT = 36
  )
  (
    input  logic       clk, reset, start,
    input  type_input  inputMAP,
    input  type_weight weights,
    output type_output outputMAP,
    output logic       data_valid
 );

  timeunit 1ns;
  timeprecision 1ps;
  localparam int SMULT = 2;

  // MU[SMULT]
  typedef enum {IDLE, WR_IFMAP, WR_MC, MU, WR_OUT} state_type;
  state_type current_st, next_st;

  type_weight   registers;
  type_matrix_c prod_c0;
  type_weight   prod_c1;
  type_matrix_a prod_a1;
  type_output   prod_a0;

  logic signed[NBITS-1+QUANT:0] product[0:NMULT-1];   // QUANT more bits for the multipliers

  //
  // Control FSM
  //

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      current_st <= IDLE;
    end else begin
      current_st <= next_st;
    end
  end

  // 9 states + IDEL - IDLE is blocking!
  always_comb begin
    unique case (current_st)
      IDLE:     next_st = start ? WR_IFMAP : IDLE;
      WR_IFMAP: next_st = WR_MC;
      WR_MC:    next_st = MU;
      MU:       next_st = WR_OUT;
      default:   next_st = IDLE;
    endcase
  end

  //
  // Data path
  //

  // Instance of matrix multiplier "C"
  MatrixC0 matrix_c0(
    .P(registers[24:0]),
    .soma(prod_c0)
  );

  MatrixC1 matrix_c1(
    .P(prod_c0),
    .soma(prod_c1)
  );

  generate
    for (genvar i = 0; i < NMULT; i++) begin
      Multip multip(.register(registers[i]), .weight(weights[i]), .product(product[i]));
    end
  endgenerate

  // Instance of matrix multiplier "A"
  MatrixA1 matrix_a1 (
    .P(registers),
    .soma(prod_a1)
  );

  MatrixA0 matrix_a0 (
    .P(prod_a1),
    .soma(prod_a0)
  );

  // Internal register bank to store intermediate results
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      registers <= '{default: '0};
      data_valid <= 0;
    end else begin
      data_valid <= 0;
      unique case (current_st)
        IDLE:     registers <= registers;
        WR_IFMAP: registers[24:0] <= inputMAP;
        WR_MC:    registers <= prod_c1;
        WR_OUT: begin
          data_valid <=1;
          registers[8:0] <= prod_a0;
        end
        default:  begin
          for (int i = 0; i < NMULT; i++) begin
            registers[i] <= product[i];
          end
        end
      endcase
    end
  end

  // connect 9 first registers to the outputs
  always_comb begin
    outputMAP = registers[8:0];
  end

endmodule
