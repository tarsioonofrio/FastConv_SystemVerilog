module Transform #(
    parameter int NBITS = 20,
    parameter int CONV_OUTPUT_SIZE = 4,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 6
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
    parameter int HADAMARD_SIZE = 6
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
    parameter int HADAMARD_SIZE = 6
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*CONV_INPUT_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic [NBITS-1:0] sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24, sp25, sp26, sp27, sp28, sp29, sp30, sp31, sp32, sp33, sp34, sp35;
  logic [NBITS-1:0] sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24, sn25, sn26, sn27, sn28, sn29, sn30, sn31, sn32, sn33, sn34, sn35;

  CSA_2 #(.NBITS(NBITS)) csa_p0(P[0] <<< 2, P[4], sp0);
  CSA_2 #(.NBITS(NBITS)) csa_p1(P[3], P[4], sp1);
  CSA_2 #(.NBITS(NBITS)) csa_p2(P[1] <<< 2, P[4], sp2);
  CSA_2 #(.NBITS(NBITS)) csa_p3(P[3] <<< 1, P[4], sp3);
  CSA_2 #(.NBITS(NBITS)) csa_p4(P[1] <<< 1, P[4], sp4);
  CSA_2 #(.NBITS(NBITS)) csa_p5(P[1] <<< 2, P[5], sp5);
  CSA_2 #(.NBITS(NBITS)) csa_p6(P[6] <<< 2, P[10], sp6);
  CSA_2 #(.NBITS(NBITS)) csa_p7(P[9], P[10], sp7);
  CSA_2 #(.NBITS(NBITS)) csa_p8(P[7] <<< 2, P[10], sp8);
  CSA_2 #(.NBITS(NBITS)) csa_p9(P[9] <<< 1, P[10], sp9);
  CSA_2 #(.NBITS(NBITS)) csa_p10(P[7] <<< 1, P[10], sp10);
  CSA_2 #(.NBITS(NBITS)) csa_p11(P[7] <<< 2, P[11], sp11);
  CSA_2 #(.NBITS(NBITS)) csa_p12(P[12] <<< 2, P[16], sp12);
  CSA_2 #(.NBITS(NBITS)) csa_p13(P[15], P[16], sp13);
  CSA_2 #(.NBITS(NBITS)) csa_p14(P[13] <<< 2, P[16], sp14);
  CSA_2 #(.NBITS(NBITS)) csa_p15(P[15] <<< 1, P[16], sp15);
  CSA_2 #(.NBITS(NBITS)) csa_p16(P[13] <<< 1, P[16], sp16);
  CSA_2 #(.NBITS(NBITS)) csa_p17(P[13] <<< 2, P[17], sp17);
  CSA_2 #(.NBITS(NBITS)) csa_p18(P[18] <<< 2, P[22], sp18);
  CSA_2 #(.NBITS(NBITS)) csa_p19(P[21], P[22], sp19);
  CSA_2 #(.NBITS(NBITS)) csa_p20(P[19] <<< 2, P[22], sp20);
  CSA_2 #(.NBITS(NBITS)) csa_p21(P[21] <<< 1, P[22], sp21);
  CSA_2 #(.NBITS(NBITS)) csa_p22(P[19] <<< 1, P[22], sp22);
  CSA_2 #(.NBITS(NBITS)) csa_p23(P[19] <<< 2, P[23], sp23);
  CSA_2 #(.NBITS(NBITS)) csa_p24(P[24] <<< 2, P[28], sp24);
  CSA_2 #(.NBITS(NBITS)) csa_p25(P[27], P[28], sp25);
  CSA_2 #(.NBITS(NBITS)) csa_p26(P[25] <<< 2, P[28], sp26);
  CSA_2 #(.NBITS(NBITS)) csa_p27(P[27] <<< 1, P[28], sp27);
  CSA_2 #(.NBITS(NBITS)) csa_p28(P[25] <<< 1, P[28], sp28);
  CSA_2 #(.NBITS(NBITS)) csa_p29(P[25] <<< 2, P[29], sp29);
  CSA_2 #(.NBITS(NBITS)) csa_p30(P[30] <<< 2, P[34], sp30);
  CSA_2 #(.NBITS(NBITS)) csa_p31(P[33], P[34], sp31);
  CSA_2 #(.NBITS(NBITS)) csa_p32(P[31] <<< 2, P[34], sp32);
  CSA_2 #(.NBITS(NBITS)) csa_p33(P[33] <<< 1, P[34], sp33);
  CSA_2 #(.NBITS(NBITS)) csa_p34(P[31] <<< 1, P[34], sp34);
  CSA_2 #(.NBITS(NBITS)) csa_p35(P[31] <<< 2, P[35], sp35);
  CSA_2 #(.NBITS(NBITS)) csa_n0(P[2], P[2] <<< 2, sn0);
  CSA_2 #(.NBITS(NBITS)) csa_n1(P[1] <<< 2, P[2] <<< 2, sn1);
  CSA_2 #(.NBITS(NBITS)) csa_n2(P[2] <<< 2, P[3], sn2);
  CSA_2 #(.NBITS(NBITS)) csa_n3(P[1] <<< 1, P[2], sn3);
  CSA_2 #(.NBITS(NBITS)) csa_n4(P[2], P[3] <<< 1, sn4);
  CSA_2 #(.NBITS(NBITS)) csa_n5(P[3], P[3] <<< 2, sn5);
  CSA_2 #(.NBITS(NBITS)) csa_n6(P[8], P[8] <<< 2, sn6);
  CSA_2 #(.NBITS(NBITS)) csa_n7(P[7] <<< 2, P[8] <<< 2, sn7);
  CSA_2 #(.NBITS(NBITS)) csa_n8(P[8] <<< 2, P[9], sn8);
  CSA_2 #(.NBITS(NBITS)) csa_n9(P[7] <<< 1, P[8], sn9);
  CSA_2 #(.NBITS(NBITS)) csa_n10(P[8], P[9] <<< 1, sn10);
  CSA_2 #(.NBITS(NBITS)) csa_n11(P[9], P[9] <<< 2, sn11);
  CSA_2 #(.NBITS(NBITS)) csa_n12(P[14], P[14] <<< 2, sn12);
  CSA_2 #(.NBITS(NBITS)) csa_n13(P[13] <<< 2, P[14] <<< 2, sn13);
  CSA_2 #(.NBITS(NBITS)) csa_n14(P[14] <<< 2, P[15], sn14);
  CSA_2 #(.NBITS(NBITS)) csa_n15(P[13] <<< 1, P[14], sn15);
  CSA_2 #(.NBITS(NBITS)) csa_n16(P[14], P[15] <<< 1, sn16);
  CSA_2 #(.NBITS(NBITS)) csa_n17(P[15], P[15] <<< 2, sn17);
  CSA_2 #(.NBITS(NBITS)) csa_n18(P[20], P[20] <<< 2, sn18);
  CSA_2 #(.NBITS(NBITS)) csa_n19(P[19] <<< 2, P[20] <<< 2, sn19);
  CSA_2 #(.NBITS(NBITS)) csa_n20(P[20] <<< 2, P[21], sn20);
  CSA_2 #(.NBITS(NBITS)) csa_n21(P[19] <<< 1, P[20], sn21);
  CSA_2 #(.NBITS(NBITS)) csa_n22(P[20], P[21] <<< 1, sn22);
  CSA_2 #(.NBITS(NBITS)) csa_n23(P[21], P[21] <<< 2, sn23);
  CSA_2 #(.NBITS(NBITS)) csa_n24(P[26], P[26] <<< 2, sn24);
  CSA_2 #(.NBITS(NBITS)) csa_n25(P[25] <<< 2, P[26] <<< 2, sn25);
  CSA_2 #(.NBITS(NBITS)) csa_n26(P[26] <<< 2, P[27], sn26);
  CSA_2 #(.NBITS(NBITS)) csa_n27(P[25] <<< 1, P[26], sn27);
  CSA_2 #(.NBITS(NBITS)) csa_n28(P[26], P[27] <<< 1, sn28);
  CSA_2 #(.NBITS(NBITS)) csa_n29(P[27], P[27] <<< 2, sn29);
  CSA_2 #(.NBITS(NBITS)) csa_n30(P[32], P[32] <<< 2, sn30);
  CSA_2 #(.NBITS(NBITS)) csa_n31(P[31] <<< 2, P[32] <<< 2, sn31);
  CSA_2 #(.NBITS(NBITS)) csa_n32(P[32] <<< 2, P[33], sn32);
  CSA_2 #(.NBITS(NBITS)) csa_n33(P[31] <<< 1, P[32], sn33);
  CSA_2 #(.NBITS(NBITS)) csa_n34(P[32], P[33] <<< 1, sn34);
  CSA_2 #(.NBITS(NBITS)) csa_n35(P[33], P[33] <<< 2, sn35);
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
endmodule

