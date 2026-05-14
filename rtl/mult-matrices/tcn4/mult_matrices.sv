module Transform
  #(
    parameter int NBITS = 16,
    parameter int A1_SIZE = 3,
    parameter int C1_SIZE = 5,
    parameter int M1_SIZE = 6
  )
  (
    input  logic [NBITS-1:0] [C1_SIZE*C1_SIZE-1:0] pin,
    output logic [NBITS-1:0] [M1_SIZE*M1_SIZE-1:0] pout
  );
  timeunit 1ns;
  timeprecision 1ps;

  logic [NBITS-1:0] [C1_SIZE*M1_SIZE-1:0] partial;

  // Instance of matrix multiplier "C"
  MatrixC0 matrix_c0(
    .P(pin),
    .soma(partial)
  );
  MatrixC1 matrix_c1(
    .P(partial),
    .soma(pout)
  );
endmodule

module Inverse
  #(
    parameter int NBITS = 16,
    parameter int A1_SIZE = 3,
    parameter int C1_SIZE = 5,
    parameter int M1_SIZE = 6
  )
  (
    input  logic [NBITS-1:0] [M1_SIZE*M1_SIZE-1:0] pin,
    output logic [NBITS-1:0] [A1_SIZE*A1_SIZE-1:0] pout
 );
  timeunit 1ns;
  timeprecision 1ps;

  logic [NBITS-1:0] [C1_SIZE*M1_SIZE-1:0] partial;

  MatrixA1 matrix_a1 (
    .P(pin),
    .soma(partial)
  );
  MatrixA0 matrix_a0 (
    .P(partial),
    .soma(pout)
  );
endmodule

module MatrixC0
  #(
    parameter int NBITS = 16,
    parameter int A1_SIZE = 3,
    parameter int C1_SIZE = 5,
    parameter int M1_SIZE = 6
  )
  (
    input  logic [NBITS-1:0] [C1_SIZE*C1_SIZE-1:0] P,
    output logic [NBITS-1:0] [C1_SIZE*M1_SIZE-1:0] soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[2] - (P[0]);
  assign soma[1] = P[1] + P[2];
  assign soma[2] = P[2] - (P[1]);
  assign soma[3] = P[3] - (P[1]);
  assign soma[4] = P[6] - (P[4]);
  assign soma[5] = P[5] + P[6];
  assign soma[6] = P[6] - (P[5]);
  assign soma[7] = P[7] - (P[5]);
  assign soma[8] = P[10] - (P[8]);
  assign soma[9] = P[9] + P[10];
  assign soma[10] = P[10] - (P[9]);
  assign soma[11] = P[11] - (P[9]);
  assign soma[12] = P[14] - (P[12]);
  assign soma[13] = P[13] + P[14];
  assign soma[14] = P[14] - (P[13]);
  assign soma[15] = P[15] - (P[13]);
endmodule

module MatrixC1
  #(
    parameter int NBITS = 16,
    parameter int A1_SIZE = 3,
    parameter int C1_SIZE = 5,
    parameter int M1_SIZE = 6
  )
  (
    input  logic [NBITS-1:0] [C1_SIZE*M1_SIZE-1:0] P,
    output logic [NBITS-1:0] [M1_SIZE*M1_SIZE-1:0] soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[8] - (P[0]);
  assign soma[1] = P[9] - (P[1]);
  assign soma[2] = P[10] - (P[2]);
  assign soma[3] = P[11] - (P[3]);
  assign soma[4] = P[4] + P[8];
  assign soma[5] = P[5] + P[9];
  assign soma[6] = P[6] + P[10];
  assign soma[7] = P[7] + P[11];
  assign soma[8] = P[8] - (P[4]);
  assign soma[9] = P[9] - (P[5]);
  assign soma[10] = P[10] - (P[6]);
  assign soma[11] = P[11] - (P[7]);
  assign soma[12] = P[12] - (P[4]);
  assign soma[13] = P[13] - (P[5]);
  assign soma[14] = P[14] - (P[6]);
  assign soma[15] = P[15] - (P[7]);
endmodule

module MatrixA1
  #(
    parameter int NBITS = 16,
    parameter int A1_SIZE = 3,
    parameter int C1_SIZE = 5,
    parameter int M1_SIZE = 6
  )
  (
    input  logic [NBITS-1:0] [M1_SIZE*M1_SIZE-1:0] P,
    output logic [NBITS-1:0] [C1_SIZE*M1_SIZE-1:0] soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] + P[1] + P[2];
  assign soma[1] = P[1] + P[3] - (P[2]);
  assign soma[2] = P[4] + P[5] + P[6];
  assign soma[3] = P[5] + P[7] - (P[6]);
  assign soma[4] = P[8] + P[9] + P[10];
  assign soma[5] = P[9] + P[11] - (P[10]);
  assign soma[6] = P[12] + P[13] + P[14];
  assign soma[7] = P[13] + P[15] - (P[14]);
endmodule

module MatrixA0
  #(
    parameter int NBITS = 16,
    parameter int A1_SIZE = 3,
    parameter int C1_SIZE = 5,
    parameter int M1_SIZE = 6
  )
  (
    input  logic [NBITS-1:0] [C1_SIZE*M1_SIZE-1:0] P,
    output logic [NBITS-1:0] [A1_SIZE*A1_SIZE-1:0] soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] + P[2] + P[4];
  assign soma[1] = P[1] + P[3] + P[5];
  assign soma[2] = P[2] + P[6] - (P[4]);
  assign soma[3] = P[3] + P[7] - (P[5]);
endmodule
