module Transform #(
    parameter int NBITS = 20,
    parameter int CONV_OUTPUT_SIZE = 4,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 8
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
    parameter int HADAMARD_SIZE = 8
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
    parameter int HADAMARD_SIZE = 8
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*CONV_INPUT_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic [NBITS-1:0] sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24, sp25, sp26, sp27, sp28, sp29, sp30, sp31, sp32, sp33, sp34, sp35, sp36, sp37, sp38, sp39, sp40, sp41, sp42, sp43, sp44, sp45, sp46, sp47;
  logic [NBITS-1:0] sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24, sn25, sn26, sn27, sn28, sn29, sn30, sn31, sn32, sn33, sn34, sn35, sn36, sn37, sn38, sn39, sn40, sn41, sn42, sn43, sn44, sn45, sn46, sn47;

  assign sp0 = P[5];
  assign sp1 = P[3];
  assign sp2 = P[1];
  CSA_2 #(.NBITS(NBITS)) csa_p3(P[2], P[4], sp3);
  CSA_2 #(.NBITS(NBITS)) csa_p5(P[0], P[2], sp5);
  assign sp6 = P[1];
  assign sp7 = P[3];
  assign sp8 = P[11];
  assign sp9 = P[9];
  assign sp10 = P[7];
  CSA_2 #(.NBITS(NBITS)) csa_p11(P[8], P[10], sp11);
  CSA_2 #(.NBITS(NBITS)) csa_p13(P[6], P[8], sp13);
  assign sp14 = P[7];
  assign sp15 = P[9];
  assign sp16 = P[17];
  assign sp17 = P[15];
  assign sp18 = P[13];
  CSA_2 #(.NBITS(NBITS)) csa_p19(P[14], P[16], sp19);
  CSA_2 #(.NBITS(NBITS)) csa_p21(P[12], P[14], sp21);
  assign sp22 = P[13];
  assign sp23 = P[15];
  assign sp24 = P[23];
  assign sp25 = P[21];
  assign sp26 = P[19];
  CSA_2 #(.NBITS(NBITS)) csa_p27(P[20], P[22], sp27);
  CSA_2 #(.NBITS(NBITS)) csa_p29(P[18], P[20], sp29);
  assign sp30 = P[19];
  assign sp31 = P[21];
  assign sp32 = P[29];
  assign sp33 = P[27];
  assign sp34 = P[25];
  CSA_2 #(.NBITS(NBITS)) csa_p35(P[26], P[28], sp35);
  CSA_2 #(.NBITS(NBITS)) csa_p37(P[24], P[26], sp37);
  assign sp38 = P[25];
  assign sp39 = P[27];
  assign sp40 = P[35];
  assign sp41 = P[33];
  assign sp42 = P[31];
  CSA_2 #(.NBITS(NBITS)) csa_p43(P[32], P[34], sp43);
  CSA_2 #(.NBITS(NBITS)) csa_p45(P[30], P[32], sp45);
  assign sp46 = P[31];
  assign sp47 = P[33];
  assign sn0 = P[3];
  assign sn1 = P[4];
  assign sn2 = P[2];
  assign sn4 = P[2];
  assign sn6 = P[3];
  assign sn8 = P[9];
  assign sn9 = P[10];
  assign sn10 = P[8];
  assign sn12 = P[8];
  assign sn14 = P[9];
  assign sn16 = P[15];
  assign sn17 = P[16];
  assign sn18 = P[14];
  assign sn20 = P[14];
  assign sn22 = P[15];
  assign sn24 = P[21];
  assign sn25 = P[22];
  assign sn26 = P[20];
  assign sn28 = P[20];
  assign sn30 = P[21];
  assign sn32 = P[27];
  assign sn33 = P[28];
  assign sn34 = P[26];
  assign sn36 = P[26];
  assign sn38 = P[27];
  assign sn40 = P[33];
  assign sn41 = P[34];
  assign sn42 = P[32];
  assign sn44 = P[32];
  assign sn46 = P[33];
  assign soma[0] = sp0 - sn0;
  assign soma[1] = sp1 - sn1;
  assign soma[2] = sp2 - sn2;
  assign soma[3] = sp3;
  assign soma[4] = sn4;
  assign soma[5] = sp5;
  assign soma[6] = sp6 - sn6;
  assign soma[7] = sp7;
  assign soma[8] = sp8 - sn8;
  assign soma[9] = sp9 - sn9;
  assign soma[10] = sp10 - sn10;
  assign soma[11] = sp11;
  assign soma[12] = sn12;
  assign soma[13] = sp13;
  assign soma[14] = sp14 - sn14;
  assign soma[15] = sp15;
  assign soma[16] = sp16 - sn16;
  assign soma[17] = sp17 - sn17;
  assign soma[18] = sp18 - sn18;
  assign soma[19] = sp19;
  assign soma[20] = sn20;
  assign soma[21] = sp21;
  assign soma[22] = sp22 - sn22;
  assign soma[23] = sp23;
  assign soma[24] = sp24 - sn24;
  assign soma[25] = sp25 - sn25;
  assign soma[26] = sp26 - sn26;
  assign soma[27] = sp27;
  assign soma[28] = sn28;
  assign soma[29] = sp29;
  assign soma[30] = sp30 - sn30;
  assign soma[31] = sp31;
  assign soma[32] = sp32 - sn32;
  assign soma[33] = sp33 - sn33;
  assign soma[34] = sp34 - sn34;
  assign soma[35] = sp35;
  assign soma[36] = sn36;
  assign soma[37] = sp37;
  assign soma[38] = sp38 - sn38;
  assign soma[39] = sp39;
  assign soma[40] = sp40 - sn40;
  assign soma[41] = sp41 - sn41;
  assign soma[42] = sp42 - sn42;
  assign soma[43] = sp43;
  assign soma[44] = sn44;
  assign soma[45] = sp45;
  assign soma[46] = sp46 - sn46;
  assign soma[47] = sp47;
