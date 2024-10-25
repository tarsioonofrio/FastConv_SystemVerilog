//-------------------------------------------------------------------------
// 4-cycles multiplier  27/SET/2024   -  moraes
//------------------------------------------------------------------------
module mult_iterate
     import packConv::*;
#(
    parameter int QUANT = 8 
) 
(   input logic clk,
    input logic reset,
    input mul_states state,
    input param25 A,
    input param25 B,
    output param25 P
); 
  timeunit 1ns;
  timeprecision 1ps;
                                         
    logic signed [NBITS-1+QUANT:0] partial_product [0:4]; 
    logic [4:0] m0, m1, m2, m3, m4;

    // in each cycle 5 multiplications are made, and at the end we will have 25 multiplications

    always_comb begin

          unique case (state)
                MU1: begin m0= 0; m1= 1; m2= 2;  m3= 3; m4= 4; end
                MU2: begin m0= 5; m1= 6; m2= 7;  m3= 8; m4= 9; end
                MU3: begin m0=10; m1=11; m2=12;  m3=13; m4=14; end
                MU4: begin m0=15; m1=16; m2=17;  m3=18; m4=19; end
                MU5: begin m0=20; m1=21; m2=22;  m3=23; m4=24; end
         endcase

          partial_product[0] = (NBITS+QUANT)'($signed(A[m0]) * $signed(B[m0]));
          partial_product[1] = (NBITS+QUANT)'($signed(A[m1]) * $signed(B[m1]));
          partial_product[2] = (NBITS+QUANT)'($signed(A[m2]) * $signed(B[m2]));
          partial_product[3] = (NBITS+QUANT)'($signed(A[m3]) * $signed(B[m3]));
          partial_product[4] = (NBITS+QUANT)'($signed(A[m4]) * $signed(B[m4]));
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            P <=  '{default: '0};
        end else begin
                P[m0] <= (NBITS)'($signed(partial_product[0][NBITS-1+QUANT:QUANT]));  // remove QUANT bits
                P[m1] <= (NBITS)'($signed(partial_product[1][NBITS-1+QUANT:QUANT]));
                P[m2] <= (NBITS)'($signed(partial_product[2][NBITS-1+QUANT:QUANT]));
                P[m3] <= (NBITS)'($signed(partial_product[3][NBITS-1+QUANT:QUANT]));
                P[m4] <= (NBITS)'($signed(partial_product[4][NBITS-1+QUANT:QUANT]));
        end
    end

endmodule
