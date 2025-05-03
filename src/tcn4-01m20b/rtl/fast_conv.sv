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
    parameter int QUANT = 8
  )
  (
    input  logic       clk, reset, start,
    input  type_input  inputMAP,
    input  type_input  weights,
    output type_output outputMAP,
    output logic       data_valid
 );

  timeunit 1ns;
  timeprecision 1ps;

  type_input registers, prod_c0;
  type_matrix_c prod_c1;
  type_matrix_a prod_a1;
  type_output prod_a0;

  logic signed [NBITS-1+QUANT:0] product;   // QUANT more bits for the multipliers

  logic [4:0] idx;

  typedef enum {IDLE, WR_IFMAP, WR_C, MU[16], WR_OUT} state_type;

  state_type current_st, next_st;

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

  always_comb begin
    unique case (current_st)
      IDLE:     next_st = start ? WR_IFMAP : IDLE;
      WR_IFMAP: next_st = WR_C;
      WR_OUT:   next_st = IDLE;
      // default:  next_st = current_st.next();
      default: next_st = state_type'(current_st + 1);
    endcase
  end

  //
  // Data path
  //

  // Instance of matrix multiplier "C"
  MatrixC0 matrix_c0(
    .P(registers),
    .soma(prod_c0)
  );

  MatrixC1 matrix_c1(
    .P(prod_c0),
    .soma(prod_c1)
  );


  // 4 multipliers inside this block
 always_comb begin
   unique case (current_st)
     MU0:  idx=0;
     MU1:  idx=1;
     MU2:  idx=2;
     MU3:  idx=3;
     MU4:  idx=4;
     MU5:  idx=5;
     MU6:  idx=6;
     MU7:  idx=7;
     MU8:  idx=8;
     MU9:  idx=9;
     MU10: idx=10;
     MU11: idx=11;
     MU12: idx=12;
     MU13: idx=13;
     MU14: idx=14;
     default: idx=15;
   endcase
 end


  //  // 4 multipliers inside this block
  // always_comb begin
  //   if (current_st >= MU0 && current_st <= MU15)
  //     idx = current_st - MU0;
  //   else
  //     idx = 15;
  // end

  Multip multip0(.register(registers[idx]), .weight(weights[idx]), .product(product));


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
  end
  else begin
    data_valid <= 0;  // default
      unique case (current_st)
        IDLE:     registers <= registers;
        WR_IFMAP: registers <= inputMAP;
        WR_C:     registers <= prod_c1;
        default:  begin
          registers[idx] <= product;
        end
        WR_OUT: data_valid <= 1;
      endcase
    end
  end

  always_latch begin
    if (current_st==WR_OUT) begin
        outputMAP = prod_a0;   /// saída em latch
      end
  end

endmodule
