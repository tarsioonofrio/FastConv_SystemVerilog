module Transform #(
    parameter int NBITS = 20,
    parameter int TRANSFORM_SIZE = 4,
    parameter int B_SIZE = 4,
    parameter int INVERSE_SIZE = 6,
    parameter int HADAMARD_SIZE = 6
  ) (
    input  logic [NBITS-1:0] pin [INVERSE_SIZE*INVERSE_SIZE-1:0],
    output logic [NBITS-1:0] pout [HADAMARD_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  logic [NBITS-1:0] partial [INVERSE_SIZE*HADAMARD_SIZE-1:0];

  // Instance of matrix multiplier "C"
  MatrixC0 #(
    .NBITS(NBITS),
    .INVERSE_SIZE(INVERSE_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE)
  ) matrix_c0(
    .P(pin),
    .soma(partial)
  );
  MatrixC1 #(
    .NBITS(NBITS),
    .INVERSE_SIZE(INVERSE_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE)
  ) matrix_c1(
    .P(partial),
    .soma(pout)
  );
endmodule

module Inverse #(
    parameter int NBITS = 20,
    parameter int TRANSFORM_SIZE = 4,
    parameter int B_SIZE = 4,
    parameter int INVERSE_SIZE = 6,
    parameter int HADAMARD_SIZE = 6
  ) (
    input  logic [NBITS-1:0] pin [HADAMARD_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] pout [TRANSFORM_SIZE*TRANSFORM_SIZE-1:0]
 );
  timeunit 1ns;
  timeprecision 1ps;

  logic [NBITS-1:0] partial [INVERSE_SIZE*HADAMARD_SIZE-1:0];

  MatrixA1 #(
    .NBITS(NBITS),
    .INVERSE_SIZE(INVERSE_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE)
  ) matrix_a1 (
    .P(pin),
    .soma(partial)
  );
  MatrixA0 #(
    .NBITS(NBITS),
    .TRANSFORM_SIZE(TRANSFORM_SIZE),
    .INVERSE_SIZE(INVERSE_SIZE),
    .HADAMARD_SIZE(HADAMARD_SIZE)
  ) matrix_a0 (
    .P(partial),
    .soma(pout)
  );
endmodule

