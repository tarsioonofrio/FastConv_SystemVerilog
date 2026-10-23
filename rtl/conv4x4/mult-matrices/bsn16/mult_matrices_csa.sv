module Transform #(
    parameter int NBITS = 20,
    parameter int CONV_OUTPUT_SIZE = 4,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 7
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
    parameter int HADAMARD_SIZE = 7
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
    parameter int HADAMARD_SIZE = 7
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*CONV_INPUT_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic [NBITS-1:0] sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24, sp25, sp26, sp27, sp28, sp29, sp30, sp31, sp32, sp33, sp34, sp35, sp36, sp37, sp38, sp39, sp40, sp41;
  logic [NBITS-1:0] sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24, sn25, sn26, sn27, sn28, sn29, sn30, sn31, sn32, sn33, sn34, sn35, sn36, sn37, sn38, sn39, sn40, sn41;

  assign sp0 = P[0];
  CSA_4 #(.NBITS(NBITS)) csa_p1(P[1], P[2], P[3], P[4], sp1);
  CSA_2 #(.NBITS(NBITS)) csa_p2(P[2], P[4], sp2);
  CSA_2 #(.NBITS(NBITS)) csa_p3(P[3], P[4], sp3);
  assign sp4 = P[1];
  CSA_2 #(.NBITS(NBITS)) csa_p5(P[2], P[3], sp5);
  assign sp6 = P[5];
  assign sp7 = P[6];
  CSA_4 #(.NBITS(NBITS)) csa_p8(P[7], P[8], P[9], P[10], sp8);
  CSA_2 #(.NBITS(NBITS)) csa_p9(P[8], P[10], sp9);
  CSA_2 #(.NBITS(NBITS)) csa_p10(P[9], P[10], sp10);
  assign sp11 = P[7];
  CSA_2 #(.NBITS(NBITS)) csa_p12(P[8], P[9], sp12);
  assign sp13 = P[11];
  assign sp14 = P[12];
  CSA_4 #(.NBITS(NBITS)) csa_p15(P[13], P[14], P[15], P[16], sp15);
  CSA_2 #(.NBITS(NBITS)) csa_p16(P[14], P[16], sp16);
  CSA_2 #(.NBITS(NBITS)) csa_p17(P[15], P[16], sp17);
  assign sp18 = P[13];
  CSA_2 #(.NBITS(NBITS)) csa_p19(P[14], P[15], sp19);
  assign sp20 = P[17];
  assign sp21 = P[18];
  CSA_4 #(.NBITS(NBITS)) csa_p22(P[19], P[20], P[21], P[22], sp22);
  CSA_2 #(.NBITS(NBITS)) csa_p23(P[20], P[22], sp23);
  CSA_2 #(.NBITS(NBITS)) csa_p24(P[21], P[22], sp24);
  assign sp25 = P[19];
  CSA_2 #(.NBITS(NBITS)) csa_p26(P[20], P[21], sp26);
  assign sp27 = P[23];
  assign sp28 = P[24];
  CSA_4 #(.NBITS(NBITS)) csa_p29(P[25], P[26], P[27], P[28], sp29);
  CSA_2 #(.NBITS(NBITS)) csa_p30(P[26], P[28], sp30);
  CSA_2 #(.NBITS(NBITS)) csa_p31(P[27], P[28], sp31);
  assign sp32 = P[25];
  CSA_2 #(.NBITS(NBITS)) csa_p33(P[26], P[27], sp33);
  assign sp34 = P[29];
  assign sp35 = P[30];
  CSA_4 #(.NBITS(NBITS)) csa_p36(P[31], P[32], P[33], P[34], sp36);
  CSA_2 #(.NBITS(NBITS)) csa_p37(P[32], P[34], sp37);
  CSA_2 #(.NBITS(NBITS)) csa_p38(P[33], P[34], sp38);
  assign sp39 = P[31];
  CSA_2 #(.NBITS(NBITS)) csa_p40(P[32], P[33], sp40);
  assign sp41 = P[35];
  assign sn0 = P[4];
  CSA_2 #(.NBITS(NBITS)) csa_n2(P[1], P[3], sn2);
  CSA_2 #(.NBITS(NBITS)) csa_n3(P[1], P[2], sn3);
  assign sn4 = P[3];
  CSA_2 #(.NBITS(NBITS)) csa_n5(P[1], P[4], sn5);
  assign sn6 = P[1];
  assign sn7 = P[10];
  CSA_2 #(.NBITS(NBITS)) csa_n9(P[7], P[9], sn9);
  CSA_2 #(.NBITS(NBITS)) csa_n10(P[7], P[8], sn10);
  assign sn11 = P[9];
  CSA_2 #(.NBITS(NBITS)) csa_n12(P[7], P[10], sn12);
  assign sn13 = P[7];
  assign sn14 = P[16];
  CSA_2 #(.NBITS(NBITS)) csa_n16(P[13], P[15], sn16);
  CSA_2 #(.NBITS(NBITS)) csa_n17(P[13], P[14], sn17);
  assign sn18 = P[15];
  CSA_2 #(.NBITS(NBITS)) csa_n19(P[13], P[16], sn19);
  assign sn20 = P[13];
  assign sn21 = P[22];
  CSA_2 #(.NBITS(NBITS)) csa_n23(P[19], P[21], sn23);
  CSA_2 #(.NBITS(NBITS)) csa_n24(P[19], P[20], sn24);
  assign sn25 = P[21];
  CSA_2 #(.NBITS(NBITS)) csa_n26(P[19], P[22], sn26);
  assign sn27 = P[19];
  assign sn28 = P[28];
  CSA_2 #(.NBITS(NBITS)) csa_n30(P[25], P[27], sn30);
  CSA_2 #(.NBITS(NBITS)) csa_n31(P[25], P[26], sn31);
  assign sn32 = P[27];
  CSA_2 #(.NBITS(NBITS)) csa_n33(P[25], P[28], sn33);
  assign sn34 = P[25];
  assign sn35 = P[34];
  CSA_2 #(.NBITS(NBITS)) csa_n37(P[31], P[33], sn37);
  CSA_2 #(.NBITS(NBITS)) csa_n38(P[31], P[32], sn38);
  assign sn39 = P[33];
  CSA_2 #(.NBITS(NBITS)) csa_n40(P[31], P[34], sn40);
  assign sn41 = P[31];
  assign soma[0] = sp0 - sn0;
  assign soma[1] = sp1;
  assign soma[2] = sp2 - sn2;
  assign soma[3] = sp3 - sn3;
  assign soma[4] = sp4 - sn4;
  assign soma[5] = sp5 - sn5;
  assign soma[6] = sp6 - sn6;
  assign soma[7] = sp7 - sn7;
  assign soma[8] = sp8;
  assign soma[9] = sp9 - sn9;
  assign soma[10] = sp10 - sn10;
  assign soma[11] = sp11 - sn11;
  assign soma[12] = sp12 - sn12;
  assign soma[13] = sp13 - sn13;
  assign soma[14] = sp14 - sn14;
  assign soma[15] = sp15;
  assign soma[16] = sp16 - sn16;
  assign soma[17] = sp17 - sn17;
  assign soma[18] = sp18 - sn18;
  assign soma[19] = sp19 - sn19;
  assign soma[20] = sp20 - sn20;
  assign soma[21] = sp21 - sn21;
  assign soma[22] = sp22;
  assign soma[23] = sp23 - sn23;
  assign soma[24] = sp24 - sn24;
  assign soma[25] = sp25 - sn25;
  assign soma[26] = sp26 - sn26;
  assign soma[27] = sp27 - sn27;
  assign soma[28] = sp28 - sn28;
  assign soma[29] = sp29;
  assign soma[30] = sp30 - sn30;
  assign soma[31] = sp31 - sn31;
  assign soma[32] = sp32 - sn32;
  assign soma[33] = sp33 - sn33;
  assign soma[34] = sp34 - sn34;
  assign soma[35] = sp35 - sn35;
  assign soma[36] = sp36;
  assign soma[37] = sp37 - sn37;
  assign soma[38] = sp38 - sn38;
  assign soma[39] = sp39 - sn39;
  assign soma[40] = sp40 - sn40;
  assign soma[41] = sp41 - sn41;
