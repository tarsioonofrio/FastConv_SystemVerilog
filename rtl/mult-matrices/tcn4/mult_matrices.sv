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

  logic_vector sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15;
  logic_vector sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15;

  assign sp0 = P[2];
  CSA_2 csa_p1(P[1], P[2], sp1);
  assign sp2 = P[2];
  assign sp3 = P[3];
  assign sp4 = P[6];
  CSA_2 csa_p5(P[5], P[6], sp5);
  assign sp6 = P[6];
  assign sp7 = P[7];
  assign sp8 = P[10];
  CSA_2 csa_p9(P[9], P[10], sp9);
  assign sp10 = P[10];
  assign sp11 = P[11];
  assign sp12 = P[14];
  CSA_2 csa_p13(P[13], P[14], sp13);
  assign sp14 = P[14];
  assign sp15 = P[15];
  assign sn0 = P[0];
  assign sn2 = P[1];
  assign sn3 = P[1];
  assign sn4 = P[4];
  assign sn6 = P[5];
  assign sn7 = P[5];
  assign sn8 = P[8];
  assign sn10 = P[9];
  assign sn11 = P[9];
  assign sn12 = P[12];
  assign sn14 = P[13];
  assign sn15 = P[13];
  assign soma[0] = sp0 - sn0;
  assign soma[1] = sp1;
  assign soma[2] = sp2 - sn2;
  assign soma[3] = sp3 - sn3;
  assign soma[4] = sp4 - sn4;
  assign soma[5] = sp5;
  assign soma[6] = sp6 - sn6;
  assign soma[7] = sp7 - sn7;
  assign soma[8] = sp8 - sn8;
  assign soma[9] = sp9;
  assign soma[10] = sp10 - sn10;
  assign soma[11] = sp11 - sn11;
  assign soma[12] = sp12 - sn12;
  assign soma[13] = sp13;
  assign soma[14] = sp14 - sn14;
  assign soma[15] = sp15 - sn15;
endmodule


module MatrixC1
  import packConv::*;
  (
    input  type_matrix_c P,
    output type_weight soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  logic_vector sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15;
  logic_vector sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15;

  assign sp0 = P[8];
  assign sp1 = P[9];
  assign sp2 = P[10];
  assign sp3 = P[11];
  CSA_2 csa_p4(P[4], P[8], sp4);
  CSA_2 csa_p5(P[5], P[9], sp5);
  CSA_2 csa_p6(P[6], P[10], sp6);
  CSA_2 csa_p7(P[7], P[11], sp7);
  assign sp8 = P[8];
  assign sp9 = P[9];
  assign sp10 = P[10];
  assign sp11 = P[11];
  assign sp12 = P[12];
  assign sp13 = P[13];
  assign sp14 = P[14];
  assign sp15 = P[15];
  assign sn0 = P[0];
  assign sn1 = P[1];
  assign sn2 = P[2];
  assign sn3 = P[3];
  assign sn8 = P[4];
  assign sn9 = P[5];
  assign sn10 = P[6];
  assign sn11 = P[7];
  assign sn12 = P[4];
  assign sn13 = P[5];
  assign sn14 = P[6];
  assign sn15 = P[7];
  assign soma[0] = sp0 - sn0;
  assign soma[1] = sp1 - sn1;
  assign soma[2] = sp2 - sn2;
  assign soma[3] = sp3 - sn3;
  assign soma[4] = sp4;
  assign soma[5] = sp5;
  assign soma[6] = sp6;
  assign soma[7] = sp7;
  assign soma[8] = sp8 - sn8;
  assign soma[9] = sp9 - sn9;
  assign soma[10] = sp10 - sn10;
  assign soma[11] = sp11 - sn11;
  assign soma[12] = sp12 - sn12;
  assign soma[13] = sp13 - sn13;
  assign soma[14] = sp14 - sn14;
  assign soma[15] = sp15 - sn15;
endmodule


module MatrixA1
  import packConv::*;
  (
    input  type_weight P,
    output type_matrix_a soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  logic_vector sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7;
  logic_vector sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7;

  CSA_3 csa_p0(P[0], P[1], P[2], sp0);
  CSA_2 csa_p1(P[1], P[3], sp1);
  CSA_3 csa_p2(P[4], P[5], P[6], sp2);
  CSA_2 csa_p3(P[5], P[7], sp3);
  CSA_3 csa_p4(P[8], P[9], P[10], sp4);
  CSA_2 csa_p5(P[9], P[11], sp5);
  CSA_3 csa_p6(P[12], P[13], P[14], sp6);
  CSA_2 csa_p7(P[13], P[15], sp7);
  assign sn1 = P[2];
  assign sn3 = P[6];
  assign sn5 = P[10];
  assign sn7 = P[14];
  assign soma[0] = sp0;
  assign soma[1] = sp1 - sn1;
  assign soma[2] = sp2;
  assign soma[3] = sp3 - sn3;
  assign soma[4] = sp4;
  assign soma[5] = sp5 - sn5;
  assign soma[6] = sp6;
  assign soma[7] = sp7 - sn7;
endmodule


module MatrixA0
  import packConv::*;
  (
    input  type_matrix_a P,
    output type_output soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  logic_vector sp0, sp1, sp2, sp3;
  logic_vector sn0, sn1, sn2, sn3;

  CSA_3 csa_p0(P[0], P[2], P[4], sp0);
  CSA_3 csa_p1(P[1], P[3], P[5], sp1);
  CSA_2 csa_p2(P[2], P[6], sp2);
  CSA_2 csa_p3(P[3], P[7], sp3);
  assign sn2 = P[4];
  assign sn3 = P[5];
  assign soma[0] = sp0;
  assign soma[1] = sp1;
  assign soma[2] = sp2 - sn2;
  assign soma[3] = sp3 - sn3;
endmodule