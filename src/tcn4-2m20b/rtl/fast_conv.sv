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

  logic signed [NBITS-1+QUANT:0] product[0:4];   // QUANT more bits for the multipliers

  logic [4:0] m0, m1;

  typedef enum {IDLE, WR_IFMAP, WR_C, MU1, MU2, MU3, MU4, MU5, MU6, MU7, MU8, WR_OUT} state_type;

  state_type EA, PE;

  //
  // Control FSM
  //
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      EA <= IDLE;
    end else begin
      EA <= PE;
    end
  end

  always_comb begin
    unique case (EA)
      IDLE:     PE = start ? WR_IFMAP : IDLE;
      WR_IFMAP: PE = WR_C;
      WR_C:     PE = MU1;

      MU1:     PE = MU2;
      MU2:     PE = MU3;
      MU3:     PE = MU4;
      MU4:     PE = MU5;
      MU5:     PE = MU6;
      MU6:     PE = MU7;
      MU7:     PE = MU8;
      MU8:     PE = WR_OUT;
      WR_OUT:  PE = IDLE;
      default: PE = IDLE;
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
    unique case (EA)
      MU1: begin m0= 0; m1= 1; end
      MU2: begin m0= 2; m1= 3; end
      MU3: begin m0= 4; m1= 5; end
      MU4: begin m0= 6; m1= 7; end
      MU5: begin m0= 8; m1= 9; end
      MU6: begin m0=10; m1=11; end
      MU7: begin m0=12; m1=13; end
      default: begin m0=14; m1=15; end
    endcase
  end

  Multip multip0(.register(registers[m0]), .weight(weights[m0]), .product(product[0]));
  Multip multip1(.register(registers[m1]), .weight(weights[m1]), .product(product[1]));

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
    //outputMAP <= '{default: '0};
    data_valid <= 0;
  end
  else begin
    data_valid <= 0;  // default
      unique case (EA)
        WR_IFMAP: registers <= inputMAP;
        WR_C:     registers <= prod_c1;
        MU1, MU2, MU3, MU4, MU5, MU6, MU7, MU8:  begin
          registers[m0] <= product[0];
          registers[m1] <= product[1];
        end
        WR_OUT: data_valid <= 1;
        default: begin   // necessary - wrong behavior in logic simulation
          registers <= registers;
        end
      endcase
    end
  end

  always_latch begin
    if (EA==WR_OUT) begin
        outputMAP = prod_a0;   /// saída em latch
      end
  end

endmodule
