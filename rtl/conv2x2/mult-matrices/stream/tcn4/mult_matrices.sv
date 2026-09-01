module Transform #(
    parameter int NBITS = 20,
    parameter int CONV_OUTPUT_SIZE = 2,
    parameter int CONV_INPUT_SIZE = 4,
    parameter int CONV_KERNEL_SIZE = 2,
    parameter int HADAMARD_SIZE = 4
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

// Row-wise first inverse transform for the streaming F(2x2, 3x3) datapath.
// The expressions intentionally preserve MatrixA1 width and wrap-around.
module InverseRow #(
    parameter int NBITS = 20,
    parameter int HADAMARD_SIZE = 4,
    parameter int CONV_OUTPUT_SIZE = 2
  ) (
    input  logic [NBITS-1:0] s_row [HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] sigma [CONV_OUTPUT_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign sigma[0] = s_row[0] + s_row[1] + s_row[2];
  assign sigma[1] = s_row[1] + s_row[3] - s_row[2];
endmodule

// Incremental second inverse transform for F(2x2, 3x3).
module InverseRowAccumulate #(
    parameter int NBITS = 20,
    parameter int HADAMARD_SIZE = 4,
    parameter int CONV_OUTPUT_SIZE = 2,
    parameter int ROW_INDEX_WIDTH = (HADAMARD_SIZE <= 1) ? 1 : $clog2(HADAMARD_SIZE)
  ) (
    input  logic [ROW_INDEX_WIDTH-1:0] row_idx,
    input  logic [NBITS-1:0] acc_in [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0],
    input  logic [NBITS-1:0] sigma [CONV_OUTPUT_SIZE-1:0],
    output logic [NBITS-1:0] acc_out [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    for (int unsigned i = 0; i < CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE; i++)
      acc_out[i] = acc_in[i];
    unique case (row_idx)
      0: begin acc_out[0] = sigma[0]; acc_out[1] = sigma[1]; end
      1: begin
        acc_out[0] = acc_in[0] + sigma[0]; acc_out[1] = acc_in[1] + sigma[1];
        acc_out[2] = sigma[0]; acc_out[3] = sigma[1];
      end
      2: begin
        acc_out[0] = acc_in[0] + sigma[0]; acc_out[1] = acc_in[1] + sigma[1];
        acc_out[2] = acc_in[2] - sigma[0]; acc_out[3] = acc_in[3] - sigma[1];
      end
      3: begin acc_out[2] = acc_in[2] + sigma[0]; acc_out[3] = acc_in[3] + sigma[1]; end
      default: begin end
    endcase
  end
endmodule

module Inverse #(
    parameter int NBITS = 20,
    parameter int CONV_OUTPUT_SIZE = 2,
    parameter int CONV_INPUT_SIZE = 4,
    parameter int CONV_KERNEL_SIZE = 2,
    parameter int HADAMARD_SIZE = 4
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
    parameter int CONV_INPUT_SIZE = 4,
    parameter int CONV_KERNEL_SIZE = 2,
    parameter int HADAMARD_SIZE = 4
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*CONV_INPUT_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0]
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

module MatrixC1 #(
    parameter int NBITS = 20,
    parameter int CONV_INPUT_SIZE = 4,
    parameter int CONV_KERNEL_SIZE = 2,
    parameter int HADAMARD_SIZE = 4
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [HADAMARD_SIZE*HADAMARD_SIZE-1:0]
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

module MatrixA1 #(
    parameter int NBITS = 20,
    parameter int CONV_INPUT_SIZE = 4,
    parameter int CONV_KERNEL_SIZE = 2,
    parameter int HADAMARD_SIZE = 4
  ) (
    input  logic [NBITS-1:0] P [HADAMARD_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0]
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

module MatrixA0 #(
    parameter int NBITS = 20,
    parameter int CONV_OUTPUT_SIZE = 2,
    parameter int CONV_INPUT_SIZE = 4,
    parameter int CONV_KERNEL_SIZE = 2,
    parameter int HADAMARD_SIZE = 4
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] + P[2] + P[4];
  assign soma[1] = P[1] + P[3] + P[5];
  assign soma[2] = P[2] + P[6] - (P[4]);
  assign soma[3] = P[3] + P[7] - (P[5]);
endmodule
