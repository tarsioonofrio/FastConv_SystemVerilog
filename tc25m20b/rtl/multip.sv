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
    input regC A,
    input regC B,
    output regC P
); 
  timeunit 1ns;
  timeprecision 1ps;
  
                                              
    logic signed [NBITS/2:0] opA, opB;     // half word operators (one extra bit)
    logic signed [NBITS+1+QUANT:0] partial_product; 
    regC result; 

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            result <= '0;
        end else begin
            unique case (state)
                ALBL: begin
                    result <= (NBITS)'(partial_product[NBITS+1+QUANT:QUANT]);  // remove QUANT bits
                end
                ALBH, AHBL: begin
                    result <= result + (NBITS)'($signed({partial_product, {(NBITS/2-QUANT){1'b0}}}));     
                end
                AHBH: begin
                    result <= result + (NBITS)'({partial_product, {(NBITS-QUANT){1'b0}}});
                end
            endcase
        end
    end

    /// take the half words
    always_comb begin

        opA = (state==ALBL || state==ALBH) ? $signed({1'b0, A[NBITS/2-1:0]}) : $signed({A[NBITS-1], A[NBITS-1:NBITS/2]});

        opB = (state==ALBL || state==AHBL) ? $signed({1'b0, B[NBITS/2-1:0]}) : $signed({B[NBITS-1], B[NBITS-1:NBITS/2]});

        partial_product = opA * opB;

        P = result;
    end
endmodule
