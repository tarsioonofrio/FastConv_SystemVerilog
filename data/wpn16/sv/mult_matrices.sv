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

  assign soma[0] = P[0] - (P[4]);
  assign soma[1] = P[2] + P[4] - (P[1] + P[3]);
  assign soma[2] = P[1] + P[3];
  assign soma[3] = P[2] + P[4] - (P[1] + P[3]);
  assign soma[4] = P[3] + P[4] - (P[1] + P[2]);
  assign soma[5] = P[1] - (P[3]);
  assign soma[6] = P[2] + P[3] - (P[1] + P[4]);
  assign soma[7] = P[5] - (P[1]);
  assign soma[8] = P[6] - (P[10]);
  assign soma[9] = P[8] + P[10] - (P[7] + P[9]);
  assign soma[10] = P[7] + P[9];
  assign soma[11] = P[8] + P[10] - (P[7] + P[9]);
  assign soma[12] = P[9] + P[10] - (P[7] + P[8]);
  assign soma[13] = P[7] - (P[9]);
  assign soma[14] = P[8] + P[9] - (P[7] + P[10]);
  assign soma[15] = P[11] - (P[7]);
  assign soma[16] = P[12] - (P[16]);
  assign soma[17] = P[14] + P[16] - (P[13] + P[15]);
  assign soma[18] = P[13] + P[15];
  assign soma[19] = P[14] + P[16] - (P[13] + P[15]);
  assign soma[20] = P[15] + P[16] - (P[13] + P[14]);
  assign soma[21] = P[13] - (P[15]);
  assign soma[22] = P[14] + P[15] - (P[13] + P[16]);
  assign soma[23] = P[17] - (P[13]);
  assign soma[24] = P[18] - (P[22]);
  assign soma[25] = P[20] + P[22] - (P[19] + P[21]);
  assign soma[26] = P[19] + P[21];
  assign soma[27] = P[20] + P[22] - (P[19] + P[21]);
  assign soma[28] = P[21] + P[22] - (P[19] + P[20]);
  assign soma[29] = P[19] - (P[21]);
  assign soma[30] = P[20] + P[21] - (P[19] + P[22]);
  assign soma[31] = P[23] - (P[19]);
  assign soma[32] = P[24] - (P[28]);
  assign soma[33] = P[26] + P[28] - (P[25] + P[27]);
  assign soma[34] = P[25] + P[27];
  assign soma[35] = P[26] + P[28] - (P[25] + P[27]);
  assign soma[36] = P[27] + P[28] - (P[25] + P[26]);
  assign soma[37] = P[25] - (P[27]);
  assign soma[38] = P[26] + P[27] - (P[25] + P[28]);
  assign soma[39] = P[29] - (P[25]);
  assign soma[40] = P[30] - (P[34]);
  assign soma[41] = P[32] + P[34] - (P[31] + P[33]);
  assign soma[42] = P[31] + P[33];
  assign soma[43] = P[32] + P[34] - (P[31] + P[33]);
  assign soma[44] = P[33] + P[34] - (P[31] + P[32]);
  assign soma[45] = P[31] - (P[33]);
  assign soma[46] = P[32] + P[33] - (P[31] + P[34]);
  assign soma[47] = P[35] - (P[31]);
endmodule