endmodule

module MatrixC1 #(
    parameter int NBITS = 20,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 8
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [HADAMARD_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic [NBITS-1:0] sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24, sp25, sp26, sp27, sp28, sp29, sp30, sp31, sp32, sp33, sp34, sp35, sp36, sp37, sp38, sp39, sp40, sp41, sp42, sp43, sp44, sp45, sp46, sp47, sp48, sp49, sp50, sp51, sp52, sp53, sp54, sp55, sp56, sp57, sp58, sp59, sp60, sp61, sp62, sp63;
  logic [NBITS-1:0] sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24, sn25, sn26, sn27, sn28, sn29, sn30, sn31, sn32, sn33, sn34, sn35, sn36, sn37, sn38, sn39, sn40, sn41, sn42, sn43, sn44, sn45, sn46, sn47, sn48, sn49, sn50, sn51, sn52, sn53, sn54, sn55, sn56, sn57, sn58, sn59, sn60, sn61, sn62, sn63;

  assign sp0 = P[40];
  assign sp1 = P[41];
  assign sp2 = P[42];
  assign sp3 = P[43];
  assign sp4 = P[44];
  assign sp5 = P[45];
  assign sp6 = P[46];
  assign sp7 = P[47];
  assign sp8 = P[24];
  assign sp9 = P[25];
  assign sp10 = P[26];
  assign sp11 = P[27];
  assign sp12 = P[28];
  assign sp13 = P[29];
  assign sp14 = P[30];
  assign sp15 = P[31];
  assign sp16 = P[8];
  assign sp17 = P[9];
  assign sp18 = P[10];
  assign sp19 = P[11];
  assign sp20 = P[12];
  assign sp21 = P[13];
  assign sp22 = P[14];
  assign sp23 = P[15];
  CSA_2 #(.NBITS(NBITS)) csa_p24(P[16], P[32], sp24);
  CSA_2 #(.NBITS(NBITS)) csa_p25(P[17], P[33], sp25);
  CSA_2 #(.NBITS(NBITS)) csa_p26(P[18], P[34], sp26);
  CSA_2 #(.NBITS(NBITS)) csa_p27(P[19], P[35], sp27);
  CSA_2 #(.NBITS(NBITS)) csa_p28(P[20], P[36], sp28);
  CSA_2 #(.NBITS(NBITS)) csa_p29(P[21], P[37], sp29);
  CSA_2 #(.NBITS(NBITS)) csa_p30(P[22], P[38], sp30);
  CSA_2 #(.NBITS(NBITS)) csa_p31(P[23], P[39], sp31);
  CSA_2 #(.NBITS(NBITS)) csa_p40(P[0], P[16], sp40);
  CSA_2 #(.NBITS(NBITS)) csa_p41(P[1], P[17], sp41);
  CSA_2 #(.NBITS(NBITS)) csa_p42(P[2], P[18], sp42);
  CSA_2 #(.NBITS(NBITS)) csa_p43(P[3], P[19], sp43);
  CSA_2 #(.NBITS(NBITS)) csa_p44(P[4], P[20], sp44);
  CSA_2 #(.NBITS(NBITS)) csa_p45(P[5], P[21], sp45);
  CSA_2 #(.NBITS(NBITS)) csa_p46(P[6], P[22], sp46);
  CSA_2 #(.NBITS(NBITS)) csa_p47(P[7], P[23], sp47);
  assign sp48 = P[8];
  assign sp49 = P[9];
  assign sp50 = P[10];
  assign sp51 = P[11];
  assign sp52 = P[12];
  assign sp53 = P[13];
  assign sp54 = P[14];
  assign sp55 = P[15];
  assign sp56 = P[24];
  assign sp57 = P[25];
  assign sp58 = P[26];
  assign sp59 = P[27];
  assign sp60 = P[28];
  assign sp61 = P[29];
  assign sp62 = P[30];
  assign sp63 = P[31];
  assign sn0 = P[24];
  assign sn1 = P[25];
  assign sn2 = P[26];
  assign sn3 = P[27];
  assign sn4 = P[28];
  assign sn5 = P[29];
  assign sn6 = P[30];
  assign sn7 = P[31];
  assign sn8 = P[32];
  assign sn9 = P[33];
  assign sn10 = P[34];
  assign sn11 = P[35];
  assign sn12 = P[36];
  assign sn13 = P[37];
  assign sn14 = P[38];
  assign sn15 = P[39];
  assign sn16 = P[16];
  assign sn17 = P[17];
  assign sn18 = P[18];
  assign sn19 = P[19];
  assign sn20 = P[20];
  assign sn21 = P[21];
  assign sn22 = P[22];
  assign sn23 = P[23];
  assign sn32 = P[16];
  assign sn33 = P[17];
  assign sn34 = P[18];
  assign sn35 = P[19];
  assign sn36 = P[20];
  assign sn37 = P[21];
  assign sn38 = P[22];
  assign sn39 = P[23];
  assign sn48 = P[24];
  assign sn49 = P[25];
  assign sn50 = P[26];
  assign sn51 = P[27];
  assign sn52 = P[28];
  assign sn53 = P[29];
  assign sn54 = P[30];
  assign sn55 = P[31];
  assign soma[0] = sp0 - sn0;
  assign soma[1] = sp1 - sn1;
  assign soma[2] = sp2 - sn2;
  assign soma[3] = sp3 - sn3;
  assign soma[4] = sp4 - sn4;
  assign soma[5] = sp5 - sn5;
  assign soma[6] = sp6 - sn6;
  assign soma[7] = sp7 - sn7;
  assign soma[8] = sp8 - sn8;
  assign soma[9] = sp9 - sn9;
  assign soma[10] = sp10 - sn10;
  assign soma[11] = sp11 - sn11;
  assign soma[12] = sp12 - sn12;
  assign soma[13] = sp13 - sn13;
  assign soma[14] = sp14 - sn14;
  assign soma[15] = sp15 - sn15;
  assign soma[16] = sp16 - sn16;
  assign soma[17] = sp17 - sn17;
  assign soma[18] = sp18 - sn18;
  assign soma[19] = sp19 - sn19;
  assign soma[20] = sp20 - sn20;
  assign soma[21] = sp21 - sn21;
  assign soma[22] = sp22 - sn22;
  assign soma[23] = sp23 - sn23;
  assign soma[24] = sp24;
  assign soma[25] = sp25;
  assign soma[26] = sp26;
  assign soma[27] = sp27;
  assign soma[28] = sp28;
  assign soma[29] = sp29;
  assign soma[30] = sp30;
  assign soma[31] = sp31;
  assign soma[32] = sn32;
  assign soma[33] = sn33;
  assign soma[34] = sn34;
  assign soma[35] = sn35;
  assign soma[36] = sn36;
  assign soma[37] = sn37;
  assign soma[38] = sn38;
  assign soma[39] = sn39;
  assign soma[40] = sp40;
  assign soma[41] = sp41;
  assign soma[42] = sp42;
  assign soma[43] = sp43;
  assign soma[44] = sp44;
  assign soma[45] = sp45;
  assign soma[46] = sp46;
  assign soma[47] = sp47;
  assign soma[48] = sp48 - sn48;
  assign soma[49] = sp49 - sn49;
  assign soma[50] = sp50 - sn50;
  assign soma[51] = sp51 - sn51;
  assign soma[52] = sp52 - sn52;
  assign soma[53] = sp53 - sn53;
  assign soma[54] = sp54 - sn54;
  assign soma[55] = sp55 - sn55;
  assign soma[56] = sp56;
  assign soma[57] = sp57;
  assign soma[58] = sp58;
  assign soma[59] = sp59;
  assign soma[60] = sp60;
  assign soma[61] = sp61;
  assign soma[62] = sp62;
  assign soma[63] = sp63;
endmodule

module MatrixA1 #(
    parameter int NBITS = 20,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 8
  ) (
    input  logic [NBITS-1:0] P [HADAMARD_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic [NBITS-1:0] sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24, sp25, sp26, sp27, sp28, sp29, sp30, sp31;
  logic [NBITS-1:0] sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24, sn25, sn26, sn27, sn28, sn29, sn30, sn31;

  CSA_3 #(.NBITS(NBITS)) csa_p0(P[2], P[4], P[5], sp0);
  CSA_2 #(.NBITS(NBITS)) csa_p1(P[6], P[7], sp1);
  CSA_2 #(.NBITS(NBITS)) csa_p2(P[1], P[3], sp2);
  CSA_2 #(.NBITS(NBITS)) csa_p3(P[0], P[7], sp3);
  CSA_3 #(.NBITS(NBITS)) csa_p4(P[10], P[12], P[13], sp4);
  CSA_2 #(.NBITS(NBITS)) csa_p5(P[14], P[15], sp5);
  CSA_2 #(.NBITS(NBITS)) csa_p6(P[9], P[11], sp6);
  CSA_2 #(.NBITS(NBITS)) csa_p7(P[8], P[15], sp7);
  CSA_3 #(.NBITS(NBITS)) csa_p8(P[18], P[20], P[21], sp8);
  CSA_2 #(.NBITS(NBITS)) csa_p9(P[22], P[23], sp9);
  CSA_2 #(.NBITS(NBITS)) csa_p10(P[17], P[19], sp10);
  CSA_2 #(.NBITS(NBITS)) csa_p11(P[16], P[23], sp11);
  CSA_3 #(.NBITS(NBITS)) csa_p12(P[26], P[28], P[29], sp12);
  CSA_2 #(.NBITS(NBITS)) csa_p13(P[30], P[31], sp13);
  CSA_2 #(.NBITS(NBITS)) csa_p14(P[25], P[27], sp14);
  CSA_2 #(.NBITS(NBITS)) csa_p15(P[24], P[31], sp15);
  CSA_3 #(.NBITS(NBITS)) csa_p16(P[34], P[36], P[37], sp16);
  CSA_2 #(.NBITS(NBITS)) csa_p17(P[38], P[39], sp17);
  CSA_2 #(.NBITS(NBITS)) csa_p18(P[33], P[35], sp18);
  CSA_2 #(.NBITS(NBITS)) csa_p19(P[32], P[39], sp19);
  CSA_3 #(.NBITS(NBITS)) csa_p20(P[42], P[44], P[45], sp20);
  CSA_2 #(.NBITS(NBITS)) csa_p21(P[46], P[47], sp21);
  CSA_2 #(.NBITS(NBITS)) csa_p22(P[41], P[43], sp22);
  CSA_2 #(.NBITS(NBITS)) csa_p23(P[40], P[47], sp23);
  CSA_3 #(.NBITS(NBITS)) csa_p24(P[50], P[52], P[53], sp24);
  CSA_2 #(.NBITS(NBITS)) csa_p25(P[54], P[55], sp25);
  CSA_2 #(.NBITS(NBITS)) csa_p26(P[49], P[51], sp26);
  CSA_2 #(.NBITS(NBITS)) csa_p27(P[48], P[55], sp27);
  CSA_3 #(.NBITS(NBITS)) csa_p28(P[58], P[60], P[61], sp28);
  CSA_2 #(.NBITS(NBITS)) csa_p29(P[62], P[63], sp29);
  CSA_2 #(.NBITS(NBITS)) csa_p30(P[57], P[59], sp30);
  CSA_2 #(.NBITS(NBITS)) csa_p31(P[56], P[63], sp31);
  assign sn1 = P[2];
  assign sn2 = P[4];
  assign sn3 = P[1];
  assign sn5 = P[10];
  assign sn6 = P[12];
  assign sn7 = P[9];
  assign sn9 = P[18];
  assign sn10 = P[20];
  assign sn11 = P[17];
  assign sn13 = P[26];
  assign sn14 = P[28];
  assign sn15 = P[25];
  assign sn17 = P[34];
  assign sn18 = P[36];
  assign sn19 = P[33];
  assign sn21 = P[42];
  assign sn22 = P[44];
  assign sn23 = P[41];
  assign sn25 = P[50];
  assign sn26 = P[52];
  assign sn27 = P[49];
  assign sn29 = P[58];
  assign sn30 = P[60];
  assign sn31 = P[57];
  assign soma[0] = sp0;
  assign soma[1] = sp1 - sn1;
  assign soma[2] = sp2 - sn2;
  assign soma[3] = sp3 - sn3;
  assign soma[4] = sp4;
  assign soma[5] = sp5 - sn5;
  assign soma[6] = sp6 - sn6;
  assign soma[7] = sp7 - sn7;
  assign soma[8] = sp8;
  assign soma[9] = sp9 - sn9;
  assign soma[10] = sp10 - sn10;
  assign soma[11] = sp11 - sn11;
  assign soma[12] = sp12;
  assign soma[13] = sp13 - sn13;
  assign soma[14] = sp14 - sn14;
  assign soma[15] = sp15 - sn15;
  assign soma[16] = sp16;
  assign soma[17] = sp17 - sn17;
  assign soma[18] = sp18 - sn18;
  assign soma[19] = sp19 - sn19;
  assign soma[20] = sp20;
  assign soma[21] = sp21 - sn21;
  assign soma[22] = sp22 - sn22;
  assign soma[23] = sp23 - sn23;
  assign soma[24] = sp24;
  assign soma[25] = sp25 - sn25;
  assign soma[26] = sp26 - sn26;
  assign soma[27] = sp27 - sn27;
  assign soma[28] = sp28;
  assign soma[29] = sp29 - sn29;
  assign soma[30] = sp30 - sn30;
  assign soma[31] = sp31 - sn31;
endmodule

module MatrixA0 #(
    parameter int NBITS = 20,
    parameter int CONV_OUTPUT_SIZE = 4,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 8
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic [NBITS-1:0] sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15;
  logic [NBITS-1:0] sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15;

  CSA_3 #(.NBITS(NBITS)) csa_p0(P[8], P[16], P[20], sp0);
  CSA_2 #(.NBITS(NBITS)) csa_p1(P[24], P[28], sp1);
  CSA_2 #(.NBITS(NBITS)) csa_p2(P[4], P[12], sp2);
  CSA_2 #(.NBITS(NBITS)) csa_p3(P[0], P[28], sp3);
  CSA_3 #(.NBITS(NBITS)) csa_p4(P[9], P[17], P[21], sp4);
  CSA_2 #(.NBITS(NBITS)) csa_p5(P[25], P[29], sp5);
  CSA_2 #(.NBITS(NBITS)) csa_p6(P[5], P[13], sp6);
  CSA_2 #(.NBITS(NBITS)) csa_p7(P[1], P[29], sp7);
  CSA_3 #(.NBITS(NBITS)) csa_p8(P[10], P[18], P[22], sp8);
  CSA_2 #(.NBITS(NBITS)) csa_p9(P[26], P[30], sp9);
  CSA_2 #(.NBITS(NBITS)) csa_p10(P[6], P[14], sp10);
  CSA_2 #(.NBITS(NBITS)) csa_p11(P[2], P[30], sp11);
  CSA_3 #(.NBITS(NBITS)) csa_p12(P[11], P[19], P[23], sp12);
  CSA_2 #(.NBITS(NBITS)) csa_p13(P[27], P[31], sp13);
  CSA_2 #(.NBITS(NBITS)) csa_p14(P[7], P[15], sp14);
  CSA_2 #(.NBITS(NBITS)) csa_p15(P[3], P[31], sp15);
  assign sn1 = P[8];
  assign sn2 = P[16];
  assign sn3 = P[4];
  assign sn5 = P[9];
  assign sn6 = P[17];
  assign sn7 = P[5];
  assign sn9 = P[10];
  assign sn10 = P[18];
  assign sn11 = P[6];
  assign sn13 = P[11];
  assign sn14 = P[19];
  assign sn15 = P[7];
  assign soma[0] = sp0;
  assign soma[1] = sp1 - sn1;
  assign soma[2] = sp2 - sn2;
  assign soma[3] = sp3 - sn3;
  assign soma[4] = sp4;
  assign soma[5] = sp5 - sn5;
  assign soma[6] = sp6 - sn6;
  assign soma[7] = sp7 - sn7;
  assign soma[8] = sp8;
  assign soma[9] = sp9 - sn9;
  assign soma[10] = sp10 - sn10;
  assign soma[11] = sp11 - sn11;
  assign soma[12] = sp12;
  assign soma[13] = sp13 - sn13;
  assign soma[14] = sp14 - sn14;
  assign soma[15] = sp15 - sn15;
endmodule
