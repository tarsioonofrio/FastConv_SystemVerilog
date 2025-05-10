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
    parameter int NMULT = 6,
    parameter int SMULT = 6
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

  logic[5:0] idx[0:NMULT-1];


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

 // states + IDEL - IDLE is blocking!
  always_comb begin
    unique case (current_st)
      IDLE:     next_st = start ? WR_IFMAP : IDLE;
      WR_IFMAP: next_st = WR_MC;
      WR_MC:    next_st = MU0;
      WR_OUT:   next_st = IDLE;
      default: next_st = state_type'(current_st + 1);
    endcase
  end


  //
  // Data path
  //

  // Instance of matrix multiplier "C"
  Transform trf(
    .pin(registers[24:0]),
    .pout(prod_c)
  );

  always_comb begin
    unique case (current_st)
      MU0:     begin idx[0]= 0; idx[1]= 1; idx[2]= 2;  idx[3]= 3; idx[4]= 4; idx[5]= 5; end
      MU1:     begin idx[0]= 6; idx[1]= 7; idx[2]= 8;  idx[3]= 9; idx[4]=10; idx[5]=11; end
      MU2:     begin idx[0]=12; idx[1]=13; idx[2]=14;  idx[3]=15; idx[4]=16; idx[5]=17; end
      MU3:     begin idx[0]=18; idx[1]=19; idx[2]=20;  idx[3]=21; idx[4]=22; idx[5]=23; end
      MU4:     begin idx[0]=24; idx[1]=25; idx[2]=26;  idx[3]=27; idx[4]=28; idx[5]=29; end
      default: begin idx[0]=30; idx[1]=31; idx[2]=32;  idx[3]=33; idx[4]=34; idx[5]=35; end
    endcase
  end

  // generate
  //   for (genvar i = 0; i < NMULT; i++) begin
  //     Multip multip(.register(registers[idx[i]]), .weight(weights[idx[i]]), .product(product[i]));
  //   end
  // endgenerate

  Multip multip0(.register(registers[idx[0]]), .weight(weights[idx[0]]), .product(product[0]));
  Multip multip1(.register(registers[idx[1]]), .weight(weights[idx[1]]), .product(product[1]));
  Multip multip2(.register(registers[idx[2]]), .weight(weights[idx[2]]), .product(product[2]));
  Multip multip3(.register(registers[idx[3]]), .weight(weights[idx[3]]), .product(product[3]));
  Multip multip4(.register(registers[idx[4]]), .weight(weights[idx[4]]), .product(product[4]));
  Multip multip5(.register(registers[idx[5]]), .weight(weights[idx[5]]), .product(product[5]));

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
        WR_IFMAP: registers[24:0] <= inputMAP;
        WR_MC:    registers <= prod_c;
        WR_OUT: begin
          data_valid <= 1;
          registers[8:0] <= prod_a;
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
    outputMAP = registers[8:0];
  end

endmodule
