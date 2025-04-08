module MatrixC0
   import packConv::*;
    (
      input  type_input P,
      output type_weight soma
    );
    timeunit 1ns;
    timeprecision 1ps;

    logic_vector sn1, sn5, sn9, sn13;

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
endmodule


module MatrixC1
   import packConv::*;
    (
      input  type_input P,
      output type_input soma
    );
    timeunit 1ns;
    timeprecision 1ps;

    logic_vector sn4, sn5, sn6, sn7;

    assign soma[0] =  - P[0] - P[8];
    assign soma[1] =  - P[1] - P[9];
    assign soma[2] =  - P[2] - P[10];
    assign soma[3] =  - P[3] - P[11];

    CSA_2 csa_p4 (P[4], P[8], sn4);
    assign soma[4] = sn4;
    CSA_2 csa_p5 (P[5], P[9], sn5);
    assign soma[5] = sn5;
    CSA_2 csa_p6 (P[6], P[10], sn6);
    assign soma[6] = sn6;
    CSA_2 csa_p7 (P[7], P[11], sn7);
    assign soma[7] = sn7;

    assign soma[8] =  - P[4] - P[8];
    assign soma[9] =  - P[5] - P[9];
    assign soma[10] =  - P[6] - P[10];
    assign soma[11] =  - P[7] - P[11];

    assign soma[12] =  - P[4] - P[12];
    assign soma[13] =  - P[5] - P[13];
    assign soma[14] =  - P[6] - P[14];
    assign soma[15] =  - P[7] - P[15];
endmodule


module MatrixA1
   import packConv::*;
    (
      input  type_input P,
      output type_matrix soma
    );
    timeunit 1ns;
    timeprecision 1ps;

    logic_vector sn0, sn2, sn4, sn6, sn1, sn3, sn5, sn7;

    CSA_3 csa_p0(P[0], P[1], P[2], sn0);
    assign soma[0] = sn0;
    CSA_3 csa_p2(P[4], P[5], P[6], sn2);
    assign soma[2] = sn2;
    CSA_3 csa_p4(P[8], P[9], P[10], sn4);
    assign soma[4] = sn4;
    CSA_3 csa_p6(P[12], P[13], P[14], sn6);
    assign soma[6] = sn6;

    CSA_2 csa_p1(P[1], P[3], sn1);
    assign soma[1] = sn1 - P[2];
    CSA_2 csa_p3(P[5], P[7], sn3);
    assign soma[3] = sn3 - P[6];
    CSA_2 csa_p5(P[9], P[11], sn5);
    assign soma[5] = sn5 - P[10];
    CSA_2 csa_p7(P[13], P[15], sn7);
    assign soma[7] = sn7 - P[14];
endmodule


module MatrixA0
   import packConv::*;
    (
      input  type_matrix P,
      output type_output soma
    );
    timeunit 1ns;
    timeprecision 1ps;

    logic_vector sn0, sn2, sn1, sn3;

    CSA_3 csa_p0(P[0], P[2], P[4], sn0);
    assign soma[0] = sn0;
    CSA_3 csa_p2(P[1], P[3], P[5], sn2);
    assign soma[1] = sn2;

    CSA_2 csa_p1(P[2], P[6], sn1);
    assign soma[2] = sn1 - P[4];
    CSA_2 csa_p3(P[3], P[7], sn3);
    assign soma[3] = sn3 - P[5];
endmodule
