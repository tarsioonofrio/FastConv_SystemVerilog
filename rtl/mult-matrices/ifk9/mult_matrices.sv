module MatrixA
  import pack_typedef::*;
  (
    input  type_weight P,
    output type_output soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] + P[3] + P[4] + P[18] + P[21] + P[22] + P[24] + P[27] + P[28];
  assign soma[1] = P[1] + P[3] + P[5] + P[19] + P[21] + P[23] + P[25] + P[27] + P[29];
  assign soma[2] = P[2] + P[4] + P[5] + P[20] + P[22] + P[23] + P[26] + P[28] + P[29];
  assign soma[3] = P[6] + P[9] + P[10] + P[18] + P[21] + P[22] + P[30] + P[33] + P[34];
  assign soma[4] = P[7] + P[9] + P[11] + P[19] + P[21] + P[23] + P[31] + P[33] + P[35];
  assign soma[5] = P[8] + P[10] + P[11] + P[20] + P[22] + P[23] + P[32] + P[34] + P[35];
  assign soma[6] = P[12] + P[15] + P[16] + P[24] + P[27] + P[28] + P[30] + P[33] + P[34];
  assign soma[7] = P[13] + P[15] + P[17] + P[25] + P[27] + P[29] + P[31] + P[33] + P[35];
  assign soma[8] = P[14] + P[16] + P[17] + P[26] + P[28] + P[29] + P[32] + P[34] + P[35];
endmodule


module MatrixC
  import pack_typedef::*;
  (
    input  type_input P,
    output type_weight soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] + P[6] + P[7] + P[11] + P[12] - (P[1] + P[2] + P[5] + P[10]);
  assign soma[1] = P[2] + P[6] + P[8] + P[11] + P[13] - (P[1] + P[3] + P[7] + P[12]);
  assign soma[2] = P[4] + P[7] + P[8] + P[12] + P[13] - (P[2] + P[3] + P[9] + P[14]);
  assign soma[3] = P[1] - (P[6] + P[11]);
  assign soma[4] = P[2] - (P[7] + P[12]);
  assign soma[5] = P[3] - (P[8] + P[13]);
  assign soma[6] = P[6] + P[7] + P[10] + P[16] + P[17] - (P[5] + P[11] + P[12] + P[15]);
  assign soma[7] = P[6] + P[8] + P[12] + P[16] + P[18] - (P[7] + P[11] + P[13] + P[17]);
  assign soma[8] = P[7] + P[8] + P[14] + P[17] + P[18] - (P[9] + P[12] + P[13] + P[19]);
  assign soma[9] = P[11] - (P[6] + P[16]);
  assign soma[10] = P[12] - (P[7] + P[17]);
  assign soma[11] = P[13] - (P[8] + P[18]);
  assign soma[12] = P[11] + P[12] + P[16] + P[17] + P[20] - (P[10] + P[15] + P[21] + P[22]);
  assign soma[13] = P[11] + P[13] + P[16] + P[18] + P[22] - (P[12] + P[17] + P[21] + P[23]);
  assign soma[14] = P[12] + P[13] + P[17] + P[18] + P[24] - (P[14] + P[19] + P[22] + P[23]);
  assign soma[15] = P[21] - (P[11] + P[16]);
  assign soma[16] = P[22] - (P[12] + P[17]);
  assign soma[17] = P[23] - (P[13] + P[18]);
  assign soma[18] = P[5] - (P[6] + P[7]);
  assign soma[19] = P[7] - (P[6] + P[8]);
  assign soma[20] = P[9] - (P[7] + P[8]);
  assign soma[21] = P[6];
  assign soma[22] = P[7];
  assign soma[23] = P[8];
  assign soma[24] = P[10] - (P[11] + P[12]);
  assign soma[25] = P[12] - (P[11] + P[13]);
  assign soma[26] = P[14] - (P[12] + P[13]);
  assign soma[27] = P[11];
  assign soma[28] = P[12];
  assign soma[29] = P[13];
  assign soma[30] = P[15] - (P[16] + P[17]);
  assign soma[31] = P[17] - (P[16] + P[18]);
  assign soma[32] = P[19] - (P[17] + P[18]);
  assign soma[33] = P[16];
  assign soma[34] = P[17];
  assign soma[35] = P[18];
endmodule
