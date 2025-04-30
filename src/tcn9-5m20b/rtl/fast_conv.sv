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
    input  type_weight weights,
    output type_output outputMAP,
    output logic       data_valid
 );

  timeunit 1ns;
  timeprecision 1ps;


  type_input registers, prod_c0;
  type_matrix_c prod_c1;
  type_matrix_a prod_a1;
  type_output prod_a0;

  logic signed [NBITS-1+QUANT:0] product [0:4];   // QUANT more bits for the multipliers

  logic [4:0] m0, m1, m2, m3, m4;

  typedef enum {IDLE, WR_IFMAP, WR_MC, MU1, MU2, MU3, MU4, MU5, WR_OUT} state_type;

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
      WR_IFMAP: PE = WR_MC;
      WR_MC:    PE = MU1;

      // five state multiplier
      MU1:   PE = MU2;
      MU2:   PE = MU3;
      MU3:   PE = MU4;
      MU4:   PE = MU5;
      MU5:   PE = WR_OUT;

      //MMMA:  PE = WR_OUT;
      WR_OUT:  PE = IDLE;
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

   // 5 multipliers inside this block
  always_comb begin
    unique case (EA)
      MU1: begin m0= 0; m1= 1; m2= 2;  m3= 3; m4= 4; end
      MU2: begin m0= 5; m1= 6; m2= 7;  m3= 8; m4= 9; end
      MU3: begin m0=10; m1=11; m2=12;  m3=13; m4=14; end
      MU4: begin m0=15; m1=16; m2=17;  m3=18; m4=19; end
      default: begin m0=20; m1=21; m2=22;  m3=23; m4=24; end
    endcase
  end

  Multip multip0(.register(registers[m0]), .weight(weights[m0]), .product(product[0]));
  Multip multip1(.register(registers[m1]), .weight(weights[m1]), .product(product[1]));
  Multip multip2(.register(registers[m2]), .weight(weights[m2]), .product(product[2]));
  Multip multip3(.register(registers[m3]), .weight(weights[m3]), .product(product[3]));
  Multip multip4(.register(registers[m4]), .weight(weights[m4]), .product(product[4]));

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
        WR_IFMAP:   registers <= inputMAP;
        WR_MC:      registers <= prod_c1;
        MU1, MU2, MU3, MU4, MU5:  begin
          registers[m0] <= product[0];
          registers[m1] <= product[1];
          registers[m2] <= product[2];
          registers[m3] <= product[3];
          registers[m4] <= product[4];
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
      for (int i = 0; i < 9; i++)
      outputMAP[i] = prod_a0[i];   /// saída em latch
    end
  end
endmodule
