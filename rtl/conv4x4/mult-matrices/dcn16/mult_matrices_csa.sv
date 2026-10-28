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
  logic [NBITS-1:0] sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24, sp25, sp26, sp27, sp28, sp29, sp30, sp31, sp32, sp33, sp34, sp35, sp36, sp37, sp38, sp39, sp40, sp41, sp42, sp43, sp44, sp45, sp46, sp47, sp48, sp49, sp50, sp51, sp52, sp53, sp54, sp55, sp56, sp57, sp58, sp59, sp60, sp61, sp62, sp63, sp64, sp65, sp66, sp67, sp68, sp69, sp70, sp71;
  logic [NBITS-1:0] sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24, sn25, sn26, sn27, sn28, sn29, sn30, sn31, sn32, sn33, sn34, sn35, sn36, sn37, sn38, sn39, sn40, sn41, sn42, sn43, sn44, sn45, sn46, sn47, sn48, sn49, sn50, sn51, sn52, sn53, sn54, sn55, sn56, sn57, sn58, sn59, sn60, sn61, sn62, sn63, sn64, sn65, sn66, sn67, sn68, sn69, sn70, sn71;

  assign sp0 = P[0];
  assign sp1 = P[1];
  assign sp2 = P[2];
  assign sp3 = P[1];
  assign sp4 = P[2];
  assign sp5 = P[3];
  assign sp6 = P[2];
  assign sp7 = P[3];
  assign sp8 = P[4];
  assign sp9 = P[3];
  assign sp10 = P[4];
  assign sp11 = P[5];
  assign sp12 = P[6];
  assign sp13 = P[7];
  assign sp14 = P[8];
  assign sp15 = P[7];
  assign sp16 = P[8];
  assign sp17 = P[9];
  assign sp18 = P[8];
  assign sp19 = P[9];
  assign sp20 = P[10];
  assign sp21 = P[9];
  assign sp22 = P[10];
  assign sp23 = P[11];
  assign sp24 = P[12];
  assign sp25 = P[13];
  assign sp26 = P[14];
  assign sp27 = P[13];
  assign sp28 = P[14];
  assign sp29 = P[15];
  assign sp30 = P[14];
  assign sp31 = P[15];
  assign sp32 = P[16];
  assign sp33 = P[15];
  assign sp34 = P[16];
  assign sp35 = P[17];
  assign sp36 = P[18];
  assign sp37 = P[19];
  assign sp38 = P[20];
  assign sp39 = P[19];
  assign sp40 = P[20];
  assign sp41 = P[21];
  assign sp42 = P[20];
  assign sp43 = P[21];
  assign sp44 = P[22];
  assign sp45 = P[21];
  assign sp46 = P[22];
  assign sp47 = P[23];
  assign sp48 = P[24];
  assign sp49 = P[25];
  assign sp50 = P[26];
  assign sp51 = P[25];
  assign sp52 = P[26];
  assign sp53 = P[27];
  assign sp54 = P[26];
  assign sp55 = P[27];
  assign sp56 = P[28];
  assign sp57 = P[27];
  assign sp58 = P[28];
  assign sp59 = P[29];
  assign sp60 = P[30];
  assign sp61 = P[31];
  assign sp62 = P[32];
  assign sp63 = P[31];
  assign sp64 = P[32];
  assign sp65 = P[33];
  assign sp66 = P[32];
  assign sp67 = P[33];
  assign sp68 = P[34];
  assign sp69 = P[33];
  assign sp70 = P[34];
  assign sp71 = P[35];
  assign soma[0] = sp0;
  assign soma[1] = sp1;
  assign soma[2] = sp2;
  assign soma[3] = sp3;
  assign soma[4] = sp4;
  assign soma[5] = sp5;
  assign soma[6] = sp6;
  assign soma[7] = sp7;
  assign soma[8] = sp8;
  assign soma[9] = sp9;
  assign soma[10] = sp10;
  assign soma[11] = sp11;
  assign soma[12] = sp12;
  assign soma[13] = sp13;
  assign soma[14] = sp14;
  assign soma[15] = sp15;
  assign soma[16] = sp16;
  assign soma[17] = sp17;
  assign soma[18] = sp18;
  assign soma[19] = sp19;
  assign soma[20] = sp20;
  assign soma[21] = sp21;
  assign soma[22] = sp22;
  assign soma[23] = sp23;
  assign soma[24] = sp24;
  assign soma[25] = sp25;
  assign soma[26] = sp26;
  assign soma[27] = sp27;
  assign soma[28] = sp28;
  assign soma[29] = sp29;
  assign soma[30] = sp30;
  assign soma[31] = sp31;
  assign soma[32] = sp32;
  assign soma[33] = sp33;
  assign soma[34] = sp34;
  assign soma[35] = sp35;
  assign soma[36] = sp36;
  assign soma[37] = sp37;
  assign soma[38] = sp38;
  assign soma[39] = sp39;
  assign soma[40] = sp40;
  assign soma[41] = sp41;
  assign soma[42] = sp42;
  assign soma[43] = sp43;
  assign soma[44] = sp44;
  assign soma[45] = sp45;
  assign soma[46] = sp46;
  assign soma[47] = sp47;
  assign soma[48] = sp48;
  assign soma[49] = sp49;
  assign soma[50] = sp50;
  assign soma[51] = sp51;
  assign soma[52] = sp52;
  assign soma[53] = sp53;
  assign soma[54] = sp54;
  assign soma[55] = sp55;
  assign soma[56] = sp56;
  assign soma[57] = sp57;
  assign soma[58] = sp58;
  assign soma[59] = sp59;
  assign soma[60] = sp60;
  assign soma[61] = sp61;
  assign soma[62] = sp62;
  assign soma[63] = sp63;
  assign soma[64] = sp64;
  assign soma[65] = sp65;
  assign soma[66] = sp66;
  assign soma[67] = sp67;
  assign soma[68] = sp68;
  assign soma[69] = sp69;
  assign soma[70] = sp70;
  assign soma[71] = sp71;
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
  logic [NBITS-1:0] sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24, sp25, sp26, sp27, sp28, sp29, sp30, sp31, sp32, sp33, sp34, sp35, sp36, sp37, sp38, sp39, sp40, sp41, sp42, sp43, sp44, sp45, sp46, sp47, sp48, sp49, sp50, sp51, sp52, sp53, sp54, sp55, sp56, sp57, sp58, sp59, sp60, sp61, sp62, sp63, sp64, sp65, sp66, sp67, sp68, sp69, sp70, sp71, sp72, sp73, sp74, sp75, sp76, sp77, sp78, sp79, sp80, sp81, sp82, sp83, sp84, sp85, sp86, sp87, sp88, sp89, sp90, sp91, sp92, sp93, sp94, sp95, sp96, sp97, sp98, sp99, sp100, sp101, sp102, sp103, sp104, sp105, sp106, sp107, sp108, sp109, sp110, sp111, sp112, sp113, sp114, sp115, sp116, sp117, sp118, sp119, sp120, sp121, sp122, sp123, sp124, sp125, sp126, sp127, sp128, sp129, sp130, sp131, sp132, sp133, sp134, sp135, sp136, sp137, sp138, sp139, sp140, sp141, sp142, sp143;
  logic [NBITS-1:0] sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24, sn25, sn26, sn27, sn28, sn29, sn30, sn31, sn32, sn33, sn34, sn35, sn36, sn37, sn38, sn39, sn40, sn41, sn42, sn43, sn44, sn45, sn46, sn47, sn48, sn49, sn50, sn51, sn52, sn53, sn54, sn55, sn56, sn57, sn58, sn59, sn60, sn61, sn62, sn63, sn64, sn65, sn66, sn67, sn68, sn69, sn70, sn71, sn72, sn73, sn74, sn75, sn76, sn77, sn78, sn79, sn80, sn81, sn82, sn83, sn84, sn85, sn86, sn87, sn88, sn89, sn90, sn91, sn92, sn93, sn94, sn95, sn96, sn97, sn98, sn99, sn100, sn101, sn102, sn103, sn104, sn105, sn106, sn107, sn108, sn109, sn110, sn111, sn112, sn113, sn114, sn115, sn116, sn117, sn118, sn119, sn120, sn121, sn122, sn123, sn124, sn125, sn126, sn127, sn128, sn129, sn130, sn131, sn132, sn133, sn134, sn135, sn136, sn137, sn138, sn139, sn140, sn141, sn142, sn143;

  assign sp0 = P[0];
  assign sp1 = P[1];
  assign sp2 = P[2];
  assign sp3 = P[3];
  assign sp4 = P[4];
  assign sp5 = P[5];
  assign sp6 = P[6];
  assign sp7 = P[7];
  assign sp8 = P[8];
  assign sp9 = P[9];
  assign sp10 = P[10];
  assign sp11 = P[11];
  assign sp12 = P[12];
  assign sp13 = P[13];
  assign sp14 = P[14];
  assign sp15 = P[15];
  assign sp16 = P[16];
  assign sp17 = P[17];
  assign sp18 = P[18];
  assign sp19 = P[19];
  assign sp20 = P[20];
  assign sp21 = P[21];
  assign sp22 = P[22];
  assign sp23 = P[23];
  assign sp24 = P[24];
  assign sp25 = P[25];
  assign sp26 = P[26];
  assign sp27 = P[27];
  assign sp28 = P[28];
  assign sp29 = P[29];
  assign sp30 = P[30];
  assign sp31 = P[31];
  assign sp32 = P[32];
  assign sp33 = P[33];
  assign sp34 = P[34];
  assign sp35 = P[35];
  assign sp36 = P[12];
  assign sp37 = P[13];
  assign sp38 = P[14];
  assign sp39 = P[15];
  assign sp40 = P[16];
  assign sp41 = P[17];
  assign sp42 = P[18];
  assign sp43 = P[19];
  assign sp44 = P[20];
  assign sp45 = P[21];
  assign sp46 = P[22];
  assign sp47 = P[23];
  assign sp48 = P[24];
  assign sp49 = P[25];
  assign sp50 = P[26];
  assign sp51 = P[27];
  assign sp52 = P[28];
  assign sp53 = P[29];
  assign sp54 = P[30];
  assign sp55 = P[31];
  assign sp56 = P[32];
  assign sp57 = P[33];
  assign sp58 = P[34];
  assign sp59 = P[35];
  assign sp60 = P[36];
  assign sp61 = P[37];
  assign sp62 = P[38];
  assign sp63 = P[39];
  assign sp64 = P[40];
  assign sp65 = P[41];
  assign sp66 = P[42];
  assign sp67 = P[43];
  assign sp68 = P[44];
  assign sp69 = P[45];
  assign sp70 = P[46];
  assign sp71 = P[47];
  assign sp72 = P[24];
  assign sp73 = P[25];
  assign sp74 = P[26];
  assign sp75 = P[27];
  assign sp76 = P[28];
  assign sp77 = P[29];
  assign sp78 = P[30];
  assign sp79 = P[31];
  assign sp80 = P[32];
  assign sp81 = P[33];
  assign sp82 = P[34];
  assign sp83 = P[35];
  assign sp84 = P[36];
  assign sp85 = P[37];
  assign sp86 = P[38];
  assign sp87 = P[39];
  assign sp88 = P[40];
  assign sp89 = P[41];
  assign sp90 = P[42];
  assign sp91 = P[43];
  assign sp92 = P[44];
  assign sp93 = P[45];
  assign sp94 = P[46];
  assign sp95 = P[47];
  assign sp96 = P[48];
  assign sp97 = P[49];
  assign sp98 = P[50];
  assign sp99 = P[51];
  assign sp100 = P[52];
  assign sp101 = P[53];
  assign sp102 = P[54];
  assign sp103 = P[55];
  assign sp104 = P[56];
  assign sp105 = P[57];
  assign sp106 = P[58];
  assign sp107 = P[59];
  assign sp108 = P[36];
  assign sp109 = P[37];
  assign sp110 = P[38];
  assign sp111 = P[39];
  assign sp112 = P[40];
  assign sp113 = P[41];
  assign sp114 = P[42];
  assign sp115 = P[43];
  assign sp116 = P[44];
  assign sp117 = P[45];
  assign sp118 = P[46];
  assign sp119 = P[47];
  assign sp120 = P[48];
  assign sp121 = P[49];
  assign sp122 = P[50];
  assign sp123 = P[51];
  assign sp124 = P[52];
  assign sp125 = P[53];
  assign sp126 = P[54];
  assign sp127 = P[55];
  assign sp128 = P[56];
  assign sp129 = P[57];
  assign sp130 = P[58];
  assign sp131 = P[59];
  assign sp132 = P[60];
  assign sp133 = P[61];
  assign sp134 = P[62];
  assign sp135 = P[63];
  assign sp136 = P[64];
  assign sp137 = P[65];
  assign sp138 = P[66];
  assign sp139 = P[67];
  assign sp140 = P[68];
  assign sp141 = P[69];
  assign sp142 = P[70];
  assign sp143 = P[71];
  assign soma[0] = sp0;
  assign soma[1] = sp1;
  assign soma[2] = sp2;
  assign soma[3] = sp3;
  assign soma[4] = sp4;
  assign soma[5] = sp5;
  assign soma[6] = sp6;
  assign soma[7] = sp7;
  assign soma[8] = sp8;
  assign soma[9] = sp9;
  assign soma[10] = sp10;
  assign soma[11] = sp11;
  assign soma[12] = sp12;
  assign soma[13] = sp13;
  assign soma[14] = sp14;
  assign soma[15] = sp15;
  assign soma[16] = sp16;
  assign soma[17] = sp17;
  assign soma[18] = sp18;
  assign soma[19] = sp19;
  assign soma[20] = sp20;
  assign soma[21] = sp21;
  assign soma[22] = sp22;
  assign soma[23] = sp23;
  assign soma[24] = sp24;
  assign soma[25] = sp25;
  assign soma[26] = sp26;
  assign soma[27] = sp27;
  assign soma[28] = sp28;
  assign soma[29] = sp29;
  assign soma[30] = sp30;
  assign soma[31] = sp31;
  assign soma[32] = sp32;
  assign soma[33] = sp33;
  assign soma[34] = sp34;
  assign soma[35] = sp35;
  assign soma[36] = sp36;
  assign soma[37] = sp37;
  assign soma[38] = sp38;
  assign soma[39] = sp39;
  assign soma[40] = sp40;
  assign soma[41] = sp41;
  assign soma[42] = sp42;
  assign soma[43] = sp43;
  assign soma[44] = sp44;
  assign soma[45] = sp45;
  assign soma[46] = sp46;
  assign soma[47] = sp47;
  assign soma[48] = sp48;
  assign soma[49] = sp49;
  assign soma[50] = sp50;
  assign soma[51] = sp51;
  assign soma[52] = sp52;
  assign soma[53] = sp53;
  assign soma[54] = sp54;
  assign soma[55] = sp55;
  assign soma[56] = sp56;
  assign soma[57] = sp57;
  assign soma[58] = sp58;
  assign soma[59] = sp59;
  assign soma[60] = sp60;
  assign soma[61] = sp61;
  assign soma[62] = sp62;
  assign soma[63] = sp63;
  assign soma[64] = sp64;
  assign soma[65] = sp65;
  assign soma[66] = sp66;
  assign soma[67] = sp67;
  assign soma[68] = sp68;
  assign soma[69] = sp69;
  assign soma[70] = sp70;
  assign soma[71] = sp71;
  assign soma[72] = sp72;
  assign soma[73] = sp73;
  assign soma[74] = sp74;
  assign soma[75] = sp75;
  assign soma[76] = sp76;
  assign soma[77] = sp77;
  assign soma[78] = sp78;
  assign soma[79] = sp79;
  assign soma[80] = sp80;
  assign soma[81] = sp81;
  assign soma[82] = sp82;
  assign soma[83] = sp83;
  assign soma[84] = sp84;
  assign soma[85] = sp85;
  assign soma[86] = sp86;
  assign soma[87] = sp87;
  assign soma[88] = sp88;
  assign soma[89] = sp89;
  assign soma[90] = sp90;
  assign soma[91] = sp91;
  assign soma[92] = sp92;
  assign soma[93] = sp93;
  assign soma[94] = sp94;
  assign soma[95] = sp95;
  assign soma[96] = sp96;
  assign soma[97] = sp97;
  assign soma[98] = sp98;
  assign soma[99] = sp99;
  assign soma[100] = sp100;
  assign soma[101] = sp101;
  assign soma[102] = sp102;
  assign soma[103] = sp103;
  assign soma[104] = sp104;
  assign soma[105] = sp105;
  assign soma[106] = sp106;
  assign soma[107] = sp107;
  assign soma[108] = sp108;
  assign soma[109] = sp109;
  assign soma[110] = sp110;
  assign soma[111] = sp111;
  assign soma[112] = sp112;
  assign soma[113] = sp113;
  assign soma[114] = sp114;
  assign soma[115] = sp115;
  assign soma[116] = sp116;
  assign soma[117] = sp117;
  assign soma[118] = sp118;
  assign soma[119] = sp119;
  assign soma[120] = sp120;
  assign soma[121] = sp121;
  assign soma[122] = sp122;
  assign soma[123] = sp123;
  assign soma[124] = sp124;
  assign soma[125] = sp125;
  assign soma[126] = sp126;
  assign soma[127] = sp127;
  assign soma[128] = sp128;
  assign soma[129] = sp129;
  assign soma[130] = sp130;
  assign soma[131] = sp131;
  assign soma[132] = sp132;
  assign soma[133] = sp133;
  assign soma[134] = sp134;
  assign soma[135] = sp135;
  assign soma[136] = sp136;
  assign soma[137] = sp137;
  assign soma[138] = sp138;
  assign soma[139] = sp139;
  assign soma[140] = sp140;
  assign soma[141] = sp141;
  assign soma[142] = sp142;
  assign soma[143] = sp143;
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
  logic [NBITS-1:0] sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24, sp25, sp26, sp27, sp28, sp29, sp30, sp31, sp32, sp33, sp34, sp35, sp36, sp37, sp38, sp39, sp40, sp41, sp42, sp43, sp44, sp45, sp46, sp47;
  logic [NBITS-1:0] sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24, sn25, sn26, sn27, sn28, sn29, sn30, sn31, sn32, sn33, sn34, sn35, sn36, sn37, sn38, sn39, sn40, sn41, sn42, sn43, sn44, sn45, sn46, sn47;

  CSA_3 #(.NBITS(NBITS)) csa_p0(P[0], P[1], P[2], sp0);
  CSA_3 #(.NBITS(NBITS)) csa_p1(P[3], P[4], P[5], sp1);
  CSA_3 #(.NBITS(NBITS)) csa_p2(P[6], P[7], P[8], sp2);
  CSA_3 #(.NBITS(NBITS)) csa_p3(P[9], P[10], P[11], sp3);
  CSA_3 #(.NBITS(NBITS)) csa_p4(P[12], P[13], P[14], sp4);
  CSA_3 #(.NBITS(NBITS)) csa_p5(P[15], P[16], P[17], sp5);
  CSA_3 #(.NBITS(NBITS)) csa_p6(P[18], P[19], P[20], sp6);
  CSA_3 #(.NBITS(NBITS)) csa_p7(P[21], P[22], P[23], sp7);
  CSA_3 #(.NBITS(NBITS)) csa_p8(P[24], P[25], P[26], sp8);
  CSA_3 #(.NBITS(NBITS)) csa_p9(P[27], P[28], P[29], sp9);
  CSA_3 #(.NBITS(NBITS)) csa_p10(P[30], P[31], P[32], sp10);
  CSA_3 #(.NBITS(NBITS)) csa_p11(P[33], P[34], P[35], sp11);
  CSA_3 #(.NBITS(NBITS)) csa_p12(P[36], P[37], P[38], sp12);
  CSA_3 #(.NBITS(NBITS)) csa_p13(P[39], P[40], P[41], sp13);
  CSA_3 #(.NBITS(NBITS)) csa_p14(P[42], P[43], P[44], sp14);
  CSA_3 #(.NBITS(NBITS)) csa_p15(P[45], P[46], P[47], sp15);
  CSA_3 #(.NBITS(NBITS)) csa_p16(P[48], P[49], P[50], sp16);
  CSA_3 #(.NBITS(NBITS)) csa_p17(P[51], P[52], P[53], sp17);
  CSA_3 #(.NBITS(NBITS)) csa_p18(P[54], P[55], P[56], sp18);
  CSA_3 #(.NBITS(NBITS)) csa_p19(P[57], P[58], P[59], sp19);
  CSA_3 #(.NBITS(NBITS)) csa_p20(P[60], P[61], P[62], sp20);
  CSA_3 #(.NBITS(NBITS)) csa_p21(P[63], P[64], P[65], sp21);
  CSA_3 #(.NBITS(NBITS)) csa_p22(P[66], P[67], P[68], sp22);
  CSA_3 #(.NBITS(NBITS)) csa_p23(P[69], P[70], P[71], sp23);
  CSA_3 #(.NBITS(NBITS)) csa_p24(P[72], P[73], P[74], sp24);
  CSA_3 #(.NBITS(NBITS)) csa_p25(P[75], P[76], P[77], sp25);
  CSA_3 #(.NBITS(NBITS)) csa_p26(P[78], P[79], P[80], sp26);
  CSA_3 #(.NBITS(NBITS)) csa_p27(P[81], P[82], P[83], sp27);
  CSA_3 #(.NBITS(NBITS)) csa_p28(P[84], P[85], P[86], sp28);
  CSA_3 #(.NBITS(NBITS)) csa_p29(P[87], P[88], P[89], sp29);
  CSA_3 #(.NBITS(NBITS)) csa_p30(P[90], P[91], P[92], sp30);
  CSA_3 #(.NBITS(NBITS)) csa_p31(P[93], P[94], P[95], sp31);
  CSA_3 #(.NBITS(NBITS)) csa_p32(P[96], P[97], P[98], sp32);
  CSA_3 #(.NBITS(NBITS)) csa_p33(P[99], P[100], P[101], sp33);
  CSA_3 #(.NBITS(NBITS)) csa_p34(P[102], P[103], P[104], sp34);
  CSA_3 #(.NBITS(NBITS)) csa_p35(P[105], P[106], P[107], sp35);
  CSA_3 #(.NBITS(NBITS)) csa_p36(P[108], P[109], P[110], sp36);
  CSA_3 #(.NBITS(NBITS)) csa_p37(P[111], P[112], P[113], sp37);
  CSA_3 #(.NBITS(NBITS)) csa_p38(P[114], P[115], P[116], sp38);
  CSA_3 #(.NBITS(NBITS)) csa_p39(P[117], P[118], P[119], sp39);
  CSA_3 #(.NBITS(NBITS)) csa_p40(P[120], P[121], P[122], sp40);
  CSA_3 #(.NBITS(NBITS)) csa_p41(P[123], P[124], P[125], sp41);
  CSA_3 #(.NBITS(NBITS)) csa_p42(P[126], P[127], P[128], sp42);
  CSA_3 #(.NBITS(NBITS)) csa_p43(P[129], P[130], P[131], sp43);
  CSA_3 #(.NBITS(NBITS)) csa_p44(P[132], P[133], P[134], sp44);
  CSA_3 #(.NBITS(NBITS)) csa_p45(P[135], P[136], P[137], sp45);
  CSA_3 #(.NBITS(NBITS)) csa_p46(P[138], P[139], P[140], sp46);
  CSA_3 #(.NBITS(NBITS)) csa_p47(P[141], P[142], P[143], sp47);
  assign soma[0] = sp0;
  assign soma[1] = sp1;
  assign soma[2] = sp2;
  assign soma[3] = sp3;
  assign soma[4] = sp4;
  assign soma[5] = sp5;
  assign soma[6] = sp6;
  assign soma[7] = sp7;
  assign soma[8] = sp8;
  assign soma[9] = sp9;
  assign soma[10] = sp10;
  assign soma[11] = sp11;
  assign soma[12] = sp12;
  assign soma[13] = sp13;
  assign soma[14] = sp14;
  assign soma[15] = sp15;
  assign soma[16] = sp16;
  assign soma[17] = sp17;
  assign soma[18] = sp18;
  assign soma[19] = sp19;
  assign soma[20] = sp20;
  assign soma[21] = sp21;
  assign soma[22] = sp22;
  assign soma[23] = sp23;
  assign soma[24] = sp24;
  assign soma[25] = sp25;
  assign soma[26] = sp26;
  assign soma[27] = sp27;
  assign soma[28] = sp28;
  assign soma[29] = sp29;
  assign soma[30] = sp30;
  assign soma[31] = sp31;
  assign soma[32] = sp32;
  assign soma[33] = sp33;
  assign soma[34] = sp34;
  assign soma[35] = sp35;
  assign soma[36] = sp36;
  assign soma[37] = sp37;
  assign soma[38] = sp38;
  assign soma[39] = sp39;
  assign soma[40] = sp40;
  assign soma[41] = sp41;
  assign soma[42] = sp42;
  assign soma[43] = sp43;
  assign soma[44] = sp44;
  assign soma[45] = sp45;
  assign soma[46] = sp46;
  assign soma[47] = sp47;
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
  logic [NBITS-1:0] sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15;
  logic [NBITS-1:0] sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15;

  CSA_3 #(.NBITS(NBITS)) csa_p0(P[0], P[4], P[8], sp0);
  CSA_3 #(.NBITS(NBITS)) csa_p1(P[12], P[16], P[20], sp1);
  CSA_3 #(.NBITS(NBITS)) csa_p2(P[24], P[28], P[32], sp2);
  CSA_3 #(.NBITS(NBITS)) csa_p3(P[36], P[40], P[44], sp3);
  CSA_3 #(.NBITS(NBITS)) csa_p4(P[1], P[5], P[9], sp4);
  CSA_3 #(.NBITS(NBITS)) csa_p5(P[13], P[17], P[21], sp5);
  CSA_3 #(.NBITS(NBITS)) csa_p6(P[25], P[29], P[33], sp6);
  CSA_3 #(.NBITS(NBITS)) csa_p7(P[37], P[41], P[45], sp7);
  CSA_3 #(.NBITS(NBITS)) csa_p8(P[2], P[6], P[10], sp8);
  CSA_3 #(.NBITS(NBITS)) csa_p9(P[14], P[18], P[22], sp9);
  CSA_3 #(.NBITS(NBITS)) csa_p10(P[26], P[30], P[34], sp10);
  CSA_3 #(.NBITS(NBITS)) csa_p11(P[38], P[42], P[46], sp11);
  CSA_3 #(.NBITS(NBITS)) csa_p12(P[3], P[7], P[11], sp12);
  CSA_3 #(.NBITS(NBITS)) csa_p13(P[15], P[19], P[23], sp13);
  CSA_3 #(.NBITS(NBITS)) csa_p14(P[27], P[31], P[35], sp14);
  CSA_3 #(.NBITS(NBITS)) csa_p15(P[39], P[43], P[47], sp15);
  assign soma[0] = sp0;
  assign soma[1] = sp1;
  assign soma[2] = sp2;
  assign soma[3] = sp3;
  assign soma[4] = sp4;
  assign soma[5] = sp5;
  assign soma[6] = sp6;
  assign soma[7] = sp7;
  assign soma[8] = sp8;
  assign soma[9] = sp9;
  assign soma[10] = sp10;
  assign soma[11] = sp11;
  assign soma[12] = sp12;
  assign soma[13] = sp13;
  assign soma[14] = sp14;
  assign soma[15] = sp15;
endmodule
