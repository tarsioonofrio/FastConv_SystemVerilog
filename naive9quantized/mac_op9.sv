
//--------------------------------------------------------------
// FA adder
//--------------------------------------------------------------
module FA
     import packConv::*;
(
  input  logic [8+NBITS-1:0] a, b, c,
  output logic [8+NBITS-1:0] sum, cout
);

  timeunit 1ns;
  timeprecision 1ps;

  assign sum = a ^ b ^ c;
  assign cout = (8+NBITS)'({(a & b) | (a & c) | (b & c), 1'b0}); // cout applied to the next bit
endmodule



//--------------------------------------------------------------
// CSA - CARRY SAVE ADDER with 9 inputs
//--------------------------------------------------------------
module CSA_9
     import packConv::*;
(
  input  logic [8+NBITS-1:0] op0, op1, op2, op3, op4, op5, op6, op7, op8,
  output logic [8+NBITS-1:0] sum
);
  timeunit 1ns;
  timeprecision 1ps;
  
  logic [8+NBITS-1:0] sumL1 [5:0];  // 6 words
  logic [8+NBITS-1:0] sumL2 [3:0];  // 4 words
  logic [8+NBITS-1:0] sumL3 [1:0];  // 2 words
  logic [8+NBITS-1:0] sum_Q, cout_Q;

  FA L1a(.a(op8), .b(op7), .c(op6), .sum(sumL1[0]), .cout(sumL1[1]));
  FA L1b(.a(op5), .b(op4), .c(op3), .sum(sumL1[2]), .cout(sumL1[3]));
  FA L1c(.a(op2), .b(op1), .c(op0), .sum(sumL1[4]), .cout(sumL1[5]));

  FA L2a(.a(sumL1[0]), .b(sumL1[1]), .c(sumL1[2]), .sum(sumL2[0]), .cout(sumL2[1]));
  FA L2b(.a(sumL1[3]), .b(sumL1[4]), .c(sumL1[5]), .sum(sumL2[2]), .cout(sumL2[3]));

  FA L3(.a(sumL2[0]), .b(sumL2[1]), .c(sumL2[2]), .sum(sumL3[0]), .cout(sumL3[1]));

  FA L4(.a(sumL3[0]), .b(sumL3[1]), .c(sumL2[3]), .sum(sum_Q), .cout(cout_Q));

  assign sum = sum_Q + cout_Q;
endmodule



//--------------------------------------------------------------
// 9 multipliers and a carry-save structure
//
//  precisa fazer tudo com mais 8 bits (QUANT) para ter resultados iguais à fast  
//
//--------------------------------------------------------------
module macoperation
     import packConv::*;
(
    input param9 inputs9,  
    input param9 weights9, 
    output regC  P,            
    input logic clk,  
    input logic reset,
    input logic start,
    output logic done 
);
  timeunit 1ns;
  timeprecision 1ps;
  
  logic signed [8+NBITS-1:0] prod [0:8];   // QUANT more bits for the multipliers

  logic signed [8+NBITS-1:0] sum_csa;   // QUANT more bits for the multipliers

  //param9 prod;  ////// 9 truncaded multiplierss
  
  typedef enum {IDLE, DONE} state;
  state EA, PE;
  

  // 9 paralell multipliers - trunca com a QUANTIZAÇÃO - GERA  28 BITS E NÃO 20—--
  always_comb begin
    for (int m=0; m < 9; m=m+1) begin
        prod[m] = (NBITS+8)'($signed(inputs9[m]) * $signed(weights9[m]));
    end 
  end


  // carry-save adder with 9 inputs
  CSA_9 sps (prod[0], prod[1], prod[2], prod[3], prod[4], prod[5], prod[6], prod[7], prod[8], sum_csa);

  assign P = (NBITS)'(sum_csa[NBITS-1+8:8]);

  always_comb begin
       if (EA == DONE) begin
           done = 1;  
       end else begin
           done = 0;
       end
   end


   // FSM
   always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            EA <= IDLE;
        end else begin
            EA <= PE;
        end
   end

   always_comb begin
        PE = EA;
        unique case (EA)
            IDLE: if (start)  PE = DONE;
            DONE: PE = IDLE; 
        endcase
    end

endmodule
