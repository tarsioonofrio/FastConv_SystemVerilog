module Transform #(
    parameter int NBITS = 20,
    parameter int CONV_OUTPUT_SIZE = 4,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 12
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
    parameter int CONV_OUTPUT_SIZE = 4,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 12
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
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 12
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*CONV_INPUT_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0];
  assign soma[1] = P[1];
  assign soma[2] = P[2];
  assign soma[3] = P[1];
  assign soma[4] = P[2];
  assign soma[5] = P[3];
  assign soma[6] = P[2];
  assign soma[7] = P[3];
  assign soma[8] = P[4];
  assign soma[9] = P[3];
  assign soma[10] = P[4];
  assign soma[11] = P[5];
  assign soma[12] = P[6];
  assign soma[13] = P[7];
  assign soma[14] = P[8];
  assign soma[15] = P[7];
  assign soma[16] = P[8];
  assign soma[17] = P[9];
  assign soma[18] = P[8];
  assign soma[19] = P[9];
  assign soma[20] = P[10];
  assign soma[21] = P[9];
  assign soma[22] = P[10];
  assign soma[23] = P[11];
  assign soma[24] = P[12];
  assign soma[25] = P[13];
  assign soma[26] = P[14];
  assign soma[27] = P[13];
  assign soma[28] = P[14];
  assign soma[29] = P[15];
  assign soma[30] = P[14];
  assign soma[31] = P[15];
  assign soma[32] = P[16];
  assign soma[33] = P[15];
  assign soma[34] = P[16];
  assign soma[35] = P[17];
  assign soma[36] = P[18];
  assign soma[37] = P[19];
  assign soma[38] = P[20];
  assign soma[39] = P[19];
  assign soma[40] = P[20];
  assign soma[41] = P[21];
  assign soma[42] = P[20];
  assign soma[43] = P[21];
  assign soma[44] = P[22];
  assign soma[45] = P[21];
  assign soma[46] = P[22];
  assign soma[47] = P[23];
  assign soma[48] = P[24];
  assign soma[49] = P[25];
  assign soma[50] = P[26];
  assign soma[51] = P[25];
  assign soma[52] = P[26];
  assign soma[53] = P[27];
  assign soma[54] = P[26];
  assign soma[55] = P[27];
  assign soma[56] = P[28];
  assign soma[57] = P[27];
  assign soma[58] = P[28];
  assign soma[59] = P[29];
  assign soma[60] = P[30];
  assign soma[61] = P[31];
  assign soma[62] = P[32];
  assign soma[63] = P[31];
  assign soma[64] = P[32];
  assign soma[65] = P[33];
  assign soma[66] = P[32];
  assign soma[67] = P[33];
  assign soma[68] = P[34];
  assign soma[69] = P[33];
  assign soma[70] = P[34];
  assign soma[71] = P[35];
endmodule

