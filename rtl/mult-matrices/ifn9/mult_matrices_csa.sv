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
  logic_vector sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24, sp25, sp26, sp27, sp28, sp29;
  logic_vector sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24, sn25, sn26, sn27, sn28, sn29;

  assign sp0 = P[0];
  assign sp1 = P[2];
  assign sp2 = P[4];
  assign sp3 = P[1];
  assign sp4 = P[2];
  assign sp5 = P[3];
  assign sp6 = P[5];
  assign sp7 = P[7];
  assign sp8 = P[9];
  assign sp9 = P[6];
  assign sp10 = P[7];
  assign sp11 = P[8];
  assign sp12 = P[10];
  assign sp13 = P[12];
  assign sp14 = P[14];
  assign sp15 = P[11];
  assign sp16 = P[12];
  assign sp17 = P[13];
  assign sp18 = P[15];
  assign sp19 = P[17];
  assign sp20 = P[19];
  assign sp21 = P[16];
  assign sp22 = P[17];
  assign sp23 = P[18];
  assign sp24 = P[20];
  assign sp25 = P[22];
  assign sp26 = P[24];
  assign sp27 = P[21];
  assign sp28 = P[22];
  assign sp29 = P[23];
  CSA_2 csa_n0(P[1], P[2], sn0);
  CSA_2 csa_n1(P[1], P[3], sn1);
  CSA_2 csa_n2(P[2], P[3], sn2);
  CSA_2 csa_n6(P[6], P[7], sn6);
  CSA_2 csa_n7(P[6], P[8], sn7);
  CSA_2 csa_n8(P[7], P[8], sn8);
  CSA_2 csa_n12(P[11], P[12], sn12);
  CSA_2 csa_n13(P[11], P[13], sn13);
  CSA_2 csa_n14(P[12], P[13], sn14);
  CSA_2 csa_n18(P[16], P[17], sn18);
  CSA_2 csa_n19(P[16], P[18], sn19);
  CSA_2 csa_n20(P[17], P[18], sn20);
  CSA_2 csa_n24(P[21], P[22], sn24);
  CSA_2 csa_n25(P[21], P[23], sn25);
  CSA_2 csa_n26(P[22], P[23], sn26);
  assign soma[0] = sp0 - sn0;
  assign soma[1] = sp1 - sn1;
  assign soma[2] = sp2 - sn2;
  assign soma[3] = sp3;
  assign soma[4] = sp4;
  assign soma[5] = sp5;
  assign soma[6] = sp6 - sn6;
  assign soma[7] = sp7 - sn7;
  assign soma[8] = sp8 - sn8;
  assign soma[9] = sp9;
  assign soma[10] = sp10;
  assign soma[11] = sp11;
  assign soma[12] = sp12 - sn12;
  assign soma[13] = sp13 - sn13;
  assign soma[14] = sp14 - sn14;
  assign soma[15] = sp15;
  assign soma[16] = sp16;
  assign soma[17] = sp17;
  assign soma[18] = sp18 - sn18;
  assign soma[19] = sp19 - sn19;
  assign soma[20] = sp20 - sn20;
  assign soma[21] = sp21;
  assign soma[22] = sp22;
  assign soma[23] = sp23;
  assign soma[24] = sp24 - sn24;
  assign soma[25] = sp25 - sn25;
  assign soma[26] = sp26 - sn26;
  assign soma[27] = sp27;
  assign soma[28] = sp28;
  assign soma[29] = sp29;
endmodule