module MatrixC1 #(
    parameter int NBITS = 20,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 6
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [HADAMARD_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic [NBITS-1:0] sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24, sp25, sp26, sp27, sp28, sp29, sp30, sp31, sp32, sp33, sp34, sp35;
  logic [NBITS-1:0] sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24, sn25, sn26, sn27, sn28, sn29, sn30, sn31, sn32, sn33, sn34, sn35;

  CSA_2 #(.NBITS(NBITS)) csa_p0(P[0] <<< 2, P[24], sp0);
  CSA_2 #(.NBITS(NBITS)) csa_p1(P[1] <<< 2, P[25], sp1);
  CSA_2 #(.NBITS(NBITS)) csa_p2(P[2] <<< 2, P[26], sp2);
  CSA_2 #(.NBITS(NBITS)) csa_p3(P[3] <<< 2, P[27], sp3);
  CSA_2 #(.NBITS(NBITS)) csa_p4(P[4] <<< 2, P[28], sp4);
  CSA_2 #(.NBITS(NBITS)) csa_p5(P[5] <<< 2, P[29], sp5);
  CSA_2 #(.NBITS(NBITS)) csa_p6(P[18], P[24], sp6);
  CSA_2 #(.NBITS(NBITS)) csa_p7(P[19], P[25], sp7);
  CSA_2 #(.NBITS(NBITS)) csa_p8(P[20], P[26], sp8);
  CSA_2 #(.NBITS(NBITS)) csa_p9(P[21], P[27], sp9);
  CSA_2 #(.NBITS(NBITS)) csa_p10(P[22], P[28], sp10);
  CSA_2 #(.NBITS(NBITS)) csa_p11(P[23], P[29], sp11);
  CSA_2 #(.NBITS(NBITS)) csa_p12(P[6] <<< 2, P[24], sp12);
  CSA_2 #(.NBITS(NBITS)) csa_p13(P[7] <<< 2, P[25], sp13);
  CSA_2 #(.NBITS(NBITS)) csa_p14(P[8] <<< 2, P[26], sp14);
  CSA_2 #(.NBITS(NBITS)) csa_p15(P[9] <<< 2, P[27], sp15);
  CSA_2 #(.NBITS(NBITS)) csa_p16(P[10] <<< 2, P[28], sp16);
  CSA_2 #(.NBITS(NBITS)) csa_p17(P[11] <<< 2, P[29], sp17);
  CSA_2 #(.NBITS(NBITS)) csa_p18(P[18] <<< 1, P[24], sp18);
  CSA_2 #(.NBITS(NBITS)) csa_p19(P[19] <<< 1, P[25], sp19);
  CSA_2 #(.NBITS(NBITS)) csa_p20(P[20] <<< 1, P[26], sp20);
  CSA_2 #(.NBITS(NBITS)) csa_p21(P[21] <<< 1, P[27], sp21);
  CSA_2 #(.NBITS(NBITS)) csa_p22(P[22] <<< 1, P[28], sp22);
  CSA_2 #(.NBITS(NBITS)) csa_p23(P[23] <<< 1, P[29], sp23);
  CSA_2 #(.NBITS(NBITS)) csa_p24(P[6] <<< 1, P[24], sp24);
  CSA_2 #(.NBITS(NBITS)) csa_p25(P[7] <<< 1, P[25], sp25);
  CSA_2 #(.NBITS(NBITS)) csa_p26(P[8] <<< 1, P[26], sp26);
  CSA_2 #(.NBITS(NBITS)) csa_p27(P[9] <<< 1, P[27], sp27);
  CSA_2 #(.NBITS(NBITS)) csa_p28(P[10] <<< 1, P[28], sp28);
  CSA_2 #(.NBITS(NBITS)) csa_p29(P[11] <<< 1, P[29], sp29);
  CSA_2 #(.NBITS(NBITS)) csa_p30(P[6] <<< 2, P[30], sp30);
  CSA_2 #(.NBITS(NBITS)) csa_p31(P[7] <<< 2, P[31], sp31);
  CSA_2 #(.NBITS(NBITS)) csa_p32(P[8] <<< 2, P[32], sp32);
  CSA_2 #(.NBITS(NBITS)) csa_p33(P[9] <<< 2, P[33], sp33);
  CSA_2 #(.NBITS(NBITS)) csa_p34(P[10] <<< 2, P[34], sp34);
  CSA_2 #(.NBITS(NBITS)) csa_p35(P[11] <<< 2, P[35], sp35);
  CSA_2 #(.NBITS(NBITS)) csa_n0(P[12], P[12] <<< 2, sn0);
  CSA_2 #(.NBITS(NBITS)) csa_n1(P[13], P[13] <<< 2, sn1);
  CSA_2 #(.NBITS(NBITS)) csa_n2(P[14], P[14] <<< 2, sn2);
  CSA_2 #(.NBITS(NBITS)) csa_n3(P[15], P[15] <<< 2, sn3);
  CSA_2 #(.NBITS(NBITS)) csa_n4(P[16], P[16] <<< 2, sn4);
  CSA_2 #(.NBITS(NBITS)) csa_n5(P[17], P[17] <<< 2, sn5);
  CSA_2 #(.NBITS(NBITS)) csa_n6(P[6] <<< 2, P[12] <<< 2, sn6);
  CSA_2 #(.NBITS(NBITS)) csa_n7(P[7] <<< 2, P[13] <<< 2, sn7);
  CSA_2 #(.NBITS(NBITS)) csa_n8(P[8] <<< 2, P[14] <<< 2, sn8);
  CSA_2 #(.NBITS(NBITS)) csa_n9(P[9] <<< 2, P[15] <<< 2, sn9);
  CSA_2 #(.NBITS(NBITS)) csa_n10(P[10] <<< 2, P[16] <<< 2, sn10);
  CSA_2 #(.NBITS(NBITS)) csa_n11(P[11] <<< 2, P[17] <<< 2, sn11);
  CSA_2 #(.NBITS(NBITS)) csa_n12(P[12] <<< 2, P[18], sn12);
  CSA_2 #(.NBITS(NBITS)) csa_n13(P[13] <<< 2, P[19], sn13);
  CSA_2 #(.NBITS(NBITS)) csa_n14(P[14] <<< 2, P[20], sn14);
  CSA_2 #(.NBITS(NBITS)) csa_n15(P[15] <<< 2, P[21], sn15);
  CSA_2 #(.NBITS(NBITS)) csa_n16(P[16] <<< 2, P[22], sn16);
  CSA_2 #(.NBITS(NBITS)) csa_n17(P[17] <<< 2, P[23], sn17);
  CSA_2 #(.NBITS(NBITS)) csa_n18(P[6] <<< 1, P[12], sn18);
  CSA_2 #(.NBITS(NBITS)) csa_n19(P[7] <<< 1, P[13], sn19);
  CSA_2 #(.NBITS(NBITS)) csa_n20(P[8] <<< 1, P[14], sn20);
  CSA_2 #(.NBITS(NBITS)) csa_n21(P[9] <<< 1, P[15], sn21);
  CSA_2 #(.NBITS(NBITS)) csa_n22(P[10] <<< 1, P[16], sn22);
  CSA_2 #(.NBITS(NBITS)) csa_n23(P[11] <<< 1, P[17], sn23);
  CSA_2 #(.NBITS(NBITS)) csa_n24(P[12], P[18] <<< 1, sn24);
  CSA_2 #(.NBITS(NBITS)) csa_n25(P[13], P[19] <<< 1, sn25);
  CSA_2 #(.NBITS(NBITS)) csa_n26(P[14], P[20] <<< 1, sn26);
  CSA_2 #(.NBITS(NBITS)) csa_n27(P[15], P[21] <<< 1, sn27);
  CSA_2 #(.NBITS(NBITS)) csa_n28(P[16], P[22] <<< 1, sn28);
  CSA_2 #(.NBITS(NBITS)) csa_n29(P[17], P[23] <<< 1, sn29);
  CSA_2 #(.NBITS(NBITS)) csa_n30(P[18], P[18] <<< 2, sn30);
  CSA_2 #(.NBITS(NBITS)) csa_n31(P[19], P[19] <<< 2, sn31);
  CSA_2 #(.NBITS(NBITS)) csa_n32(P[20], P[20] <<< 2, sn32);
  CSA_2 #(.NBITS(NBITS)) csa_n33(P[21], P[21] <<< 2, sn33);
  CSA_2 #(.NBITS(NBITS)) csa_n34(P[22], P[22] <<< 2, sn34);
  CSA_2 #(.NBITS(NBITS)) csa_n35(P[23], P[23] <<< 2, sn35);
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
endmodule

module MatrixA1 #(
    parameter int NBITS = 20,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 6
  ) (
    input  logic [NBITS-1:0] P [HADAMARD_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic [NBITS-1:0] sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23;
  logic [NBITS-1:0] sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23;

  CSA_5 #(.NBITS(NBITS)) csa_p0(P[0], P[1], P[2], P[3], P[4], sp0);
  CSA_2 #(.NBITS(NBITS)) csa_p1(P[1], P[3] <<< 1, sp1);
  CSA_4 #(.NBITS(NBITS)) csa_p2(P[1], P[2], P[3] <<< 2, P[4] <<< 2, sp2);
  CSA_3 #(.NBITS(NBITS)) csa_p3(P[1], P[3] <<< 3, P[5], sp3);
  CSA_5 #(.NBITS(NBITS)) csa_p4(P[6], P[7], P[8], P[9], P[10], sp4);
  CSA_2 #(.NBITS(NBITS)) csa_p5(P[7], P[9] <<< 1, sp5);
  CSA_4 #(.NBITS(NBITS)) csa_p6(P[7], P[8], P[9] <<< 2, P[10] <<< 2, sp6);
  CSA_3 #(.NBITS(NBITS)) csa_p7(P[7], P[9] <<< 3, P[11], sp7);
  CSA_5 #(.NBITS(NBITS)) csa_p8(P[12], P[13], P[14], P[15], P[16], sp8);
  CSA_2 #(.NBITS(NBITS)) csa_p9(P[13], P[15] <<< 1, sp9);
  CSA_4 #(.NBITS(NBITS)) csa_p10(P[13], P[14], P[15] <<< 2, P[16] <<< 2, sp10);
  CSA_3 #(.NBITS(NBITS)) csa_p11(P[13], P[15] <<< 3, P[17], sp11);
  CSA_5 #(.NBITS(NBITS)) csa_p12(P[18], P[19], P[20], P[21], P[22], sp12);
  CSA_2 #(.NBITS(NBITS)) csa_p13(P[19], P[21] <<< 1, sp13);
  CSA_4 #(.NBITS(NBITS)) csa_p14(P[19], P[20], P[21] <<< 2, P[22] <<< 2, sp14);
  CSA_3 #(.NBITS(NBITS)) csa_p15(P[19], P[21] <<< 3, P[23], sp15);
  CSA_5 #(.NBITS(NBITS)) csa_p16(P[24], P[25], P[26], P[27], P[28], sp16);
  CSA_2 #(.NBITS(NBITS)) csa_p17(P[25], P[27] <<< 1, sp17);
  CSA_4 #(.NBITS(NBITS)) csa_p18(P[25], P[26], P[27] <<< 2, P[28] <<< 2, sp18);
  CSA_3 #(.NBITS(NBITS)) csa_p19(P[25], P[27] <<< 3, P[29], sp19);
  CSA_5 #(.NBITS(NBITS)) csa_p20(P[30], P[31], P[32], P[33], P[34], sp20);
  CSA_2 #(.NBITS(NBITS)) csa_p21(P[31], P[33] <<< 1, sp21);
  CSA_4 #(.NBITS(NBITS)) csa_p22(P[31], P[32], P[33] <<< 2, P[34] <<< 2, sp22);
  CSA_3 #(.NBITS(NBITS)) csa_p23(P[31], P[33] <<< 3, P[35], sp23);
  CSA_2 #(.NBITS(NBITS)) csa_n1(P[2], P[4] <<< 1, sn1);
  CSA_2 #(.NBITS(NBITS)) csa_n3(P[2], P[4] <<< 3, sn3);
  CSA_2 #(.NBITS(NBITS)) csa_n5(P[8], P[10] <<< 1, sn5);
  CSA_2 #(.NBITS(NBITS)) csa_n7(P[8], P[10] <<< 3, sn7);
  CSA_2 #(.NBITS(NBITS)) csa_n9(P[14], P[16] <<< 1, sn9);
  CSA_2 #(.NBITS(NBITS)) csa_n11(P[14], P[16] <<< 3, sn11);
  CSA_2 #(.NBITS(NBITS)) csa_n13(P[20], P[22] <<< 1, sn13);
  CSA_2 #(.NBITS(NBITS)) csa_n15(P[20], P[22] <<< 3, sn15);
  CSA_2 #(.NBITS(NBITS)) csa_n17(P[26], P[28] <<< 1, sn17);
  CSA_2 #(.NBITS(NBITS)) csa_n19(P[26], P[28] <<< 3, sn19);
  CSA_2 #(.NBITS(NBITS)) csa_n21(P[32], P[34] <<< 1, sn21);
  CSA_2 #(.NBITS(NBITS)) csa_n23(P[32], P[34] <<< 3, sn23);
  assign soma[0] = sp0;
  assign soma[1] = sp1 - sn1;
  assign soma[2] = sp2;
  assign soma[3] = sp3 - sn3;
  assign soma[4] = sp4;
  assign soma[5] = sp5 - sn5;
  assign soma[6] = sp6;
  assign soma[7] = sp7 - sn7;
  assign soma[8] = sp8;
  assign soma[9] = sp9 - sn9;
  assign soma[10] = sp10;
  assign soma[11] = sp11 - sn11;
  assign soma[12] = sp12;
  assign soma[13] = sp13 - sn13;
  assign soma[14] = sp14;
  assign soma[15] = sp15 - sn15;
  assign soma[16] = sp16;
  assign soma[17] = sp17 - sn17;
  assign soma[18] = sp18;
  assign soma[19] = sp19 - sn19;
  assign soma[20] = sp20;
  assign soma[21] = sp21 - sn21;
  assign soma[22] = sp22;
  assign soma[23] = sp23 - sn23;
endmodule

module MatrixA0 #(
    parameter int NBITS = 20,
    parameter int CONV_OUTPUT_SIZE = 4,
    parameter int CONV_INPUT_SIZE = 6,
    parameter int CONV_KERNEL_SIZE = 4,
    parameter int HADAMARD_SIZE = 6
  ) (
    input  logic [NBITS-1:0] P [CONV_INPUT_SIZE*HADAMARD_SIZE-1:0],
    output logic [NBITS-1:0] soma [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0]
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic [NBITS-1:0] sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15;
  logic [NBITS-1:0] sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15;

  CSA_5 #(.NBITS(NBITS)) csa_p0(P[0], P[4], P[8], P[12], P[16], sp0);
  CSA_5 #(.NBITS(NBITS)) csa_p1(P[1], P[5], P[9], P[13], P[17], sp1);
  CSA_5 #(.NBITS(NBITS)) csa_p2(P[2], P[6], P[10], P[14], P[18], sp2);
  CSA_5 #(.NBITS(NBITS)) csa_p3(P[3], P[7], P[11], P[15], P[19], sp3);
  CSA_2 #(.NBITS(NBITS)) csa_p4(P[4], P[12] <<< 1, sp4);
  CSA_2 #(.NBITS(NBITS)) csa_p5(P[5], P[13] <<< 1, sp5);
  CSA_2 #(.NBITS(NBITS)) csa_p6(P[6], P[14] <<< 1, sp6);
  CSA_2 #(.NBITS(NBITS)) csa_p7(P[7], P[15] <<< 1, sp7);
  CSA_4 #(.NBITS(NBITS)) csa_p8(P[4], P[8], P[12] <<< 2, P[16] <<< 2, sp8);
  CSA_4 #(.NBITS(NBITS)) csa_p9(P[5], P[9], P[13] <<< 2, P[17] <<< 2, sp9);
  CSA_4 #(.NBITS(NBITS)) csa_p10(P[6], P[10], P[14] <<< 2, P[18] <<< 2, sp10);
  CSA_4 #(.NBITS(NBITS)) csa_p11(P[7], P[11], P[15] <<< 2, P[19] <<< 2, sp11);
  CSA_3 #(.NBITS(NBITS)) csa_p12(P[4], P[12] <<< 3, P[20], sp12);
  CSA_3 #(.NBITS(NBITS)) csa_p13(P[5], P[13] <<< 3, P[21], sp13);
  CSA_3 #(.NBITS(NBITS)) csa_p14(P[6], P[14] <<< 3, P[22], sp14);
  CSA_3 #(.NBITS(NBITS)) csa_p15(P[7], P[15] <<< 3, P[23], sp15);
  CSA_2 #(.NBITS(NBITS)) csa_n4(P[8], P[16] <<< 1, sn4);
  CSA_2 #(.NBITS(NBITS)) csa_n5(P[9], P[17] <<< 1, sn5);
  CSA_2 #(.NBITS(NBITS)) csa_n6(P[10], P[18] <<< 1, sn6);
  CSA_2 #(.NBITS(NBITS)) csa_n7(P[11], P[19] <<< 1, sn7);
  CSA_2 #(.NBITS(NBITS)) csa_n12(P[8], P[16] <<< 3, sn12);
  CSA_2 #(.NBITS(NBITS)) csa_n13(P[9], P[17] <<< 3, sn13);
  CSA_2 #(.NBITS(NBITS)) csa_n14(P[10], P[18] <<< 3, sn14);
  CSA_2 #(.NBITS(NBITS)) csa_n15(P[11], P[19] <<< 3, sn15);
  assign soma[0] = sp0;
  assign soma[1] = sp1;
  assign soma[2] = sp2;
  assign soma[3] = sp3;
  assign soma[4] = sp4 - sn4;
  assign soma[5] = sp5 - sn5;
  assign soma[6] = sp6 - sn6;
  assign soma[7] = sp7 - sn7;
  assign soma[8] = sp8;
  assign soma[9] = sp9;
  assign soma[10] = sp10;
  assign soma[11] = sp11;
  assign soma[12] = sp12 - sn12;
  assign soma[13] = sp13 - sn13;
  assign soma[14] = sp14 - sn14;
  assign soma[15] = sp15 - sn15;
endmodule