module MatrixC1
  import pack_typedef::*;
  (
    input  type_matrix_c P,
    output type_weight soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] - (P[32]);
  assign soma[1] = P[1] - (P[33]);
  assign soma[2] = P[2] - (P[34]);
  assign soma[3] = P[3] - (P[35]);
  assign soma[4] = P[4] - (P[36]);
  assign soma[5] = P[5] - (P[37]);
  assign soma[6] = P[6] - (P[38]);
  assign soma[7] = P[7] - (P[39]);
  assign soma[8] = P[16] + P[32] - (P[8] + P[24]);
  assign soma[9] = P[17] + P[33] - (P[9] + P[25]);
  assign soma[10] = P[18] + P[34] - (P[10] + P[26]);
  assign soma[11] = P[19] + P[35] - (P[11] + P[27]);
  assign soma[12] = P[20] + P[36] - (P[12] + P[28]);
  assign soma[13] = P[21] + P[37] - (P[13] + P[29]);
  assign soma[14] = P[22] + P[38] - (P[14] + P[30]);
  assign soma[15] = P[23] + P[39] - (P[15] + P[31]);
  assign soma[16] = P[8] + P[24];
  assign soma[17] = P[9] + P[25];
  assign soma[18] = P[10] + P[26];
  assign soma[19] = P[11] + P[27];
  assign soma[20] = P[12] + P[28];
  assign soma[21] = P[13] + P[29];
  assign soma[22] = P[14] + P[30];
  assign soma[23] = P[15] + P[31];
  assign soma[24] = P[16] + P[32] - (P[8] + P[24]);
  assign soma[25] = P[17] + P[33] - (P[9] + P[25]);
  assign soma[26] = P[18] + P[34] - (P[10] + P[26]);
  assign soma[27] = P[19] + P[35] - (P[11] + P[27]);
  assign soma[28] = P[20] + P[36] - (P[12] + P[28]);
  assign soma[29] = P[21] + P[37] - (P[13] + P[29]);
  assign soma[30] = P[22] + P[38] - (P[14] + P[30]);
  assign soma[31] = P[23] + P[39] - (P[15] + P[31]);
  assign soma[32] = P[24] + P[32] - (P[8] + P[16]);
  assign soma[33] = P[25] + P[33] - (P[9] + P[17]);
  assign soma[34] = P[26] + P[34] - (P[10] + P[18]);
  assign soma[35] = P[27] + P[35] - (P[11] + P[19]);
  assign soma[36] = P[28] + P[36] - (P[12] + P[20]);
  assign soma[37] = P[29] + P[37] - (P[13] + P[21]);
  assign soma[38] = P[30] + P[38] - (P[14] + P[22]);
  assign soma[39] = P[31] + P[39] - (P[15] + P[23]);
  assign soma[40] = P[8] - (P[24]);
  assign soma[41] = P[9] - (P[25]);
  assign soma[42] = P[10] - (P[26]);
  assign soma[43] = P[11] - (P[27]);
  assign soma[44] = P[12] - (P[28]);
  assign soma[45] = P[13] - (P[29]);
  assign soma[46] = P[14] - (P[30]);
  assign soma[47] = P[15] - (P[31]);
  assign soma[48] = P[16] + P[24] - (P[8] + P[32]);
  assign soma[49] = P[17] + P[25] - (P[9] + P[33]);
  assign soma[50] = P[18] + P[26] - (P[10] + P[34]);
  assign soma[51] = P[19] + P[27] - (P[11] + P[35]);
  assign soma[52] = P[20] + P[28] - (P[12] + P[36]);
  assign soma[53] = P[21] + P[29] - (P[13] + P[37]);
  assign soma[54] = P[22] + P[30] - (P[14] + P[38]);
  assign soma[55] = P[23] + P[31] - (P[15] + P[39]);
  assign soma[56] = P[40] - (P[8]);
  assign soma[57] = P[41] - (P[9]);
  assign soma[58] = P[42] - (P[10]);
  assign soma[59] = P[43] - (P[11]);
  assign soma[60] = P[44] - (P[12]);
  assign soma[61] = P[45] - (P[13]);
  assign soma[62] = P[46] - (P[14]);
  assign soma[63] = P[47] - (P[15]);
endmodule