module MatrixC1 #(
    parameter int NBITS = 20,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 12
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [HADAMARD_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0];
  assign soma[1] = P[1];
  assign soma[2] = P[2];
  assign soma[3] = P[3];
  assign soma[4] = P[4];
  assign soma[5] = P[5];
  assign soma[6] = P[6];
  assign soma[7] = P[7];
  assign soma[8] = P[8];
  assign soma[9] = P[9];
  assign soma[10] = P[10];
  assign soma[11] = P[11];
  assign soma[12] = P[12];
  assign soma[13] = P[13];
  assign soma[14] = P[14];
  assign soma[15] = P[15];
  assign soma[16] = P[16];
  assign soma[17] = P[17];
  assign soma[18] = P[18];
  assign soma[19] = P[19];
  assign soma[20] = P[20];
  assign soma[21] = P[21];
  assign soma[22] = P[22];
  assign soma[23] = P[23];
  assign soma[24] = P[24];
  assign soma[25] = P[25];
  assign soma[26] = P[26];
  assign soma[27] = P[27];
  assign soma[28] = P[28];
  assign soma[29] = P[29];
  assign soma[30] = P[30];
  assign soma[31] = P[31];
  assign soma[32] = P[32];
  assign soma[33] = P[33];
  assign soma[34] = P[34];
  assign soma[35] = P[35];
  assign soma[36] = P[12];
  assign soma[37] = P[13];
  assign soma[38] = P[14];
  assign soma[39] = P[15];
  assign soma[40] = P[16];
  assign soma[41] = P[17];
  assign soma[42] = P[18];
  assign soma[43] = P[19];
  assign soma[44] = P[20];
  assign soma[45] = P[21];
  assign soma[46] = P[22];
  assign soma[47] = P[23];
  assign soma[48] = P[24];
  assign soma[49] = P[25];
  assign soma[50] = P[26];
  assign soma[51] = P[27];
  assign soma[52] = P[28];
  assign soma[53] = P[29];
  assign soma[54] = P[30];
  assign soma[55] = P[31];
  assign soma[56] = P[32];
  assign soma[57] = P[33];
  assign soma[58] = P[34];
  assign soma[59] = P[35];
  assign soma[60] = P[36];
  assign soma[61] = P[37];
  assign soma[62] = P[38];
  assign soma[63] = P[39];
  assign soma[64] = P[40];
  assign soma[65] = P[41];
  assign soma[66] = P[42];
  assign soma[67] = P[43];
  assign soma[68] = P[44];
  assign soma[69] = P[45];
  assign soma[70] = P[46];
  assign soma[71] = P[47];
  assign soma[72] = P[24];
  assign soma[73] = P[25];
  assign soma[74] = P[26];
  assign soma[75] = P[27];
  assign soma[76] = P[28];
  assign soma[77] = P[29];
  assign soma[78] = P[30];
  assign soma[79] = P[31];
  assign soma[80] = P[32];
  assign soma[81] = P[33];
  assign soma[82] = P[34];
  assign soma[83] = P[35];
  assign soma[84] = P[36];
  assign soma[85] = P[37];
  assign soma[86] = P[38];
  assign soma[87] = P[39];
  assign soma[88] = P[40];
  assign soma[89] = P[41];
  assign soma[90] = P[42];
  assign soma[91] = P[43];
  assign soma[92] = P[44];
  assign soma[93] = P[45];
  assign soma[94] = P[46];
  assign soma[95] = P[47];
  assign soma[96] = P[48];
  assign soma[97] = P[49];
  assign soma[98] = P[50];
  assign soma[99] = P[51];
  assign soma[100] = P[52];
  assign soma[101] = P[53];
  assign soma[102] = P[54];
  assign soma[103] = P[55];
  assign soma[104] = P[56];
  assign soma[105] = P[57];
  assign soma[106] = P[58];
  assign soma[107] = P[59];
  assign soma[108] = P[36];
  assign soma[109] = P[37];
  assign soma[110] = P[38];
  assign soma[111] = P[39];
  assign soma[112] = P[40];
  assign soma[113] = P[41];
  assign soma[114] = P[42];
  assign soma[115] = P[43];
  assign soma[116] = P[44];
  assign soma[117] = P[45];
  assign soma[118] = P[46];
  assign soma[119] = P[47];
  assign soma[120] = P[48];
  assign soma[121] = P[49];
  assign soma[122] = P[50];
  assign soma[123] = P[51];
  assign soma[124] = P[52];
  assign soma[125] = P[53];
  assign soma[126] = P[54];
  assign soma[127] = P[55];
  assign soma[128] = P[56];
  assign soma[129] = P[57];
  assign soma[130] = P[58];
  assign soma[131] = P[59];
  assign soma[132] = P[60];
  assign soma[133] = P[61];
  assign soma[134] = P[62];
  assign soma[135] = P[63];
  assign soma[136] = P[64];
  assign soma[137] = P[65];
  assign soma[138] = P[66];
  assign soma[139] = P[67];
  assign soma[140] = P[68];
  assign soma[141] = P[69];
  assign soma[142] = P[70];
  assign soma[143] = P[71];
endmodule