module MatrixC0 #(
    parameter int NBITS = 20,
    parameter int INVERSE_SIZE = 6,
    parameter int HADAMARD_SIZE = 6
  ) (
    input  logic [NBITS-1:0] P [INVERSE_SIZE*INVERSE_SIZE-1:0],
    output logic [NBITS-1:0] soma [INVERSE_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = (P[0] * 4) + P[4] - ((P[2] * 5));
  assign soma[1] = P[3] + P[4] - ((P[1] * 4) + (P[2] * 4));
  assign soma[2] = (P[1] * 4) + P[4] - ((P[2] * 4) + P[3]);
  assign soma[3] = (P[3] * 2) + P[4] - ((P[1] * 2) + P[2]);
  assign soma[4] = (P[1] * 2) + P[4] - (P[2] + (P[3] * 2));
  assign soma[5] = (P[1] * 4) + P[5] - ((P[3] * 5));
  assign soma[6] = (P[6] * 4) + P[10] - ((P[8] * 5));
  assign soma[7] = P[9] + P[10] - ((P[7] * 4) + (P[8] * 4));
  assign soma[8] = (P[7] * 4) + P[10] - ((P[8] * 4) + P[9]);
  assign soma[9] = (P[9] * 2) + P[10] - ((P[7] * 2) + P[8]);
  assign soma[10] = (P[7] * 2) + P[10] - (P[8] + (P[9] * 2));
  assign soma[11] = (P[7] * 4) + P[11] - ((P[9] * 5));
  assign soma[12] = (P[12] * 4) + P[16] - ((P[14] * 5));
  assign soma[13] = P[15] + P[16] - ((P[13] * 4) + (P[14] * 4));
  assign soma[14] = (P[13] * 4) + P[16] - ((P[14] * 4) + P[15]);
  assign soma[15] = (P[15] * 2) + P[16] - ((P[13] * 2) + P[14]);
  assign soma[16] = (P[13] * 2) + P[16] - (P[14] + (P[15] * 2));
  assign soma[17] = (P[13] * 4) + P[17] - ((P[15] * 5));
  assign soma[18] = (P[18] * 4) + P[22] - ((P[20] * 5));
  assign soma[19] = P[21] + P[22] - ((P[19] * 4) + (P[20] * 4));
  assign soma[20] = (P[19] * 4) + P[22] - ((P[20] * 4) + P[21]);
  assign soma[21] = (P[21] * 2) + P[22] - ((P[19] * 2) + P[20]);
  assign soma[22] = (P[19] * 2) + P[22] - (P[20] + (P[21] * 2));
  assign soma[23] = (P[19] * 4) + P[23] - ((P[21] * 5));
  assign soma[24] = (P[24] * 4) + P[28] - ((P[26] * 5));
  assign soma[25] = P[27] + P[28] - ((P[25] * 4) + (P[26] * 4));
  assign soma[26] = (P[25] * 4) + P[28] - ((P[26] * 4) + P[27]);
  assign soma[27] = (P[27] * 2) + P[28] - ((P[25] * 2) + P[26]);
  assign soma[28] = (P[25] * 2) + P[28] - (P[26] + (P[27] * 2));
  assign soma[29] = (P[25] * 4) + P[29] - ((P[27] * 5));
  assign soma[30] = (P[30] * 4) + P[34] - ((P[32] * 5));
  assign soma[31] = P[33] + P[34] - ((P[31] * 4) + (P[32] * 4));
  assign soma[32] = (P[31] * 4) + P[34] - ((P[32] * 4) + P[33]);
  assign soma[33] = (P[33] * 2) + P[34] - ((P[31] * 2) + P[32]);
  assign soma[34] = (P[31] * 2) + P[34] - (P[32] + (P[33] * 2));
  assign soma[35] = (P[31] * 4) + P[35] - ((P[33] * 5));
endmodule

module MatrixC1 #(
    parameter int NBITS = 20,
    parameter int INVERSE_SIZE = 6,
    parameter int HADAMARD_SIZE = 6
  ) (
    input  logic [NBITS-1:0] P [INVERSE_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [HADAMARD_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = (P[0] * 4) + P[24] - ((P[12] * 5));
  assign soma[1] = (P[1] * 4) + P[25] - ((P[13] * 5));
  assign soma[2] = (P[2] * 4) + P[26] - ((P[14] * 5));
  assign soma[3] = (P[3] * 4) + P[27] - ((P[15] * 5));
  assign soma[4] = (P[4] * 4) + P[28] - ((P[16] * 5));
  assign soma[5] = (P[5] * 4) + P[29] - ((P[17] * 5));
  assign soma[6] = P[18] + P[24] - ((P[6] * 4) + (P[12] * 4));
  assign soma[7] = P[19] + P[25] - ((P[7] * 4) + (P[13] * 4));
  assign soma[8] = P[20] + P[26] - ((P[8] * 4) + (P[14] * 4));
  assign soma[9] = P[21] + P[27] - ((P[9] * 4) + (P[15] * 4));
  assign soma[10] = P[22] + P[28] - ((P[10] * 4) + (P[16] * 4));
  assign soma[11] = P[23] + P[29] - ((P[11] * 4) + (P[17] * 4));
  assign soma[12] = (P[6] * 4) + P[24] - ((P[12] * 4) + P[18]);
  assign soma[13] = (P[7] * 4) + P[25] - ((P[13] * 4) + P[19]);
  assign soma[14] = (P[8] * 4) + P[26] - ((P[14] * 4) + P[20]);
  assign soma[15] = (P[9] * 4) + P[27] - ((P[15] * 4) + P[21]);
  assign soma[16] = (P[10] * 4) + P[28] - ((P[16] * 4) + P[22]);
  assign soma[17] = (P[11] * 4) + P[29] - ((P[17] * 4) + P[23]);
  assign soma[18] = (P[18] * 2) + P[24] - ((P[6] * 2) + P[12]);
  assign soma[19] = (P[19] * 2) + P[25] - ((P[7] * 2) + P[13]);
  assign soma[20] = (P[20] * 2) + P[26] - ((P[8] * 2) + P[14]);
  assign soma[21] = (P[21] * 2) + P[27] - ((P[9] * 2) + P[15]);
  assign soma[22] = (P[22] * 2) + P[28] - ((P[10] * 2) + P[16]);
  assign soma[23] = (P[23] * 2) + P[29] - ((P[11] * 2) + P[17]);
  assign soma[24] = (P[6] * 2) + P[24] - (P[12] + (P[18] * 2));
  assign soma[25] = (P[7] * 2) + P[25] - (P[13] + (P[19] * 2));
  assign soma[26] = (P[8] * 2) + P[26] - (P[14] + (P[20] * 2));
  assign soma[27] = (P[9] * 2) + P[27] - (P[15] + (P[21] * 2));
  assign soma[28] = (P[10] * 2) + P[28] - (P[16] + (P[22] * 2));
  assign soma[29] = (P[11] * 2) + P[29] - (P[17] + (P[23] * 2));
  assign soma[30] = (P[6] * 4) + P[30] - ((P[18] * 5));
  assign soma[31] = (P[7] * 4) + P[31] - ((P[19] * 5));
  assign soma[32] = (P[8] * 4) + P[32] - ((P[20] * 5));
  assign soma[33] = (P[9] * 4) + P[33] - ((P[21] * 5));
  assign soma[34] = (P[10] * 4) + P[34] - ((P[22] * 5));
  assign soma[35] = (P[11] * 4) + P[35] - ((P[23] * 5));
endmodule

module MatrixA1 #(
    parameter int NBITS = 20,
    parameter int INVERSE_SIZE = 6,
    parameter int HADAMARD_SIZE = 6
  ) (
    input  logic [NBITS-1:0] P [HADAMARD_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [INVERSE_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] + P[1] + P[2] + P[3] + P[4];
  assign soma[1] = P[1] + (P[3] * 2) - (P[2] + (P[4] * 2));
  assign soma[2] = P[1] + P[2] + (P[3] * 4) + (P[4] * 4);
  assign soma[3] = P[1] + (P[3] * 8) + P[5] - (P[2] + (P[4] * 8));
  assign soma[4] = P[6] + P[7] + P[8] + P[9] + P[10];
  assign soma[5] = P[7] + (P[9] * 2) - (P[8] + (P[10] * 2));
  assign soma[6] = P[7] + P[8] + (P[9] * 4) + (P[10] * 4);
  assign soma[7] = P[7] + (P[9] * 8) + P[11] - (P[8] + (P[10] * 8));
  assign soma[8] = P[12] + P[13] + P[14] + P[15] + P[16];
  assign soma[9] = P[13] + (P[15] * 2) - (P[14] + (P[16] * 2));
  assign soma[10] = P[13] + P[14] + (P[15] * 4) + (P[16] * 4);
  assign soma[11] = P[13] + (P[15] * 8) + P[17] - (P[14] + (P[16] * 8));
  assign soma[12] = P[18] + P[19] + P[20] + P[21] + P[22];
  assign soma[13] = P[19] + (P[21] * 2) - (P[20] + (P[22] * 2));
  assign soma[14] = P[19] + P[20] + (P[21] * 4) + (P[22] * 4);
  assign soma[15] = P[19] + (P[21] * 8) + P[23] - (P[20] + (P[22] * 8));
  assign soma[16] = P[24] + P[25] + P[26] + P[27] + P[28];
  assign soma[17] = P[25] + (P[27] * 2) - (P[26] + (P[28] * 2));
  assign soma[18] = P[25] + P[26] + (P[27] * 4) + (P[28] * 4);
  assign soma[19] = P[25] + (P[27] * 8) + P[29] - (P[26] + (P[28] * 8));
  assign soma[20] = P[30] + P[31] + P[32] + P[33] + P[34];
  assign soma[21] = P[31] + (P[33] * 2) - (P[32] + (P[34] * 2));
  assign soma[22] = P[31] + P[32] + (P[33] * 4) + (P[34] * 4);
  assign soma[23] = P[31] + (P[33] * 8) + P[35] - (P[32] + (P[34] * 8));
endmodule

module MatrixA0 #(
    parameter int NBITS = 20,
    parameter int TRANSFORM_SIZE = 4,
    parameter int B_SIZE = 4,
    parameter int INVERSE_SIZE = 6,
    parameter int HADAMARD_SIZE = 6
  ) (
    input  logic [NBITS-1:0] P [INVERSE_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [TRANSFORM_SIZE*TRANSFORM_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] + P[4] + P[8] + P[12] + P[16];
  assign soma[1] = P[1] + P[5] + P[9] + P[13] + P[17];
  assign soma[2] = P[2] + P[6] + P[10] + P[14] + P[18];
  assign soma[3] = P[3] + P[7] + P[11] + P[15] + P[19];
  assign soma[4] = P[4] + (P[12] * 2) - (P[8] + (P[16] * 2));
  assign soma[5] = P[5] + (P[13] * 2) - (P[9] + (P[17] * 2));
  assign soma[6] = P[6] + (P[14] * 2) - (P[10] + (P[18] * 2));
  assign soma[7] = P[7] + (P[15] * 2) - (P[11] + (P[19] * 2));
  assign soma[8] = P[4] + P[8] + (P[12] * 4) + (P[16] * 4);
  assign soma[9] = P[5] + P[9] + (P[13] * 4) + (P[17] * 4);
  assign soma[10] = P[6] + P[10] + (P[14] * 4) + (P[18] * 4);
  assign soma[11] = P[7] + P[11] + (P[15] * 4) + (P[19] * 4);
  assign soma[12] = P[4] + (P[12] * 8) + P[20] - (P[8] + (P[16] * 8));
  assign soma[13] = P[5] + (P[13] * 8) + P[21] - (P[9] + (P[17] * 8));
  assign soma[14] = P[6] + (P[14] * 8) + P[22] - (P[10] + (P[18] * 8));
  assign soma[15] = P[7] + (P[15] * 8) + P[23] - (P[11] + (P[19] * 8));
endmodule
