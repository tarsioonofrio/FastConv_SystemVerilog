//
// CSA ADDER LIBRARY  -  MORAES - SEPTEMBER 2024
//

//--------------------------------------------------------------
// FA adder
//--------------------------------------------------------------
module FA
     import packConv::*;
(
  input  logic [NBITS-1:0] a, b, c,
  output logic [NBITS-1:0] sum, cout
);

  timeunit 1ns;
  timeprecision 1ps;

  assign sum = a ^ b ^ c;
  assign cout = (NBITS)'({(a & b) | (a & c) | (b & c), 1'b0}); // cout applied to the next bit
endmodule

//--------------------------------------------------------------
// CSA 1  -  output equal to input
//--------------------------------------------------------------
module CSA_1
    import packConv::*;
(
  input  logic [NBITS-1:0] op0,
  output logic [NBITS-1:0] sum
);

  timeunit 1ns;
  timeprecision 1ps;
  
  assign sum = op0;
endmodule


//--------------------------------------------------------------
// 2 inputs ADDER
//--------------------------------------------------------------
module CSA_2
    import packConv::*;
(
  input  logic [NBITS-1:0] op0, op1,
  output logic [NBITS-1:0] sum
);

  timeunit 1ns;
  timeprecision 1ps;
  
  assign sum = op1 + op0;
endmodule

//--------------------------------------------------------------
// CSA - CARRY SAVE ADDER with 3 inputs
//--------------------------------------------------------------
module CSA_3
    import packConv::*;
(
  input  logic [NBITS-1:0] op0, op1, op2,
  output logic [NBITS-1:0] sum
);
  timeunit 1ns;
  timeprecision 1ps;
  
  logic [NBITS-1:0] sum_Q, cout_Q;

  FA layer1(.a(op2), .b(op1), .c(op0), .sum(sum_Q), .cout(cout_Q));
  assign sum = sum_Q + cout_Q;
endmodule

//--------------------------------------------------------------
// CSA - CARRY SAVE ADDER with 4 inputs
//--------------------------------------------------------------
module CSA_4    
     import packConv::*;
(
  input  logic [NBITS-1:0] op0, op1, op2, op3,
  output logic [NBITS-1:0] sum
);
  timeunit 1ns;
  timeprecision 1ps;
  
  two_words sumL1;
  logic [NBITS-1:0] sum_Q, cout_Q;

  FA layer1(.a(op3), .b(op2), .c(op1), .sum(sumL1[0]), .cout(sumL1[1]));
  FA layer2(.a(sumL1[0]), .b(sumL1[1]), .c(op0), .sum(sum_Q), .cout(cout_Q));

  assign sum = sum_Q + cout_Q;
endmodule

//--------------------------------------------------------------
// CSA - CARRY SAVE ADDER with 5 inputs
//--------------------------------------------------------------
module CSA_5
     import packConv::*;
