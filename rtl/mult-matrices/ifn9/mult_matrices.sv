module Transform #(
    parameter int NBITS = 20,
    parameter int CONV_OUTPUT_SIZE = 3,
    parameter int CONV_INPUT_SIZE = 5,
    parameter int CONV_KERNEL_SIZE = 3,
    parameter int HADAMARD_SIZE = 6
  ) (
    input  logic [NBITS-1:0] pin [CONV_INPUT_SIZE*CONV_INPUT_SIZE-1:0],
    output logic [NBITS-1:0] pout [HADAMARD_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  logic [NBITS-1:0] partial [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0];

  // Instance of matrix multiplier "C"
  MatrixC0 #(
    .NBITS(NBITS),
    .CONV_INPUT_SIZE(CONV_INPUT_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE)
  ) matrix_c0(
    .P(pin),
    .soma(partial)
  );
  MatrixC1 #(
    .NBITS(NBITS),
    .CONV_INPUT_SIZE(CONV_INPUT_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE)
  ) matrix_c1(
    .P(partial),
    .soma(pout)
  );
endmodule

module Inverse #(
    parameter int NBITS = 20,
    parameter int CONV_OUTPUT_SIZE = 3,
    parameter int CONV_INPUT_SIZE = 5,
    parameter int CONV_KERNEL_SIZE = 3,
    parameter int HADAMARD_SIZE = 6
  ) (
    input  logic [NBITS-1:0] pin [HADAMARD_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] pout [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0]
 );
  timeunit 1ns;
  timeprecision 1ps;

  logic [NBITS-1:0] partial [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0];

  MatrixA1 #(
    .NBITS(NBITS),
    .CONV_INPUT_SIZE(CONV_INPUT_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE)
  ) matrix_a1 (
    .P(pin),
    .soma(partial)
  );
  MatrixA0 #(
    .NBITS(NBITS),
    .CONV_OUTPUT_SIZE(CONV_OUTPUT_SIZE),
    .CONV_INPUT_SIZE(CONV_INPUT_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE)
  ) matrix_a0 (
    .P(partial),
    .soma(pout)
  );
endmodule

module MatrixC0 #(
    parameter int NBITS = 20,
    parameter int CONV_INPUT_SIZE = 5,
    parameter int CONV_KERNEL_SIZE = 3,
    parameter int HADAMARD_SIZE = 6
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*CONV_INPUT_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] - (P[1] + P[2]);
  assign soma[1] = P[2] - (P[1] + P[3]);
  assign soma[2] = P[4] - (P[2] + P[3]);
  assign soma[3] = P[1];
  assign soma[4] = P[2];
  assign soma[5] = P[3];
  assign soma[6] = P[5] - (P[6] + P[7]);
  assign soma[7] = P[7] - (P[6] + P[8]);
  assign soma[8] = P[9] - (P[7] + P[8]);
  assign soma[9] = P[6];
  assign soma[10] = P[7];
  assign soma[11] = P[8];
  assign soma[12] = P[10] - (P[11] + P[12]);
  assign soma[13] = P[12] - (P[11] + P[13]);
  assign soma[14] = P[14] - (P[12] + P[13]);
  assign soma[15] = P[11];
  assign soma[16] = P[12];
  assign soma[17] = P[13];
  assign soma[18] = P[15] - (P[16] + P[17]);
  assign soma[19] = P[17] - (P[16] + P[18]);
  assign soma[20] = P[19] - (P[17] + P[18]);
  assign soma[21] = P[16];
  assign soma[22] = P[17];
  assign soma[23] = P[18];
  assign soma[24] = P[20] - (P[21] + P[22]);
  assign soma[25] = P[22] - (P[21] + P[23]);
  assign soma[26] = P[24] - (P[22] + P[23]);
  assign soma[27] = P[21];
  assign soma[28] = P[22];
  assign soma[29] = P[23];
endmodule

