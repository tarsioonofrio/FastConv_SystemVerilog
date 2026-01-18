module Transform
  import pack_typedef::*;
  (
    input  type_input pin,
    output type_weight pout
  );
  timeunit 1ns;
  timeprecision 1ps;

  type_matrix_c partial;

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
  import pack_typedef::*;
  (
    input  type_weight pin,
    output type_output pout
 );
  timeunit 1ns;
  timeprecision 1ps;

  type_matrix_a partial;

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
  import pack_typedef::*;
  (
    input  type_input P,
    output type_matrix_c soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = (P[0] * 2) + P[3] - (P[1] + (P[2] * 2));
  assign soma[1] = P[3] - ((P[1] * 2) + P[2]);
  assign soma[2] = (P[1] * 2) + P[3] - ((P[2] * 3));
  assign soma[3] = P[3] - (P[1]);
  assign soma[4] = (P[1] * 2) + P[4] - (P[2] + (P[3] * 2));
  assign soma[5] = (P[5] * 2) + P[8] - (P[6] + (P[7] * 2));
  assign soma[6] = P[8] - ((P[6] * 2) + P[7]);
  assign soma[7] = (P[6] * 2) + P[8] - ((P[7] * 3));
  assign soma[8] = P[8] - (P[6]);
  assign soma[9] = (P[6] * 2) + P[9] - (P[7] + (P[8] * 2));
  assign soma[10] = (P[10] * 2) + P[13] - (P[11] + (P[12] * 2));
  assign soma[11] = P[13] - ((P[11] * 2) + P[12]);
  assign soma[12] = (P[11] * 2) + P[13] - ((P[12] * 3));
  assign soma[13] = P[13] - (P[11]);
  assign soma[14] = (P[11] * 2) + P[14] - (P[12] + (P[13] * 2));
  assign soma[15] = (P[15] * 2) + P[18] - (P[16] + (P[17] * 2));
  assign soma[16] = P[18] - ((P[16] * 2) + P[17]);
  assign soma[17] = (P[16] * 2) + P[18] - ((P[17] * 3));
  assign soma[18] = P[18] - (P[16]);
  assign soma[19] = (P[16] * 2) + P[19] - (P[17] + (P[18] * 2));
  assign soma[20] = (P[20] * 2) + P[23] - (P[21] + (P[22] * 2));
  assign soma[21] = P[23] - ((P[21] * 2) + P[22]);
  assign soma[22] = (P[21] * 2) + P[23] - ((P[22] * 3));
  assign soma[23] = P[23] - (P[21]);
  assign soma[24] = (P[21] * 2) + P[24] - (P[22] + (P[23] * 2));
endmodule


module MatrixC1
  import pack_typedef::*;
  (
    input  type_matrix_c P,
    output type_weight soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = (P[0] * 2) + P[15] - (P[5] + (P[10] * 2));
  assign soma[1] = (P[1] * 2) + P[16] - (P[6] + (P[11] * 2));
  assign soma[2] = (P[2] * 2) + P[17] - (P[7] + (P[12] * 2));
  assign soma[3] = (P[3] * 2) + P[18] - (P[8] + (P[13] * 2));
  assign soma[4] = (P[4] * 2) + P[19] - (P[9] + (P[14] * 2));
  assign soma[5] = P[15] - ((P[5] * 2) + P[10]);
  assign soma[6] = P[16] - ((P[6] * 2) + P[11]);
  assign soma[7] = P[17] - ((P[7] * 2) + P[12]);
  assign soma[8] = P[18] - ((P[8] * 2) + P[13]);
  assign soma[9] = P[19] - ((P[9] * 2) + P[14]);
  assign soma[10] = (P[5] * 2) + P[15] - ((P[10] * 3));
  assign soma[11] = (P[6] * 2) + P[16] - ((P[11] * 3));
  assign soma[12] = (P[7] * 2) + P[17] - ((P[12] * 3));
  assign soma[13] = (P[8] * 2) + P[18] - ((P[13] * 3));
  assign soma[14] = (P[9] * 2) + P[19] - ((P[14] * 3));
  assign soma[15] = P[15] - (P[5]);
  assign soma[16] = P[16] - (P[6]);
  assign soma[17] = P[17] - (P[7]);
  assign soma[18] = P[18] - (P[8]);
  assign soma[19] = P[19] - (P[9]);
  assign soma[20] = (P[5] * 2) + P[20] - (P[10] + (P[15] * 2));
  assign soma[21] = (P[6] * 2) + P[21] - (P[11] + (P[16] * 2));
  assign soma[22] = (P[7] * 2) + P[22] - (P[12] + (P[17] * 2));
  assign soma[23] = (P[8] * 2) + P[23] - (P[13] + (P[18] * 2));
  assign soma[24] = (P[9] * 2) + P[24] - (P[14] + (P[19] * 2));
endmodule


module MatrixA1
  import pack_typedef::*;
  (
    input  type_weight P,
    output type_matrix_a soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] + P[1] + P[2] + P[3];
  assign soma[1] = P[1] + (P[3] * 2) - (P[2]);
  assign soma[2] = P[1] + P[2] + (P[3] * 4) + P[4];
  assign soma[3] = P[5] + P[6] + P[7] + P[8];
  assign soma[4] = P[6] + (P[8] * 2) - (P[7]);
  assign soma[5] = P[6] + P[7] + (P[8] * 4) + P[9];
  assign soma[6] = P[10] + P[11] + P[12] + P[13];
  assign soma[7] = P[11] + (P[13] * 2) - (P[12]);
  assign soma[8] = P[11] + P[12] + (P[13] * 4) + P[14];
  assign soma[9] = P[15] + P[16] + P[17] + P[18];
  assign soma[10] = P[16] + (P[18] * 2) - (P[17]);
  assign soma[11] = P[16] + P[17] + (P[18] * 4) + P[19];
  assign soma[12] = P[20] + P[21] + P[22] + P[23];
  assign soma[13] = P[21] + (P[23] * 2) - (P[22]);
  assign soma[14] = P[21] + P[22] + (P[23] * 4) + P[24];
endmodule


module MatrixA0
  import pack_typedef::*;
  (
    input  type_matrix_a P,
    output type_output soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] + P[3] + P[6] + P[9];
  assign soma[1] = P[1] + P[4] + P[7] + P[10];
  assign soma[2] = P[2] + P[5] + P[8] + P[11];
  assign soma[3] = P[3] + (P[9] * 2) - (P[6]);
  assign soma[4] = P[4] + (P[10] * 2) - (P[7]);
  assign soma[5] = P[5] + (P[11] * 2) - (P[8]);
  assign soma[6] = P[3] + P[6] + (P[9] * 4) + P[12];
  assign soma[7] = P[4] + P[7] + (P[10] * 4) + P[13];
  assign soma[8] = P[5] + P[8] + (P[11] * 4) + P[14];
endmodule
