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

  logic signed [NBITS-1+QUANT:0] product[0:16];   // QUANT more bits for the multipliers

  logic [4:0] m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15;

  typedef enum {IDLE, WR_IFMAP, WR_C, MU1, WR_OUT} state_type;

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

      MU1:     PE = WR_OUT;
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
  // always_comb begin
  //   unique case (EA)
  //     MU1:     begin m0= 0; m1= 1; m2= 2; m3= 3; m4= 4; m5= 5; m6= 6; m7= 7; end
  //     default: begin m0= 8; m1= 9; m2=10; m3=11; m4=12; m5=13; m6=14; m7=15; end
  //   endcase
  // end

  Multip multip00(.register(registers[00]), .weight(weights[00]), .product(product[00]));
  Multip multip01(.register(registers[01]), .weight(weights[01]), .product(product[01]));
  Multip multip02(.register(registers[02]), .weight(weights[02]), .product(product[02]));
  Multip multip03(.register(registers[03]), .weight(weights[03]), .product(product[03]));
  Multip multip04(.register(registers[04]), .weight(weights[04]), .product(product[04]));
  Multip multip05(.register(registers[05]), .weight(weights[05]), .product(product[05]));
  Multip multip06(.register(registers[06]), .weight(weights[06]), .product(product[06]));
  Multip multip07(.register(registers[07]), .weight(weights[07]), .product(product[07]));
  Multip multip08(.register(registers[08]), .weight(weights[08]), .product(product[08]));
  Multip multip09(.register(registers[09]), .weight(weights[09]), .product(product[09]));
  Multip multip10(.register(registers[10]), .weight(weights[10]), .product(product[10]));
  Multip multip11(.register(registers[11]), .weight(weights[11]), .product(product[11]));
  Multip multip12(.register(registers[12]), .weight(weights[12]), .product(product[12]));
  Multip multip13(.register(registers[13]), .weight(weights[13]), .product(product[13]));
  Multip multip14(.register(registers[14]), .weight(weights[14]), .product(product[14]));
  Multip multip15(.register(registers[15]), .weight(weights[15]), .product(product[15]));

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
        MU1:  begin
          registers[00] <= product[00];
          registers[01] <= product[01];
          registers[02] <= product[02];
          registers[03] <= product[03];
          registers[04] <= product[04];
          registers[05] <= product[05];
          registers[06] <= product[06];
          registers[07] <= product[07];
          registers[08] <= product[08];
          registers[09] <= product[09];
          registers[10] <= product[10];
          registers[11] <= product[11];
          registers[12] <= product[12];
          registers[13] <= product[13];
          registers[14] <= product[14];
          registers[15] <= product[15];
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