module MatrixC1 #(
    parameter int NBITS = 20,
    parameter int CONV_INPUT_SIZE = 5,
    parameter int CONV_KERNEL_SIZE = 3,
    parameter int HADAMARD_SIZE = 6
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [HADAMARD_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] - (P[6] + P[12]);
  assign soma[1] = P[1] - (P[7] + P[13]);
  assign soma[2] = P[2] - (P[8] + P[14]);
  assign soma[3] = P[3] - (P[9] + P[15]);
  assign soma[4] = P[4] - (P[10] + P[16]);
  assign soma[5] = P[5] - (P[11] + P[17]);
  assign soma[6] = P[12] - (P[6] + P[18]);
  assign soma[7] = P[13] - (P[7] + P[19]);
  assign soma[8] = P[14] - (P[8] + P[20]);
  assign soma[9] = P[15] - (P[9] + P[21]);
  assign soma[10] = P[16] - (P[10] + P[22]);
  assign soma[11] = P[17] - (P[11] + P[23]);
  assign soma[12] = P[24] - (P[12] + P[18]);
  assign soma[13] = P[25] - (P[13] + P[19]);
  assign soma[14] = P[26] - (P[14] + P[20]);
  assign soma[15] = P[27] - (P[15] + P[21]);
  assign soma[16] = P[28] - (P[16] + P[22]);
  assign soma[17] = P[29] - (P[17] + P[23]);
  assign soma[18] = P[6];
  assign soma[19] = P[7];
  assign soma[20] = P[8];
  assign soma[21] = P[9];
  assign soma[22] = P[10];
  assign soma[23] = P[11];
  assign soma[24] = P[12];
  assign soma[25] = P[13];
  assign soma[26] = P[14];
  assign soma[27] = P[15];
  assign soma[28] = P[16];
  assign soma[29] = P[17];
  assign soma[30] = P[18];
  assign soma[31] = P[19];
  assign soma[32] = P[20];
  assign soma[33] = P[21];
  assign soma[34] = P[22];
  assign soma[35] = P[23];
endmodule

module MatrixA1 #(
    parameter int NBITS = 20,
    parameter int CONV_INPUT_SIZE = 5,
    parameter int CONV_KERNEL_SIZE = 3,
    parameter int HADAMARD_SIZE = 6
  ) (
    input  logic [NBITS-1:0] P [HADAMARD_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] + P[3] + P[4];
  assign soma[1] = P[1] + P[3] + P[5];
  assign soma[2] = P[2] + P[4] + P[5];
  assign soma[3] = P[6] + P[9] + P[10];
  assign soma[4] = P[7] + P[9] + P[11];
  assign soma[5] = P[8] + P[10] + P[11];
  assign soma[6] = P[12] + P[15] + P[16];
  assign soma[7] = P[13] + P[15] + P[17];
  assign soma[8] = P[14] + P[16] + P[17];
  assign soma[9] = P[18] + P[21] + P[22];
  assign soma[10] = P[19] + P[21] + P[23];
  assign soma[11] = P[20] + P[22] + P[23];
  assign soma[12] = P[24] + P[27] + P[28];
  assign soma[13] = P[25] + P[27] + P[29];
  assign soma[14] = P[26] + P[28] + P[29];
  assign soma[15] = P[30] + P[33] + P[34];
  assign soma[16] = P[31] + P[33] + P[35];
  assign soma[17] = P[32] + P[34] + P[35];
endmodule

module MatrixA0 #(
    parameter int NBITS = 20,
    parameter int CONV_OUTPUT_SIZE = 3,
    parameter int CONV_INPUT_SIZE = 5,
    parameter int CONV_KERNEL_SIZE = 3,
    parameter int HADAMARD_SIZE = 6
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] + P[9] + P[12];
  assign soma[1] = P[1] + P[10] + P[13];
  assign soma[2] = P[2] + P[11] + P[14];
  assign soma[3] = P[3] + P[9] + P[15];
  assign soma[4] = P[4] + P[10] + P[16];
  assign soma[5] = P[5] + P[11] + P[17];
  assign soma[6] = P[6] + P[12] + P[15];
  assign soma[7] = P[7] + P[13] + P[16];
  assign soma[8] = P[8] + P[14] + P[17];
endmodule