module MatrixA1
  import pack_typedef::*;
  (
    input  type_weight P,
    output type_matrix_a soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] + P[1] + P[2] + P[4] + P[5];
  assign soma[1] = P[2] + P[3] + P[5] + P[6];
  assign soma[2] = P[1] + P[2] - (P[4] + P[5]);
  assign soma[3] = P[2] + P[3] + P[7] - (P[5] + P[6]);
  assign soma[4] = P[8] + P[9] + P[10] + P[12] + P[13];
  assign soma[5] = P[10] + P[11] + P[13] + P[14];
  assign soma[6] = P[9] + P[10] - (P[12] + P[13]);
  assign soma[7] = P[10] + P[11] + P[15] - (P[13] + P[14]);
  assign soma[8] = P[16] + P[17] + P[18] + P[20] + P[21];
  assign soma[9] = P[18] + P[19] + P[21] + P[22];
  assign soma[10] = P[17] + P[18] - (P[20] + P[21]);
  assign soma[11] = P[18] + P[19] + P[23] - (P[21] + P[22]);
  assign soma[12] = P[24] + P[25] + P[26] + P[28] + P[29];
  assign soma[13] = P[26] + P[27] + P[29] + P[30];
  assign soma[14] = P[25] + P[26] - (P[28] + P[29]);
  assign soma[15] = P[26] + P[27] + P[31] - (P[29] + P[30]);
  assign soma[16] = P[32] + P[33] + P[34] + P[36] + P[37];
  assign soma[17] = P[34] + P[35] + P[37] + P[38];
  assign soma[18] = P[33] + P[34] - (P[36] + P[37]);
  assign soma[19] = P[34] + P[35] + P[39] - (P[37] + P[38]);
  assign soma[20] = P[40] + P[41] + P[42] + P[44] + P[45];
  assign soma[21] = P[42] + P[43] + P[45] + P[46];
  assign soma[22] = P[41] + P[42] - (P[44] + P[45]);
  assign soma[23] = P[42] + P[43] + P[47] - (P[45] + P[46]);
  assign soma[24] = P[48] + P[49] + P[50] + P[52] + P[53];
  assign soma[25] = P[50] + P[51] + P[53] + P[54];
  assign soma[26] = P[49] + P[50] - (P[52] + P[53]);
  assign soma[27] = P[50] + P[51] + P[55] - (P[53] + P[54]);
  assign soma[28] = P[56] + P[57] + P[58] + P[60] + P[61];
  assign soma[29] = P[58] + P[59] + P[61] + P[62];
  assign soma[30] = P[57] + P[58] - (P[60] + P[61]);
  assign soma[31] = P[58] + P[59] + P[63] - (P[61] + P[62]);
endmodule


module MatrixA0
  import pack_typedef::*;
  (
    input  type_matrix_a P,
    output type_output soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] + P[4] + P[8] + P[16] + P[20];
  assign soma[1] = P[1] + P[5] + P[9] + P[17] + P[21];
  assign soma[2] = P[2] + P[6] + P[10] + P[18] + P[22];
  assign soma[3] = P[3] + P[7] + P[11] + P[19] + P[23];
  assign soma[4] = P[8] + P[12] + P[20] + P[24];
  assign soma[5] = P[9] + P[13] + P[21] + P[25];
  assign soma[6] = P[10] + P[14] + P[22] + P[26];
  assign soma[7] = P[11] + P[15] + P[23] + P[27];
  assign soma[8] = P[4] + P[8] - (P[16] + P[20]);
  assign soma[9] = P[5] + P[9] - (P[17] + P[21]);
  assign soma[10] = P[6] + P[10] - (P[18] + P[22]);
  assign soma[11] = P[7] + P[11] - (P[19] + P[23]);
  assign soma[12] = P[8] + P[12] + P[28] - (P[20] + P[24]);
  assign soma[13] = P[9] + P[13] + P[29] - (P[21] + P[25]);
  assign soma[14] = P[10] + P[14] + P[30] - (P[22] + P[26]);
  assign soma[15] = P[11] + P[15] + P[31] - (P[23] + P[27]);
endmodule
