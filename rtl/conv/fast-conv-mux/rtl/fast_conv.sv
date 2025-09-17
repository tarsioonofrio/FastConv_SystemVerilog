//-------------------------------------------------------------------------
// FERNANDO MORAES                                          24/October/2024
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------
// FAST CONVOLUTION
//-------------------------------------------------------------------------
import packConv::*;
import data::*;
import pack_typedef::*;
import pack_param::*;

module Multip
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
    parameter int NBITS = 20
    // parameter int NMULT = 6,
    // parameter int SMULT = 6
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

  state_type current_st, next_st;

  type_weight   registers;
  type_matrix_c prod_c0;
  type_weight   prod_c;
  type_output   prod_a;

  logic signed[NBITS-1+QUANT:0] product[0:NMULT-1];   // QUANT more bits for the multipliers

  logic[6:0] idx[0:NMULT-1];


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
      WR_MC:    next_st = MULT0;
      WR_OUT:   next_st = IDLE;
      default: next_st = state_type'(current_st + 1);
    endcase
  end

  //
  // Data path
  //

  // Instance of matrix multiplier "C"
  Transform trf(
    .pin(registers[C1_SIZE*C1_SIZE-1:0]),
    .pout(prod_c)
  );

  // assign idx = addr[current_st];

  typedef logic[5:0] idx_in_logic;

  MuxMult mux_mult(
    .idx_in(idx_in_logic'(current_st)),
    .idx_out(idx)
  );

  generate
    for (genvar i = 0; i < NMULT; i++) begin
      Multip multip(.register(registers[idx[i]]), .weight(weights[idx[i]]), .product(product[i]));
    end
  endgenerate

  // Instance of matrix multiplier "A"
  Inverse inv(
    .pin(registers),
    .pout(prod_a)
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
        WR_IFMAP: registers[C1_SIZE*C1_SIZE-1:0] <= inputMAP;
        WR_MC:    registers <= prod_c;
        WR_OUT: begin
          data_valid <= 1;
          registers[A1_SIZE*A1_SIZE-1:0] <= prod_a;
        end
        default:  begin
          for (int i = 0; i < NMULT; i++) begin
            registers[idx[i]] <= product[i];
          end
        end
      endcase
    end
  end

  // connect 9 first registers to the outputs
  always_comb begin
    outputMAP = registers[A1_SIZE*A1_SIZE-1:0];
  end

endmodule