module MatrixA1 #(
    parameter int NBITS = 20,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 12
  ) (
    input  logic [NBITS-1:0] P [HADAMARD_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] + P[1] + P[2];
  assign soma[1] = P[3] + P[4] + P[5];
  assign soma[2] = P[6] + P[7] + P[8];
  assign soma[3] = P[9] + P[10] + P[11];
  assign soma[4] = P[12] + P[13] + P[14];
  assign soma[5] = P[15] + P[16] + P[17];
  assign soma[6] = P[18] + P[19] + P[20];
  assign soma[7] = P[21] + P[22] + P[23];
  assign soma[8] = P[24] + P[25] + P[26];
  assign soma[9] = P[27] + P[28] + P[29];
  assign soma[10] = P[30] + P[31] + P[32];
  assign soma[11] = P[33] + P[34] + P[35];
  assign soma[12] = P[36] + P[37] + P[38];
  assign soma[13] = P[39] + P[40] + P[41];
  assign soma[14] = P[42] + P[43] + P[44];
  assign soma[15] = P[45] + P[46] + P[47];
  assign soma[16] = P[48] + P[49] + P[50];
  assign soma[17] = P[51] + P[52] + P[53];
  assign soma[18] = P[54] + P[55] + P[56];
  assign soma[19] = P[57] + P[58] + P[59];
  assign soma[20] = P[60] + P[61] + P[62];
  assign soma[21] = P[63] + P[64] + P[65];
  assign soma[22] = P[66] + P[67] + P[68];
  assign soma[23] = P[69] + P[70] + P[71];
  assign soma[24] = P[72] + P[73] + P[74];
  assign soma[25] = P[75] + P[76] + P[77];
  assign soma[26] = P[78] + P[79] + P[80];
  assign soma[27] = P[81] + P[82] + P[83];
  assign soma[28] = P[84] + P[85] + P[86];
  assign soma[29] = P[87] + P[88] + P[89];
  assign soma[30] = P[90] + P[91] + P[92];
  assign soma[31] = P[93] + P[94] + P[95];
  assign soma[32] = P[96] + P[97] + P[98];
  assign soma[33] = P[99] + P[100] + P[101];
  assign soma[34] = P[102] + P[103] + P[104];
  assign soma[35] = P[105] + P[106] + P[107];
  assign soma[36] = P[108] + P[109] + P[110];
  assign soma[37] = P[111] + P[112] + P[113];
  assign soma[38] = P[114] + P[115] + P[116];
  assign soma[39] = P[117] + P[118] + P[119];
  assign soma[40] = P[120] + P[121] + P[122];
  assign soma[41] = P[123] + P[124] + P[125];
  assign soma[42] = P[126] + P[127] + P[128];
  assign soma[43] = P[129] + P[130] + P[131];
  assign soma[44] = P[132] + P[133] + P[134];
  assign soma[45] = P[135] + P[136] + P[137];
  assign soma[46] = P[138] + P[139] + P[140];
  assign soma[47] = P[141] + P[142] + P[143];
endmodule

module MatrixA0 #(
    parameter int NBITS = 20,
    parameter int CONV_OUTPUT_SIZE = 4,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 12
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign soma[0] = P[0] + P[4] + P[8];
  assign soma[1] = P[12] + P[16] + P[20];
  assign soma[2] = P[24] + P[28] + P[32];
  assign soma[3] = P[36] + P[40] + P[44];
  assign soma[4] = P[1] + P[5] + P[9];
  assign soma[5] = P[13] + P[17] + P[21];
  assign soma[6] = P[25] + P[29] + P[33];
  assign soma[7] = P[37] + P[41] + P[45];
  assign soma[8] = P[2] + P[6] + P[10];
  assign soma[9] = P[14] + P[18] + P[22];
  assign soma[10] = P[26] + P[30] + P[34];
  assign soma[11] = P[38] + P[42] + P[46];
  assign soma[12] = P[3] + P[7] + P[11];
  assign soma[13] = P[15] + P[19] + P[23];
  assign soma[14] = P[27] + P[31] + P[35];
  assign soma[15] = P[39] + P[43] + P[47];
endmodule