endmodule

module MatrixC1 #(
    parameter int NBITS = 20,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 7
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [HADAMARD_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic [NBITS-1:0] sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24, sp25, sp26, sp27, sp28, sp29, sp30, sp31, sp32, sp33, sp34, sp35, sp36, sp37, sp38, sp39, sp40, sp41, sp42, sp43, sp44, sp45, sp46, sp47, sp48;
  logic [NBITS-1:0] sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24, sn25, sn26, sn27, sn28, sn29, sn30, sn31, sn32, sn33, sn34, sn35, sn36, sn37, sn38, sn39, sn40, sn41, sn42, sn43, sn44, sn45, sn46, sn47, sn48;

  assign sp0 = P[0];
  assign sp1 = P[1];
  assign sp2 = P[2];
  assign sp3 = P[3];
  assign sp4 = P[4];
  assign sp5 = P[5];
  assign sp6 = P[6];
  CSA_4 #(.NBITS(NBITS)) csa_p7(P[7], P[14], P[21], P[28], sp7);
  CSA_4 #(.NBITS(NBITS)) csa_p8(P[8], P[15], P[22], P[29], sp8);
  CSA_4 #(.NBITS(NBITS)) csa_p9(P[9], P[16], P[23], P[30], sp9);
  CSA_4 #(.NBITS(NBITS)) csa_p10(P[10], P[17], P[24], P[31], sp10);
  CSA_4 #(.NBITS(NBITS)) csa_p11(P[11], P[18], P[25], P[32], sp11);
  CSA_4 #(.NBITS(NBITS)) csa_p12(P[12], P[19], P[26], P[33], sp12);
  CSA_4 #(.NBITS(NBITS)) csa_p13(P[13], P[20], P[27], P[34], sp13);
  CSA_2 #(.NBITS(NBITS)) csa_p14(P[14], P[28], sp14);
  CSA_2 #(.NBITS(NBITS)) csa_p15(P[15], P[29], sp15);
  CSA_2 #(.NBITS(NBITS)) csa_p16(P[16], P[30], sp16);
  CSA_2 #(.NBITS(NBITS)) csa_p17(P[17], P[31], sp17);
  CSA_2 #(.NBITS(NBITS)) csa_p18(P[18], P[32], sp18);
  CSA_2 #(.NBITS(NBITS)) csa_p19(P[19], P[33], sp19);
  CSA_2 #(.NBITS(NBITS)) csa_p20(P[20], P[34], sp20);
  CSA_2 #(.NBITS(NBITS)) csa_p21(P[21], P[28], sp21);
  CSA_2 #(.NBITS(NBITS)) csa_p22(P[22], P[29], sp22);
  CSA_2 #(.NBITS(NBITS)) csa_p23(P[23], P[30], sp23);
  CSA_2 #(.NBITS(NBITS)) csa_p24(P[24], P[31], sp24);
  CSA_2 #(.NBITS(NBITS)) csa_p25(P[25], P[32], sp25);
  CSA_2 #(.NBITS(NBITS)) csa_p26(P[26], P[33], sp26);
  CSA_2 #(.NBITS(NBITS)) csa_p27(P[27], P[34], sp27);
  assign sp28 = P[7];
  assign sp29 = P[8];
  assign sp30 = P[9];
  assign sp31 = P[10];
  assign sp32 = P[11];
  assign sp33 = P[12];
  assign sp34 = P[13];
  CSA_2 #(.NBITS(NBITS)) csa_p35(P[14], P[21], sp35);
  CSA_2 #(.NBITS(NBITS)) csa_p36(P[15], P[22], sp36);
  CSA_2 #(.NBITS(NBITS)) csa_p37(P[16], P[23], sp37);
  CSA_2 #(.NBITS(NBITS)) csa_p38(P[17], P[24], sp38);
  CSA_2 #(.NBITS(NBITS)) csa_p39(P[18], P[25], sp39);
  CSA_2 #(.NBITS(NBITS)) csa_p40(P[19], P[26], sp40);
  CSA_2 #(.NBITS(NBITS)) csa_p41(P[20], P[27], sp41);
  assign sp42 = P[35];
  assign sp43 = P[36];
  assign sp44 = P[37];
  assign sp45 = P[38];
  assign sp46 = P[39];
  assign sp47 = P[40];
  assign sp48 = P[41];
  assign sn0 = P[28];
  assign sn1 = P[29];
  assign sn2 = P[30];
  assign sn3 = P[31];
  assign sn4 = P[32];
  assign sn5 = P[33];
  assign sn6 = P[34];
  CSA_2 #(.NBITS(NBITS)) csa_n14(P[7], P[21], sn14);
  CSA_2 #(.NBITS(NBITS)) csa_n15(P[8], P[22], sn15);
  CSA_2 #(.NBITS(NBITS)) csa_n16(P[9], P[23], sn16);
  CSA_2 #(.NBITS(NBITS)) csa_n17(P[10], P[24], sn17);
  CSA_2 #(.NBITS(NBITS)) csa_n18(P[11], P[25], sn18);
  CSA_2 #(.NBITS(NBITS)) csa_n19(P[12], P[26], sn19);
  CSA_2 #(.NBITS(NBITS)) csa_n20(P[13], P[27], sn20);
  CSA_2 #(.NBITS(NBITS)) csa_n21(P[7], P[14], sn21);
  CSA_2 #(.NBITS(NBITS)) csa_n22(P[8], P[15], sn22);
  CSA_2 #(.NBITS(NBITS)) csa_n23(P[9], P[16], sn23);
  CSA_2 #(.NBITS(NBITS)) csa_n24(P[10], P[17], sn24);
  CSA_2 #(.NBITS(NBITS)) csa_n25(P[11], P[18], sn25);
  CSA_2 #(.NBITS(NBITS)) csa_n26(P[12], P[19], sn26);
  CSA_2 #(.NBITS(NBITS)) csa_n27(P[13], P[20], sn27);
  assign sn28 = P[21];
  assign sn29 = P[22];
  assign sn30 = P[23];
  assign sn31 = P[24];
  assign sn32 = P[25];
  assign sn33 = P[26];
  assign sn34 = P[27];
  CSA_2 #(.NBITS(NBITS)) csa_n35(P[7], P[28], sn35);
  CSA_2 #(.NBITS(NBITS)) csa_n36(P[8], P[29], sn36);
  CSA_2 #(.NBITS(NBITS)) csa_n37(P[9], P[30], sn37);
  CSA_2 #(.NBITS(NBITS)) csa_n38(P[10], P[31], sn38);
  CSA_2 #(.NBITS(NBITS)) csa_n39(P[11], P[32], sn39);
  CSA_2 #(.NBITS(NBITS)) csa_n40(P[12], P[33], sn40);
  CSA_2 #(.NBITS(NBITS)) csa_n41(P[13], P[34], sn41);
  assign sn42 = P[7];
  assign sn43 = P[8];
  assign sn44 = P[9];
  assign sn45 = P[10];
  assign sn46 = P[11];
  assign sn47 = P[12];
  assign sn48 = P[13];
  assign soma[0] = sp0 - sn0;
  assign soma[1] = sp1 - sn1;
  assign soma[2] = sp2 - sn2;
  assign soma[3] = sp3 - sn3;
  assign soma[4] = sp4 - sn4;
  assign soma[5] = sp5 - sn5;
  assign soma[6] = sp6 - sn6;
  assign soma[7] = sp7;
  assign soma[8] = sp8;
  assign soma[9] = sp9;
  assign soma[10] = sp10;
  assign soma[11] = sp11;
  assign soma[12] = sp12;
  assign soma[13] = sp13;
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
  assign soma[24] = sp24 - sn24;
  assign soma[25] = sp25 - sn25;
  assign soma[26] = sp26 - sn26;
  assign soma[27] = sp27 - sn27;
  assign soma[28] = sp28 - sn28;
  assign soma[29] = sp29 - sn29;
  assign soma[30] = sp30 - sn30;
  assign soma[31] = sp31 - sn31;
  assign soma[32] = sp32 - sn32;
  assign soma[33] = sp33 - sn33;
  assign soma[34] = sp34 - sn34;
  assign soma[35] = sp35 - sn35;
  assign soma[36] = sp36 - sn36;
  assign soma[37] = sp37 - sn37;
  assign soma[38] = sp38 - sn38;
  assign soma[39] = sp39 - sn39;
  assign soma[40] = sp40 - sn40;
  assign soma[41] = sp41 - sn41;
  assign soma[42] = sp42 - sn42;
  assign soma[43] = sp43 - sn43;
  assign soma[44] = sp44 - sn44;
  assign soma[45] = sp45 - sn45;
  assign soma[46] = sp46 - sn46;
  assign soma[47] = sp47 - sn47;
  assign soma[48] = sp48 - sn48;
endmodule

module MatrixA1 #(
    parameter int NBITS = 20,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 7
  ) (
    input  logic [NBITS-1:0] P [HADAMARD_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic [NBITS-1:0] sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24, sp25, sp26, sp27;
  logic [NBITS-1:0] sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24, sn25, sn26, sn27;

  CSA_5 #(.NBITS(NBITS)) csa_p0(P[0], P[1], P[2], P[3], P[4], sp0);
  CSA_3 #(.NBITS(NBITS)) csa_p1(P[1], P[4], P[5], sp1);
  CSA_2 #(.NBITS(NBITS)) csa_p2(P[1], P[2], sp2);
  CSA_2 #(.NBITS(NBITS)) csa_p3(P[1], P[6], sp3);
  CSA_5 #(.NBITS(NBITS)) csa_p4(P[7], P[8], P[9], P[10], P[11], sp4);
  CSA_3 #(.NBITS(NBITS)) csa_p5(P[8], P[11], P[12], sp5);
  CSA_2 #(.NBITS(NBITS)) csa_p6(P[8], P[9], sp6);
  CSA_2 #(.NBITS(NBITS)) csa_p7(P[8], P[13], sp7);
  CSA_5 #(.NBITS(NBITS)) csa_p8(P[14], P[15], P[16], P[17], P[18], sp8);
  CSA_3 #(.NBITS(NBITS)) csa_p9(P[15], P[18], P[19], sp9);
  CSA_2 #(.NBITS(NBITS)) csa_p10(P[15], P[16], sp10);
  CSA_2 #(.NBITS(NBITS)) csa_p11(P[15], P[20], sp11);
  CSA_5 #(.NBITS(NBITS)) csa_p12(P[21], P[22], P[23], P[24], P[25], sp12);
  CSA_3 #(.NBITS(NBITS)) csa_p13(P[22], P[25], P[26], sp13);
  CSA_2 #(.NBITS(NBITS)) csa_p14(P[22], P[23], sp14);
  CSA_2 #(.NBITS(NBITS)) csa_p15(P[22], P[27], sp15);
  CSA_5 #(.NBITS(NBITS)) csa_p16(P[28], P[29], P[30], P[31], P[32], sp16);
  CSA_3 #(.NBITS(NBITS)) csa_p17(P[29], P[32], P[33], sp17);
  CSA_2 #(.NBITS(NBITS)) csa_p18(P[29], P[30], sp18);
  CSA_2 #(.NBITS(NBITS)) csa_p19(P[29], P[34], sp19);
  CSA_5 #(.NBITS(NBITS)) csa_p20(P[35], P[36], P[37], P[38], P[39], sp20);
  CSA_3 #(.NBITS(NBITS)) csa_p21(P[36], P[39], P[40], sp21);
  CSA_2 #(.NBITS(NBITS)) csa_p22(P[36], P[37], sp22);
  CSA_2 #(.NBITS(NBITS)) csa_p23(P[36], P[41], sp23);
  CSA_5 #(.NBITS(NBITS)) csa_p24(P[42], P[43], P[44], P[45], P[46], sp24);
  CSA_3 #(.NBITS(NBITS)) csa_p25(P[43], P[46], P[47], sp25);
  CSA_2 #(.NBITS(NBITS)) csa_p26(P[43], P[44], sp26);
  CSA_2 #(.NBITS(NBITS)) csa_p27(P[43], P[48], sp27);
  assign sn1 = P[2];
  CSA_2 #(.NBITS(NBITS)) csa_n2(P[3], P[4], sn2);
  CSA_3 #(.NBITS(NBITS)) csa_n3(P[2], P[4], P[5], sn3);
  assign sn5 = P[9];
  CSA_2 #(.NBITS(NBITS)) csa_n6(P[10], P[11], sn6);
  CSA_3 #(.NBITS(NBITS)) csa_n7(P[9], P[11], P[12], sn7);
  assign sn9 = P[16];
  CSA_2 #(.NBITS(NBITS)) csa_n10(P[17], P[18], sn10);
  CSA_3 #(.NBITS(NBITS)) csa_n11(P[16], P[18], P[19], sn11);
  assign sn13 = P[23];
  CSA_2 #(.NBITS(NBITS)) csa_n14(P[24], P[25], sn14);
  CSA_3 #(.NBITS(NBITS)) csa_n15(P[23], P[25], P[26], sn15);
  assign sn17 = P[30];
  CSA_2 #(.NBITS(NBITS)) csa_n18(P[31], P[32], sn18);
  CSA_3 #(.NBITS(NBITS)) csa_n19(P[30], P[32], P[33], sn19);
  assign sn21 = P[37];
  CSA_2 #(.NBITS(NBITS)) csa_n22(P[38], P[39], sn22);
  CSA_3 #(.NBITS(NBITS)) csa_n23(P[37], P[39], P[40], sn23);
  assign sn25 = P[44];
  CSA_2 #(.NBITS(NBITS)) csa_n26(P[45], P[46], sn26);
  CSA_3 #(.NBITS(NBITS)) csa_n27(P[44], P[46], P[47], sn27);
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
endmodule

module MatrixA0 #(
    parameter int NBITS = 20,
    parameter int CONV_OUTPUT_SIZE = 4,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 7
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic [NBITS-1:0] sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15;
  logic [NBITS-1:0] sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15;

  CSA_5 #(.NBITS(NBITS)) csa_p0(P[0], P[4], P[8], P[12], P[16], sp0);
  CSA_3 #(.NBITS(NBITS)) csa_p1(P[4], P[16], P[20], sp1);
  CSA_2 #(.NBITS(NBITS)) csa_p2(P[4], P[8], sp2);
  CSA_2 #(.NBITS(NBITS)) csa_p3(P[4], P[24], sp3);
  CSA_5 #(.NBITS(NBITS)) csa_p4(P[1], P[5], P[9], P[13], P[17], sp4);
  CSA_3 #(.NBITS(NBITS)) csa_p5(P[5], P[17], P[21], sp5);
  CSA_2 #(.NBITS(NBITS)) csa_p6(P[5], P[9], sp6);
  CSA_2 #(.NBITS(NBITS)) csa_p7(P[5], P[25], sp7);
  CSA_5 #(.NBITS(NBITS)) csa_p8(P[2], P[6], P[10], P[14], P[18], sp8);
  CSA_3 #(.NBITS(NBITS)) csa_p9(P[6], P[18], P[22], sp9);
  CSA_2 #(.NBITS(NBITS)) csa_p10(P[6], P[10], sp10);
  CSA_2 #(.NBITS(NBITS)) csa_p11(P[6], P[26], sp11);
  CSA_5 #(.NBITS(NBITS)) csa_p12(P[3], P[7], P[11], P[15], P[19], sp12);
  CSA_3 #(.NBITS(NBITS)) csa_p13(P[7], P[19], P[23], sp13);
  CSA_2 #(.NBITS(NBITS)) csa_p14(P[7], P[11], sp14);
  CSA_2 #(.NBITS(NBITS)) csa_p15(P[7], P[27], sp15);
  assign sn1 = P[8];
  CSA_2 #(.NBITS(NBITS)) csa_n2(P[12], P[16], sn2);
  CSA_3 #(.NBITS(NBITS)) csa_n3(P[8], P[16], P[20], sn3);
  assign sn5 = P[9];
  CSA_2 #(.NBITS(NBITS)) csa_n6(P[13], P[17], sn6);
  CSA_3 #(.NBITS(NBITS)) csa_n7(P[9], P[17], P[21], sn7);
  assign sn9 = P[10];
  CSA_2 #(.NBITS(NBITS)) csa_n10(P[14], P[18], sn10);
  CSA_3 #(.NBITS(NBITS)) csa_n11(P[10], P[18], P[22], sn11);
  assign sn13 = P[11];
  CSA_2 #(.NBITS(NBITS)) csa_n14(P[15], P[19], sn14);
  CSA_3 #(.NBITS(NBITS)) csa_n15(P[11], P[19], P[23], sn15);
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