(
  input  logic [NBITS-1:0] op0, op1, op2, op3, op4,
  output logic [NBITS-1:0] sum
);
  timeunit 1ns;
  timeprecision 1ps;
  
  four_words sumL1;
  two_words sumL2;
  logic [NBITS-1:0] sum_Q, cout_Q;

  FA L1a(.a(op4), .b(op3), .c(op2),   .sum(sumL1[0]), .cout(sumL1[1]));
  FA L1b(.a(op1), .b(op0), .c({NBITS{1'b0}}), .sum(sumL1[2]), .cout(sumL1[3]));

  FA L2(.a(sumL1[0]), .b(sumL1[1]), .c(sumL1[2]), .sum(sumL2[0]), .cout(sumL2[1]));

  FA L3(.a(sumL2[0]), .b(sumL2[1]), .c(sumL1[3]), .sum(sum_Q), .cout(cout_Q));

  assign sum = sum_Q + cout_Q;
endmodule

//--------------------------------------------------------------
// CSA - CARRY SAVE ADDER with 6 inputs
//--------------------------------------------------------------
module CSA_6
     import packConv::*;
(
  input  logic [NBITS-1:0] op0, op1, op2, op3, op4, op5,
  output logic [NBITS-1:0] sum
);
  timeunit 1ns;
  timeprecision 1ps;
  
  four_words sumL1, sumL2;
  logic [NBITS-1:0] sum_Q, cout_Q;

  FA L1a(.a(op5), .b(op4), .c(op3), .sum(sumL1[0]), .cout(sumL1[1]));
  FA L1b(.a(op2), .b(op1), .c(op0), .sum(sumL1[2]), .cout(sumL1[3]));

  FA L2(.a(sumL1[0]), .b(sumL1[1]), .c(sumL1[2]), .sum(sumL2[0]), .cout(sumL2[1]));
  
  FA L3(.a(sumL2[0]), .b(sumL2[1]), .c(sumL1[3]), .sum(sum_Q), .cout(cout_Q));

  assign sum = sum_Q + cout_Q;
endmodule

//--------------------------------------------------------------
// CSA - CARRY SAVE ADDER with 7 inputs
//--------------------------------------------------------------
module CSA_7
      import packConv::*;
(
  input  logic [NBITS-1:0] op0, op1, op2, op3, op4, op5, op6,
  output logic [NBITS-1:0] sum
);
  timeunit 1ns;
  timeprecision 1ps;
  
  four_words sumL1, sumL2;
  two_words sumL3;
  logic [NBITS-1:0] sum_Q, cout_Q;

  FA L1a(.a(op6), .b(op5), .c(op4), .sum(sumL1[0]), .cout(sumL1[1]));
  FA L1b(.a(op3), .b(op2), .c(op1), .sum(sumL1[2]), .cout(sumL1[3]));

  FA L2a(.a(sumL1[0]), .b(sumL1[1]), .c(sumL1[2]), .sum(sumL2[0]), .cout(sumL2[1]));
  FA L2b(.a(sumL1[3]), .b(op0),      .c({NBITS{1'b0}}),    .sum(sumL2[2]), .cout(sumL2[3]));

  FA L3(.a(sumL2[0]), .b(sumL2[1]), .c(sumL2[2]), .sum(sumL3[0]), .cout(sumL3[1]));

  FA L4(.a(sumL3[0]), .b(sumL3[1]), .c(sumL2[3]), .sum(sum_Q), .cout(cout_Q));

  assign sum = sum_Q + cout_Q;
endmodule

//--------------------------------------------------------------
// CSA - CARRY SAVE ADDER with 8 inputs
//--------------------------------------------------------------
module CSA_8
     import packConv::*;
(
  input  logic [NBITS-1:0] op0, op1, op2, op3, op4, op5, op6, op7,
  output logic [NBITS-1:0] sum
);
  timeunit 1ns;
  timeprecision 1ps;
  
  four_words sumL1, sumL2;
  two_words sumL3;
  logic [NBITS-1:0] sum_Q, cout_Q;

  FA L1a(.a(op7), .b(op6), .c(op5), .sum(sumL1[0]), .cout(sumL1[1]));
  FA L1b(.a(op4), .b(op3), .c(op2), .sum(sumL1[2]), .cout(sumL1[3]));

  FA L2a(.a(sumL1[0]), .b(sumL1[1]), .c(sumL1[2]), .sum(sumL2[0]), .cout(sumL2[1]));
  FA L2b(.a(sumL1[3]), .b(op1), .c(op0), .sum(sumL2[2]), .cout(sumL2[3]));

  FA L3(.a(sumL2[0]), .b(sumL2[1]), .c(sumL2[2]), .sum(sumL3[0]), .cout(sumL3[1]));

  FA L4(.a(sumL3[0]), .b(sumL3[1]), .c(sumL2[3]), .sum(sum_Q), .cout(cout_Q));

  assign sum = sum_Q + cout_Q;
endmodule


//--------------------------------------------------------------
// CSA - CARRY SAVE ADDER with 9 inputs
//--------------------------------------------------------------
module CSA_9
     import packConv::*;
(
  input  logic [NBITS-1:0] op0, op1, op2, op3, op4, op5, op6, op7, op8,
  output logic [NBITS-1:0] sum
);
  timeunit 1ns;
  timeprecision 1ps;
  
  six_words sumL1;
  four_words sumL2;
  two_words sumL3;
  logic [NBITS-1:0] sum_Q, cout_Q;

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
// CSA - CARRY SAVE ADDER with 9 inputs
//--------------------------------------------------------------
module CSA_12
     import packConv::*;
(
  input  logic [NBITS-1:0] op0, op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11,
  output logic [NBITS-1:0] sum
);
  timeunit 1ns;
  timeprecision 1ps;
  
  eight_words sumL1;
  four_words sumL2;
  four_words sumL3;
  two_words sumL4;

  logic [NBITS-1:0] sum_Q, cout_Q;

  FA L1a(.a(op0),  .b(op1),  .c(op2),  .sum(sumL1[0]), .cout(sumL1[1]));
  FA L1b(.a(op3),  .b(op4),  .c(op5),  .sum(sumL1[2]), .cout(sumL1[3]));
  FA L1c(.a(op6),  .b(op7),  .c(op8),  .sum(sumL1[4]), .cout(sumL1[5]));
  FA L1d(.a(op9),  .b(op10), .c(op11), .sum(sumL1[6]), .cout(sumL1[7]));

  FA L2a(.a(sumL1[0]), .b(sumL1[1]), .c(sumL1[2]), .sum(sumL2[0]), .cout(sumL2[1]));
  FA L2b(.a(sumL1[3]), .b(sumL1[4]), .c(sumL1[5]), .sum(sumL2[2]), .cout(sumL2[3]));

  FA L3a(.a(sumL2[0]), .b(sumL2[1]), .c(sumL2[2]), .sum(sumL3[0]), .cout(sumL3[1]));
  FA L3b(.a(sumL2[3]), .b(sumL1[6]), .c(sumL1[7]), .sum(sumL3[2]), .cout(sumL3[3]));

  FA L4(.a(sumL3[0]), .b(sumL3[1]), .c(sumL3[2]), .sum(sumL4[0]), .cout(sumL4[1]));

  FA L5(.a(sumL4[0]), .b(sumL4[1]), .c(sumL3[3]), .sum(sum_Q), .cout(cout_Q));

  assign sum = sum_Q + cout_Q;
endmodule

//--------------------------------------------------------------
// CSA - CARRY SAVE ADDER with 16 inputs
//--------------------------------------------------------------
module CSA_16
     import packConv::*;
(
  input  logic [NBITS-1:0] op0, op1, op2, op3, op4, op5, op6, op7,
                               op8, op9, op10, op11, op12, op13, op14, op15,
  output logic [NBITS-1:0] sum
);
  timeunit 1ns;
  timeprecision 1ps;
  
  ten_words sumL1;
  six_words sumL2;
  four_words sumL3, sumL4;
  two_words sumL5;
  logic [NBITS-1:0] sum_Q, cout_Q;

  FA L1a(.a(op15), .b(op14), .c(op13), .sum(sumL1[0]), .cout(sumL1[1]));
  FA L1b(.a(op12), .b(op11), .c(op10), .sum(sumL1[2]), .cout(sumL1[3]));
  FA L1c(.a(op9), .b(op8), .c(op7), .sum(sumL1[4]), .cout(sumL1[5]));
  FA L1d(.a(op6), .b(op5), .c(op4), .sum(sumL1[6]), .cout(sumL1[7]));
  FA L1e(.a(op3), .b(op2), .c(op1), .sum(sumL1[8]), .cout(sumL1[9]));

  FA L2a(.a(sumL1[0]), .b(sumL1[1]), .c(sumL1[2]), .sum(sumL2[0]), .cout(sumL2[1]));
  FA L2b(.a(sumL1[3]), .b(sumL1[4]), .c(sumL1[5]), .sum(sumL2[2]), .cout(sumL2[3]));
  FA L2c(.a(sumL1[6]), .b(sumL1[7]), .c(sumL1[8]), .sum(sumL2[4]), .cout(sumL2[5]));

  FA L3a(.a(sumL2[0]), .b(sumL2[1]), .c(sumL2[2]), .sum(sumL3[0]), .cout(sumL3[1]));
  FA L3b(.a(sumL2[3]), .b(sumL2[4]), .c(sumL2[5]), .sum(sumL3[2]), .cout(sumL3[3]));

  FA L4a(.a(sumL3[0]), .b(sumL3[1]), .c(sumL3[2]), .sum(sumL4[0]), .cout(sumL4[1]));
  FA L4b(.a(sumL3[3]), .b(sumL1[9]), .c(op0), .sum(sumL4[2]), .cout(sumL4[3]));

  FA L5(.a(sumL4[0]), .b(sumL4[1]), .c(sumL4[2]), .sum(sumL5[0]), .cout(sumL5[1]));

  FA L6(.a(sumL5[0]), .b(sumL5[1]), .c(sumL4[3]), .sum(sum_Q), .cout(cout_Q));

  assign sum = sum_Q + cout_Q;
endmodule


//--------------------------------------------------------------
// CSA - CARRY SAVE ADDER with 18 inputs (using an array)
//--------------------------------------------------------------
module CSA_18
     import packConv::*;
(
  input  logic[NBITS-1:0] inputs[18], // 18 operandos de entrada
  output logic [NBITS-1:0] sum
);
  timeunit 1ns;
  timeprecision 1ps;
  
  typedef logic [NBITS-1:0] layer1 [0:11];
  typedef logic [NBITS-1:0] layer2 [0:8];
  typedef logic [NBITS-1:0] layer3 [0:5];
  typedef logic [NBITS-1:0] layer4 [0:3];
  typedef logic [NBITS-1:0] layer5 [0:1];

  layer1 sumL1;
  layer2 sumL2;
  layer3 sumL3;
  layer4 sumL4;
  layer5 sumL5;
  logic [NBITS-1:0] sum_Q, cout_Q;

  // Primeira camada de CSAs (6 grupos de 3 operandos) -> vetor com 12 resultados
  genvar i;
  generate
    for (i = 0; i < 6; i++) begin
      FA L1(.a(inputs[i*3]), .b(inputs[i*3+1]), .c(inputs[i*3+2]), .sum(sumL1[i*2]), .cout(sumL1[i*2+1]));
    end
  endgenerate

  // Segunda camada de CSAs (4 grupos de 3 operandos) -> vetor com 8 resultados
  generate
    for (i = 0; i < 4; i++) begin
      FA L2(.a(sumL1[i*3]), .b(sumL1[i*3+1]), .c(sumL1[i*3+2]), .sum(sumL2[i*2]), .cout(sumL2[i*2+1]));
    end
  endgenerate
  assign sumL2[8] = '0; // Preenchendo o último elemento para completar o nível 2 (múltiplo de 3)

  // Terceira camada de CSAs (3 grupos de 3 operandos) -> vetor com 6 resultados
  generate
    for (i = 0; i < 3; i++) begin
      FA L3(.a(sumL2[i*3]), .b(sumL2[i*3+1]), .c(sumL2[i*3+2]), .sum(sumL3[i*2]), .cout(sumL3[i*2+1]));
    end
  endgenerate

  // Quarta camada de CSAs (2 grupos de 3 operandos) -> vetor com 4 resultados
  generate
    for (i = 0; i < 2; i++) begin
      FA L4(.a(sumL3[i*3]), .b(sumL3[i*3+1]), .c(sumL3[i*3+2]), .sum(sumL4[i*2]), .cout(sumL4[i*2+1]));
    end
  endgenerate

  // Quinta camada de CSAs
  FA L5(.a(sumL4[0]), .b(sumL4[1]), .c(sumL4[2]), .sum(sumL5[0]), .cout(sumL5[1]));

  // Sexta camada de CSAs
  FA L6(.a(sumL5[0]), .b(sumL5[1]), .c(sumL4[3]), .sum(sum_Q), .cout(cout_Q));

  // Soma final
  assign sum = sum_Q + cout_Q;

endmodule





