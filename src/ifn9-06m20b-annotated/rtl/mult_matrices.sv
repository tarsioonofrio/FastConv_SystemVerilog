module MatrixC0
  import packConv::*;
  (
    input  type_input P,
    output type_input soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  logic_vector sn0, sn1, sn2;
  logic_vector sn6, sn7, sn8;
  logic_vector sn12, sn13, sn14;
  logic_vector sn18, sn19, sn20;
  logic_vector sn24, sn25, sn26;

  CSA_2 csa_n0 (P[1], P[2],  sn0);
  assign soma[0] =  P[0] - sn0;
  CSA_2 csa_n6 (P[6], P[7],  sn6);
  assign soma[6] =  P[5] - sn6;
  CSA_2 csa_n12 (P[11], P[12],  sn12);
  assign soma[12] =  P[10] - sn12;
  CSA_2 csa_n18 (P[16], P[17],  sn18);
  assign soma[18] =  P[15] - sn18;
  CSA_2 csa_n24 (P[21], P[22],  sn24);
  assign soma[24] =  P[20] - sn24;

  CSA_2 csa_n1 (P[1], P[3],  sn1);
  assign soma[1] =  P[2] - sn1;
  CSA_2 csa_n7 (P[6], P[8],  sn7);
  assign soma[7] =  P[7] - sn7;
  CSA_2 csa_n13 (P[11], P[13],  sn13);
  assign soma[13] =  P[12] - sn13;
  CSA_2 csa_n19 (P[16], P[18],  sn19);
  assign soma[19] =  P[17] - sn19;
  CSA_2 csa_n25 (P[21], P[23],  sn25);
  assign soma[25] =  P[22] - sn25;

  CSA_2 csa_n2 (P[1], P[3],  sn2);
  assign soma[2] =  P[2] - sn2;
  CSA_2 csa_n8 (P[6], P[8],  sn8);
  assign soma[8] =  P[7] - sn8;
  CSA_2 csa_n14 (P[11], P[13],  sn14);
  assign soma[14] =  P[12] - sn14;
  CSA_2 csa_n20 (P[16], P[18],  sn20);
  assign soma[20] =  P[17] - sn20;
  CSA_2 csa_n26 (P[21], P[23],  sn26);
  assign soma[26] =  P[22] - sn26;

  assign soma[3] = P[1];
  assign soma[4] = P[2];
  assign soma[5] = P[3];

  assign soma[9] =  P[6];
  assign soma[10] = P[7];
  assign soma[11] = P[8];

  assign soma[9] =  P[6];
  assign soma[10] = P[7];
  assign soma[11] = P[8];

  assign soma[15] = P[11];
  assign soma[16] = P[12];
  assign soma[17] = P[13];

  assign soma[21] = P[16];
  assign soma[22] = P[17];
  assign soma[23] = P[18];

  assign soma[21] = P[16];
  assign soma[22] = P[17];
  assign soma[23] = P[18];

  assign soma[27] = P[21];
  assign soma[28] = P[22];
  assign soma[29] = P[23];

endmodule


module MatrixC1
  import packConv::*;
  (
    input  type_input P,
    output type_weight soma
  );
  timeunit 1ns;
  timeprecision 1ps;

  logic_vector sn0, sn1, sn2, sn3, sn4, sn5;
  logic_vector sn6, sn7, sn8, sn9, sn10, sn11;
  logic_vector sn12, sn13, sn14, sn15, sn16, sn17;

  CSA_2 csa_n0 (P[06], P[12], sn0);
  CSA_2 csa_n1 (P[07], P[13], sn1);
  CSA_2 csa_n2 (P[08], P[14], sn2);
  CSA_2 csa_n3 (P[09], P[15], sn3);
  CSA_2 csa_n4 (P[10], P[16], sn4);
  CSA_2 csa_n5 (P[11], P[17], sn5);
  assign soma[0] =  P[0] - sn0;
  assign soma[1] =  P[1] - sn1;
  assign soma[2] =  P[2] - sn2;
  assign soma[3] =  P[3] - sn3;
  assign soma[4] =  P[4] - sn4;
  assign soma[5] =  P[5] - sn5;

  CSA_2 csa_n6 (P[6], P[18], sn6);
  CSA_2 csa_n7 (P[7], P[19], sn7);
  CSA_2 csa_n8 (P[8], P[20], sn8);
  CSA_2 csa_n9 (P[9], P[21], sn9);
  CSA_2 csa_n10 (P[10], P[22], sn10);
  CSA_2 csa_n11 (P[11], P[23], sn11);
  assign soma[06] =  P[12] - sn6;
  assign soma[07] =  P[13] - sn7;
  assign soma[08] =  P[14] - sn8;
  assign soma[09] =  P[15] - sn9;
  assign soma[10] =  P[16] - sn10;
  assign soma[11] =  P[17] - sn11;

  CSA_2 csa_n12 (P[12], P[18], sn12);
  CSA_2 csa_n13 (P[13], P[19], sn13);
  CSA_2 csa_n14 (P[14], P[20], sn14);
  CSA_2 csa_n15 (P[15], P[21], sn15);
  CSA_2 csa_n16 (P[16], P[22], sn16);
  CSA_2 csa_n17 (P[17], P[23], sn17);
  assign soma[06] =  P[24] - sn6;
  assign soma[07] =  P[25] - sn7;
  assign soma[08] =  P[26] - sn8;
  assign soma[09] =  P[27] - sn9;
  assign soma[10] =  P[28] - sn10;
  assign soma[11] =  P[29] - sn11;

  assign soma[18] = P[6];
  assign soma[19] = P[7];
  assign soma[20] = P[8];
  assign soma[21] = P[9];
  assign soma[22] = P[10];
  assign soma[23] = P[11];

  assign soma[24] = P[12];
  assign soma[25] = P[13];
  assign soma[26] = P[14];
  assign soma[27] = P[15];
  assign soma[28] = P[16];
  assign soma[29] = P[17];

  assign soma[30] = P[18];
  assign soma[31] = P[19];
  assign soma[32] = P[20];
  assign soma[33] = P[21];
  assign soma[35] = P[23];
  assign soma[34] = P[22];

endmodule


module MatrixA1
   import packConv::*;
    (
      input  type_weight P,
      output type_matrix soma
    );
    timeunit 1ns;
    timeprecision 1ps;

    logic_vector sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8;
    logic_vector sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17;

    CSA_3 csa_p0 (P[0], P[3], P[4], sp0);
    CSA_3 csa_p1 (P[1], P[3], P[5], sp1);
    CSA_3 csa_p2 (P[2], P[4], P[5], sp2);
    CSA_3 csa_p3 (P[6], P[09], P[10], sp3);
    CSA_3 csa_p4 (P[7], P[09], P[11], sp4);
    CSA_3 csa_p5 (P[8], P[10], P[11], sp5);
    CSA_3 csa_p6 (P[12], P[15], P[16], sp6);
    CSA_3 csa_p7 (P[13], P[15], P[17], sp7);
    CSA_3 csa_p8 (P[14], P[16], P[17], sp8);

    CSA_3 csa_p6 (P[12], P[15], P[16], sp6);
    CSA_3 csa_p7 (P[13], P[15], P[17], sp7);
    CSA_3 csa_p8 (P[14], P[16], P[17], sp8);

Z    
    
endmodule


module MatrixA0
   import packConv::*;
    (
      input  type_matrix P,
      output type_output soma
    );
    timeunit 1ns;
    timeprecision 1ps;

    logic_vector sp0, sp2, sp1, sp3;

    CSA_3 csa_p0(P[0], P[2], P[4], sp0);
    assign soma[0] = sp0;
    CSA_3 csa_p2(P[1], P[3], P[5], sp2);
    assign soma[1] = sp2;

    CSA_2 csa_p1(P[2], P[6], sp1);
    assign soma[2] = sp1 - P[4];
    CSA_2 csa_p3(P[3], P[7], sp3);
    assign soma[3] = sp3 - P[5];
endmodule
