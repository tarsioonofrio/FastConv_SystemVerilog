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
    parameter int QUANT = 8
  )
  (
    input  logic   clk, reset, start,
    input  type_input inputMAP,
    input  type_weight weights,
    output type_output  outputMAP,
    output logic   data_valid
 );

  timeunit 1ns;
  timeprecision 1ps;

  type_weight registers;
  type_matrix_c prod_c0;
  type_weight prod_c1;
  type_matrix_a prod_a1;
  type_output prod_a0;

  logic signed [NBITS-1+QUANT:0] product [0:5];   // QUANT more bits for the multipliers

  logic [5:0] m0, m1, m2, m3, m4, m5;

  // up to 16 states
  typedef enum logic [3:0] {IDLE, WR_IFMAP, WR_MC, MU1, MU2, MU3, MU4, MU5, MU6, WR_OUT} state_type;
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

  always_comb begin    // 9 states + IDEL - IDLE is blocking!
    unique case (EA)
      IDLE:      PE = start ? WR_IFMAP : IDLE;
      WR_IFMAP:  PE = WR_MC;
      WR_MC:     PE = MU1;
      MU1:       PE = MU2;
      MU2:       PE = MU3;
      MU3:       PE = MU4;
      MU4:       PE = MU5;
      MU5:       PE = MU6;
      MU6:       PE = WR_OUT;
      WR_OUT:    PE = IDLE;
      default:   PE = IDLE;
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

  Multip multip0(.register(registers[m0]), .weight(weights[m0]), .product(product[0]));
  Multip multip1(.register(registers[m1]), .weight(weights[m1]), .product(product[1]));
  Multip multip2(.register(registers[m2]), .weight(weights[m2]), .product(product[2]));
  Multip multip3(.register(registers[m3]), .weight(weights[m3]), .product(product[3]));
  Multip multip4(.register(registers[m4]), .weight(weights[m4]), .product(product[4]));
  Multip multip5(.register(registers[m5]), .weight(weights[m5]), .product(product[5]));

  always_comb begin
    unique case (EA)
      MU1: begin m0= 0; m1= 1; m2= 2;  m3= 3; m4= 4; m5= 5; end
      MU2: begin m0= 6; m1= 7; m2= 8;  m3= 9; m4=10; m5=11; end
      MU3: begin m0=12; m1=13; m2=14;  m3=15; m4=16; m5=17; end
      MU4: begin m0=18; m1=19; m2=20;  m3=21; m4=22; m5=23; end
      MU5: begin m0=24; m1=25; m2=26;  m3=27; m4=28; m5=29; end
      default: begin m0=30; m1=31; m2=32;  m3=33; m4=34; m5=35; end
    endcase
  end

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
      unique case (EA)
        WR_IFMAP:
            registers[24:0] <= inputMAP;
        WR_MC:
          registers <= prod_c1;
        MU1, MU2, MU3, MU4, MU5, MU6:  begin
          registers[m0] <= product[0];
          registers[m1] <= product[1];
          registers[m2] <= product[2];
          registers[m3] <= product[3];
          registers[m4] <= product[4];
          registers[m5] <= product[5];
        end
        WR_OUT: begin
          data_valid <= 1;
          registers[8:0] <= prod_a0;
        end
        default: begin   // necessary - wrong behavior in logic simulation
              registers <= registers;
        end
      endcase
    end
  end

  // connect 9 first registers to the outputs
  always_comb begin
    outputMAP = registers[8:0];
  end

endmodule
