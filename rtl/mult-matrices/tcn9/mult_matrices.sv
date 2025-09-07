module Transform
  import packConv::*;
 #(
  parameter int QUANT = 8,
  parameter int NBITS = 20
  )
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
  import packConv::*;
 #(
  parameter int QUANT = 8,
  parameter int NBITS = 20
  )
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
  import packConv::*;
  (
    input  type_input P,
    output type_matrix_c soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  logic_vector sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24;
  logic_vector sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24;

  CSA_2 csa_p0(P[0] <<< 1, P[3], sp0);
  assign sp1 = P[3];
  CSA_2 csa_p2(P[1] <<< 1, P[3], sp2);
  assign sp3 = P[3];
  CSA_2 csa_p4(P[1] <<< 1, P[4], sp4);
  CSA_2 csa_p5(P[5] <<< 1, P[8], sp5);
  assign sp6 = P[8];
  CSA_2 csa_p7(P[6] <<< 1, P[8], sp7);
  assign sp8 = P[8];
  CSA_2 csa_p9(P[6] <<< 1, P[9], sp9);
  CSA_2 csa_p10(P[10] <<< 1, P[13], sp10);
  assign sp11 = P[13];
  CSA_2 csa_p12(P[11] <<< 1, P[13], sp12);
  assign sp13 = P[13];
  CSA_2 csa_p14(P[11] <<< 1, P[14], sp14);
  CSA_2 csa_p15(P[15] <<< 1, P[18], sp15);
  assign sp16 = P[18];
  CSA_2 csa_p17(P[16] <<< 1, P[18], sp17);
  assign sp18 = P[18];
  CSA_2 csa_p19(P[16] <<< 1, P[19], sp19);
  CSA_2 csa_p20(P[20] <<< 1, P[23], sp20);
  assign sp21 = P[23];
  CSA_2 csa_p22(P[21] <<< 1, P[23], sp22);
  assign sp23 = P[23];
  CSA_2 csa_p24(P[21] <<< 1, P[24], sp24);
  CSA_2 csa_n0(P[1], P[2] <<< 1, sn0);
  CSA_2 csa_n1(P[1] <<< 1, P[2], sn1);
  CSA_2 csa_n2(P[2], P[2] <<< 1, sn2);
  assign sn3 = P[1];
  CSA_2 csa_n4(P[2], P[3] <<< 1, sn4);
  CSA_2 csa_n5(P[6], P[7] <<< 1, sn5);
  CSA_2 csa_n6(P[6] <<< 1, P[7], sn6);
  CSA_2 csa_n7(P[7], P[7] <<< 1, sn7);
  assign sn8 = P[6];
  CSA_2 csa_n9(P[7], P[8] <<< 1, sn9);
  CSA_2 csa_n10(P[11], P[12] <<< 1, sn10);
  CSA_2 csa_n11(P[11] <<< 1, P[12], sn11);
  CSA_2 csa_n12(P[12], P[12] <<< 1, sn12);
  assign sn13 = P[11];
  CSA_2 csa_n14(P[12], P[13] <<< 1, sn14);
  CSA_2 csa_n15(P[16], P[17] <<< 1, sn15);
  CSA_2 csa_n16(P[16] <<< 1, P[17], sn16);
  CSA_2 csa_n17(P[17], P[17] <<< 1, sn17);
  assign sn18 = P[16];
  CSA_2 csa_n19(P[17], P[18] <<< 1, sn19);
  CSA_2 csa_n20(P[21], P[22] <<< 1, sn20);
  CSA_2 csa_n21(P[21] <<< 1, P[22], sn21);
  CSA_2 csa_n22(P[22], P[22] <<< 1, sn22);
  assign sn23 = P[21];
  CSA_2 csa_n24(P[22], P[23] <<< 1, sn24);
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
endmodule


module MatrixC1
  import packConv::*;
  (
    input  type_matrix_c P,
    output type_weight soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  logic_vector sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24;
  logic_vector sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24;

  CSA_2 csa_p0(P[0] <<< 1, P[15], sp0);
  CSA_2 csa_p1(P[1] <<< 1, P[16], sp1);
  CSA_2 csa_p2(P[2] <<< 1, P[17], sp2);
  CSA_2 csa_p3(P[3] <<< 1, P[18], sp3);
  CSA_2 csa_p4(P[4] <<< 1, P[19], sp4);
  assign sp5 = P[15];
  assign sp6 = P[16];
  assign sp7 = P[17];
  assign sp8 = P[18];
  assign sp9 = P[19];
  CSA_2 csa_p10(P[5] <<< 1, P[15], sp10);
  CSA_2 csa_p11(P[6] <<< 1, P[16], sp11);
  CSA_2 csa_p12(P[7] <<< 1, P[17], sp12);
  CSA_2 csa_p13(P[8] <<< 1, P[18], sp13);
  CSA_2 csa_p14(P[9] <<< 1, P[19], sp14);
  assign sp15 = P[15];
  assign sp16 = P[16];
  assign sp17 = P[17];
  assign sp18 = P[18];
  assign sp19 = P[19];
  CSA_2 csa_p20(P[5] <<< 1, P[20], sp20);
  CSA_2 csa_p21(P[6] <<< 1, P[21], sp21);
  CSA_2 csa_p22(P[7] <<< 1, P[22], sp22);
  CSA_2 csa_p23(P[8] <<< 1, P[23], sp23);
  CSA_2 csa_p24(P[9] <<< 1, P[24], sp24);
  CSA_2 csa_n0(P[5], P[10] <<< 1, sn0);
  CSA_2 csa_n1(P[6], P[11] <<< 1, sn1);
  CSA_2 csa_n2(P[7], P[12] <<< 1, sn2);
  CSA_2 csa_n3(P[8], P[13] <<< 1, sn3);
  CSA_2 csa_n4(P[9], P[14] <<< 1, sn4);
  CSA_2 csa_n5(P[5] <<< 1, P[10], sn5);
  CSA_2 csa_n6(P[6] <<< 1, P[11], sn6);
  CSA_2 csa_n7(P[7] <<< 1, P[12], sn7);
  CSA_2 csa_n8(P[8] <<< 1, P[13], sn8);
  CSA_2 csa_n9(P[9] <<< 1, P[14], sn9);
  CSA_2 csa_n10(P[10], P[10] <<< 1, sn10);
  CSA_2 csa_n11(P[11], P[11] <<< 1, sn11);
  CSA_2 csa_n12(P[12], P[12] <<< 1, sn12);
  CSA_2 csa_n13(P[13], P[13] <<< 1, sn13);
  CSA_2 csa_n14(P[14], P[14] <<< 1, sn14);
  assign sn15 = P[5];
  assign sn16 = P[6];
  assign sn17 = P[7];
  assign sn18 = P[8];
  assign sn19 = P[9];
  CSA_2 csa_n20(P[10], P[15] <<< 1, sn20);
  CSA_2 csa_n21(P[11], P[16] <<< 1, sn21);
  CSA_2 csa_n22(P[12], P[17] <<< 1, sn22);
  CSA_2 csa_n23(P[13], P[18] <<< 1, sn23);
  CSA_2 csa_n24(P[14], P[19] <<< 1, sn24);
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
endmodule


module MatrixA1
  import packConv::*;
  (
    input  type_weight P,
    output type_matrix_a soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  logic_vector sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14;
  logic_vector sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14;

  CSA_4 csa_p0(P[0], P[1], P[2], P[3], sp0);
  CSA_2 csa_p1(P[1], P[3] <<< 1, sp1);
  CSA_4 csa_p2(P[1], P[2], P[3] <<< 2, P[4], sp2);
  CSA_4 csa_p3(P[5], P[6], P[7], P[8], sp3);
  CSA_2 csa_p4(P[6], P[8] <<< 1, sp4);
  CSA_4 csa_p5(P[6], P[7], P[8] <<< 2, P[9], sp5);
  CSA_4 csa_p6(P[10], P[11], P[12], P[13], sp6);
  CSA_2 csa_p7(P[11], P[13] <<< 1, sp7);
  CSA_4 csa_p8(P[11], P[12], P[13] <<< 2, P[14], sp8);
  CSA_4 csa_p9(P[15], P[16], P[17], P[18], sp9);
  CSA_2 csa_p10(P[16], P[18] <<< 1, sp10);
  CSA_4 csa_p11(P[16], P[17], P[18] <<< 2, P[19], sp11);
  CSA_4 csa_p12(P[20], P[21], P[22], P[23], sp12);
  CSA_2 csa_p13(P[21], P[23] <<< 1, sp13);
  CSA_4 csa_p14(P[21], P[22], P[23] <<< 2, P[24], sp14);
  assign sn1 = P[2];
  assign sn4 = P[7];
  assign sn7 = P[12];
  assign sn10 = P[17];
  assign sn13 = P[22];
  assign soma[0] = sp0;
  assign soma[1] = sp1 - sn1;
  assign soma[2] = sp2;
  assign soma[3] = sp3;
  assign soma[4] = sp4 - sn4;
  assign soma[5] = sp5;
  assign soma[6] = sp6;
  assign soma[7] = sp7 - sn7;
  assign soma[8] = sp8;
  assign soma[9] = sp9;
  assign soma[10] = sp10 - sn10;
  assign soma[11] = sp11;
  assign soma[12] = sp12;
  assign soma[13] = sp13 - sn13;
  assign soma[14] = sp14;
endmodule


module MatrixA0
  import packConv::*;
  (
    input  type_matrix_a P,
    output type_output soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  logic_vector sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8;
  logic_vector sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8;

  CSA_4 csa_p0(P[0], P[3], P[6], P[9], sp0);
  CSA_4 csa_p1(P[1], P[4], P[7], P[10], sp1);
  CSA_4 csa_p2(P[2], P[5], P[8], P[11], sp2);
  CSA_2 csa_p3(P[3], P[9] <<< 1, sp3);
  CSA_2 csa_p4(P[4], P[10] <<< 1, sp4);
  CSA_2 csa_p5(P[5], P[11] <<< 1, sp5);
  CSA_4 csa_p6(P[3], P[6], P[9] <<< 2, P[12], sp6);
  CSA_4 csa_p7(P[4], P[7], P[10] <<< 2, P[13], sp7);
  CSA_4 csa_p8(P[5], P[8], P[11] <<< 2, P[14], sp8);
  assign sn3 = P[6];
  assign sn4 = P[7];
  assign sn5 = P[8];
  assign soma[0] = sp0;
  assign soma[1] = sp1;
  assign soma[2] = sp2;
  assign soma[3] = sp3 - sn3;
  assign soma[4] = sp4 - sn4;
  assign soma[5] = sp5 - sn5;
  assign soma[6] = sp6;
  assign soma[7] = sp7;
  assign soma[8] = sp8;
endmodule