module MatrixC1
  import pack_typedef::*;
  (
    input  type_matrix_c P,
    output type_weight soma
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic_vector sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24, sp25, sp26, sp27, sp28, sp29, sp30, sp31, sp32, sp33, sp34, sp35;
  logic_vector sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24, sn25, sn26, sn27, sn28, sn29, sn30, sn31, sn32, sn33, sn34, sn35;

  assign sp0 = P[0];
  assign sp1 = P[1];
  assign sp2 = P[2];
  assign sp3 = P[3];
  assign sp4 = P[4];
  assign sp5 = P[5];
  assign sp6 = P[12];
  assign sp7 = P[13];
  assign sp8 = P[14];
  assign sp9 = P[15];
  assign sp10 = P[16];
  assign sp11 = P[17];
  assign sp12 = P[24];
  assign sp13 = P[25];
  assign sp14 = P[26];
  assign sp15 = P[27];
  assign sp16 = P[28];
  assign sp17 = P[29];
  assign sp18 = P[6];
  assign sp19 = P[7];
  assign sp20 = P[8];
  assign sp21 = P[9];
  assign sp22 = P[10];
  assign sp23 = P[11];
  assign sp24 = P[12];
  assign sp25 = P[13];
  assign sp26 = P[14];
  assign sp27 = P[15];
  assign sp28 = P[16];
  assign sp29 = P[17];
  assign sp30 = P[18];
  assign sp31 = P[19];
  assign sp32 = P[20];
  assign sp33 = P[21];
  assign sp34 = P[22];
  assign sp35 = P[23];
  CSA_2 csa_n0(P[6], P[12], sn0);
  CSA_2 csa_n1(P[7], P[13], sn1);
  CSA_2 csa_n2(P[8], P[14], sn2);
  CSA_2 csa_n3(P[9], P[15], sn3);
  CSA_2 csa_n4(P[10], P[16], sn4);
  CSA_2 csa_n5(P[11], P[17], sn5);
  CSA_2 csa_n6(P[6], P[18], sn6);
  CSA_2 csa_n7(P[7], P[19], sn7);
  CSA_2 csa_n8(P[8], P[20], sn8);
  CSA_2 csa_n9(P[9], P[21], sn9);
  CSA_2 csa_n10(P[10], P[22], sn10);
  CSA_2 csa_n11(P[11], P[23], sn11);
  CSA_2 csa_n12(P[12], P[18], sn12);
  CSA_2 csa_n13(P[13], P[19], sn13);
  CSA_2 csa_n14(P[14], P[20], sn14);
  CSA_2 csa_n15(P[15], P[21], sn15);
  CSA_2 csa_n16(P[16], P[22], sn16);
  CSA_2 csa_n17(P[17], P[23], sn17);
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
endmodule


module MatrixA1
  import pack_typedef::*;
  (
    input  type_weight P,
    output type_matrix_a soma
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic_vector sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17;
  logic_vector sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17;

  CSA_3 csa_p0(P[0], P[3], P[4], sp0);
  CSA_3 csa_p1(P[1], P[3], P[5], sp1);
  CSA_3 csa_p2(P[2], P[4], P[5], sp2);
  CSA_3 csa_p3(P[6], P[9], P[10], sp3);
  CSA_3 csa_p4(P[7], P[9], P[11], sp4);
  CSA_3 csa_p5(P[8], P[10], P[11], sp5);
  CSA_3 csa_p6(P[12], P[15], P[16], sp6);
  CSA_3 csa_p7(P[13], P[15], P[17], sp7);
  CSA_3 csa_p8(P[14], P[16], P[17], sp8);
  CSA_3 csa_p9(P[18], P[21], P[22], sp9);
  CSA_3 csa_p10(P[19], P[21], P[23], sp10);
  CSA_3 csa_p11(P[20], P[22], P[23], sp11);
  CSA_3 csa_p12(P[24], P[27], P[28], sp12);
  CSA_3 csa_p13(P[25], P[27], P[29], sp13);
  CSA_3 csa_p14(P[26], P[28], P[29], sp14);
  CSA_3 csa_p15(P[30], P[33], P[34], sp15);
  CSA_3 csa_p16(P[31], P[33], P[35], sp16);
  CSA_3 csa_p17(P[32], P[34], P[35], sp17);
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
endmodule


module MatrixA0
  import pack_typedef::*;
  (
    input  type_matrix_a P,
    output type_output soma
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic_vector sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8;
  logic_vector sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8;

  CSA_3 csa_p0(P[0], P[9], P[12], sp0);
  CSA_3 csa_p1(P[1], P[10], P[13], sp1);
  CSA_3 csa_p2(P[2], P[11], P[14], sp2);
  CSA_3 csa_p3(P[3], P[9], P[15], sp3);
  CSA_3 csa_p4(P[4], P[10], P[16], sp4);
  CSA_3 csa_p5(P[5], P[11], P[17], sp5);
  CSA_3 csa_p6(P[6], P[12], P[15], sp6);
  CSA_3 csa_p7(P[7], P[13], P[16], sp7);
  CSA_3 csa_p8(P[8], P[14], P[17], sp8);
  assign soma[0] = sp0;
  assign soma[1] = sp1;
  assign soma[2] = sp2;
  assign soma[3] = sp3;
  assign soma[4] = sp4;
  assign soma[5] = sp5;
  assign soma[6] = sp6;
  assign soma[7] = sp7;
  assign soma[8] = sp8;
endmodule
