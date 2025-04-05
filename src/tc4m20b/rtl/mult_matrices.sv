module MatrixC0
   import packConv::*;
    (
      input  logic_vector16 P,
      output logic_vector16 soma
    );
    timeunit 1ns;
    timeprecision 1ps;

    logic_vector sp1, sp5, sp9, sp13;

    assign soma[0] =  - P[0] + P[2];
    CSA_2 csa_p1 (P[1], P[2],  sp1);
    assign soma[1] = sp1;
    assign soma[2] =  - P[1] + P[2];
    assign soma[3] =  - P[1] + P[3];

    assign soma[4] =  - P[4] + P[6];
    CSA_2 csa_p5 (P[5], P[6], sp5);
    assign soma[5] = sp5;
    assign soma[6] =  - P[5] + P[6];
    assign soma[7] =  - P[5] + P[7];

    assign soma[8] =  + P[10] - P[8];
    CSA_2 csa_p9 (P[10], P[9], sp9);
    assign soma[9] =  sp9;
    assign soma[10] =  P[10] - P[9];
    assign soma[11] =  P[11] - P[9];

    assign soma[12] =  - P[12] + P[14];
    CSA_2 csa_p13(P[13], P[14], sp13);
    assign soma[13] =  sp13;
    assign soma[14] =  P[10] - P[9];
    assign soma[15] =  P[11] - P[9];
endmodule


module MatrixC1
   import packConv::*;
    (
      input  logic_vector16 P,
      output logic_vector16 soma
    );
    timeunit 1ns;
    timeprecision 1ps;

    logic_vector sp4, sp5, sp6, sp7;

    assign soma[0] =  - P[0] + P[8];
    assign soma[1] =  - P[1] + P[9];
    assign soma[2] =  - P[2] + P[10];
    assign soma[3] =  - P[3] + P[11];

    CSA_2 csa_p4 (P[4], P[8], sp4);
    assign soma[4] = sp4;
    CSA_2 csa_p5 (P[5], P[9], sp5);
    assign soma[5] = sp5;
    CSA_2 csa_p6 (P[6], P[10], sp6);
    assign soma[6] = sp6;
    CSA_2 csa_p7 (P[7], P[11], sp7);
    assign soma[7] = sp7;

    assign soma[8] =  - P[4] + P[8];
    assign soma[9] =  - P[5] + P[9];
    assign soma[10] =  - P[6] + P[10];
    assign soma[11] =  - P[7] + P[11];

    assign soma[12] =  - P[4] + P[12];
    assign soma[13] =  - P[5] + P[13];
    assign soma[14] =  - P[6] + P[14];
    assign soma[15] =  - P[7] + P[15];
endmodule


module MatrixA1
   import packConv::*;
    (
      input  logic_vector16 P,
      output logic_vector8 soma
    );
    timeunit 1ns;
    timeprecision 1ps;

    logic_vector sp0, sp2, sp4, sp6, sp1, sp3, sp5, sp7;

    CSA_3 csa_p0(P[0], P[1], P[2], sp0);
    assign soma[0] = sp0;
    CSA_3 csa_p2(P[4], P[5], P[6], sp2);
    assign soma[2] = sp2;
    CSA_3 csa_p4(P[8], P[9], P[10], sp4);
    assign soma[4] = sp4;
    CSA_3 csa_p6(P[12], P[13], P[14], sp6);
    assign soma[6] = sp6;

    CSA_2 csa_p1(P[1], P[3], sp1);
    assign soma[1] = sp1 - P[2];
    CSA_2 csa_p3(P[5], P[7], sp3);
    assign soma[3] = sp3 - P[6];
    CSA_2 csa_p5(P[9], P[11], sp5);
    assign soma[5] = sp5 - P[10];
    CSA_2 csa_p7(P[13], P[15], sp7);
    assign soma[7] = sp7 - P[14];
endmodule


module MatrixA0
   import packConv::*;
    (
      input  logic_vector8 P,
      output logic_vector4 soma
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
