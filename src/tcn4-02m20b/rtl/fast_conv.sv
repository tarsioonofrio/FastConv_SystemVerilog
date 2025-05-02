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

  logic [4:0] idx[0:1];

  typedef enum {IDLE, WR_IFMAP, WR_C, MU1, MU2, MU3, MU4, MU5, MU6, MU7, MU8, WR_OUT} state_type;

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
      WR_C:     next_st = MU1;

      MU1:     next_st = MU2;
      MU2:     next_st = MU3;
      MU3:     next_st = MU4;
      MU4:     next_st = MU5;
      MU5:     next_st = MU6;
      MU6:     next_st = MU7;
      MU7:     next_st = MU8;
      MU8:     next_st = WR_OUT;
      WR_OUT:  next_st = IDLE;
      default: next_st = IDLE;
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
      MU1: begin idx[0]= 0; idx[1]= 1; end
      MU2: begin idx[0]= 2; idx[1]= 3; end
      MU3: begin idx[0]= 4; idx[1]= 5; end
      MU4: begin idx[0]= 6; idx[1]= 7; end
      MU5: begin idx[0]= 8; idx[1]= 9; end
      MU6: begin idx[0]=10; idx[1]=11; end
      MU7: begin idx[0]=12; idx[1]=13; end
      default: begin idx[0]=14; idx[1]=15; end
    endcase
  end

  Multip multip0(.register(registers[idx[0]]), .weight(weights[idx[0]]), .product(product[0]));
  Multip multip1(.register(registers[idx[1]]), .weight(weights[idx[1]]), .product(product[1]));

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
      unique case (current_st)
        WR_IFMAP: registers <= inputMAP;
        WR_C:     registers <= prod_c1;
        MU1, MU2, MU3, MU4, MU5, MU6, MU7, MU8:  begin
          registers[idx[0]] <= product[0];
          registers[idx[1]] <= product[1];
        end
        WR_OUT: data_valid <= 1;
        default: begin   // necessary - wrong behavior in logic simulation
          registers <= registers;
        end
      endcase
    end
  end

  always_latch begin
    if (current_st==WR_OUT) begin
        outputMAP = prod_a0;   /// saída em latch
      end
  end

endmodule
