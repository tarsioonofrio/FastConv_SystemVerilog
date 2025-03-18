module MatrixDelta
   import packMatrix::*;
    (
      input  param P,
      output param soma
    );

      param tc, tc;
      // reg32 soma;

      always_comb begin

        // CSA_3 sc0 (P[0], P[1], P[2],  tc[0]);
        assign soma[0] =  - P[0] + P[2];
        CSA_2 sc1 (P[1], P[2],  tc[1]);
        assign soma[1] = tc[1];
        assign soma[2] =  - P[1] + P[2];
        assign soma[3] =  - P[1] + P[3];

        assign soma[4] =  - P[4] + P[6];
        CSA_2 sc5 (P[5], P[6], tc[5]);
        assign soma[5] = tc[5];
        assign soma[6] =  - P[5] + P[6];
        assign soma[7] =  - P[5] + P[7];

        assign soma[8] =  + P[10] - P[8];
        CSA_2 sc5 (P[10], P[9], tc[9]);
        assign soma[9] =  tc[9];
        assign soma[10] =  P[10] - P[9];
        assign soma[11] =  P[11] - P[9];

        assign soma[12] =  - P[12] - P[14];
        CSA_2 sc5 (P[13], P[14], tc[13]);
        assign soma[13] =  tc[13];
        assign soma[14] =  P[10] - P[9];
        assign soma[15] =  P[11] - P[9];
    end
endmodule


module MatrixD
   import packMatrix::*;
    (
      input  param P,
      output param soma
    );

      param tc, tc;
      // reg32 soma;

      always_comb begin

        assign soma[0] =  - P[0] + P[8];
        assign soma[1] =  - P[1] + P[9];
        assign soma[2] =  - P[2] + P[10];
        assign soma[3] =  - P[3] + P[11];

        CSA_2 sc5 (P[4], P[8], tc[4]);
        assign soma[4] = tc[4];
        CSA_2 sc5 (P[5], P[9], tc[5]);
        assign soma[5] = tc[5];
        CSA_2 sc5 (P[6], P[10], tc[6]);
        assign soma[6] = tc[6];
        CSA_2 sc5 (P[7], P[11], tc[7]);
        assign soma[7] = tc[7];

        assign soma[8] =  - P[4] + P[8];
        assign soma[9] =  - P[5] + P[9];
        assign soma[10] =  - P[6] + P[10];
        assign soma[11] =  - P[7] + P[11];

        assign soma[12] =  - P[4] + P[12];
        assign soma[13] =  - P[5] + P[13];
        assign soma[14] =  - P[6] + P[14];
        assign soma[15] =  - P[7] + P[15];
    end
endmodule


module MatrixSigma
   import packMatrix::*;
    (
      input  param P,
      output param soma
    );

      param tc, tc;
      // reg32 soma;

      always_comb begin

        CSA_3 sc0(P[0], P[1], P[2], tc[0]);
        assign soma[0] = tc[0];
        CSA_3 sc2(P[4], P[5], P[6], tc[2]);
        assign soma[2] = tc[2];
        CSA_3 sc4(P[8], P[9], P[10], tc[4]);
        assign soma[4] = tc[4];
        CSA_3 sc6(P[12], P[13], P[14], tc[6]);
        assign soma[6] = tc[6];

        CSA_2 sc1(P[1], P[3], tc[1]);
        assign soma[1] = tc[1] - P[2];
        CSA_2 sc3(P[5], P[7], tc[3]);
        assign soma[3] = tc[3] - P[6];
        CSA_2 sc5(P[9], P[11], tc[5]);
        assign soma[5] = tc[5] - P[10];
        CSA_2 sc7(P[13], P[15], tc[7]);
        assign soma[5] = tc[7] - P[14];
    end
endmodule


module MatrixS
   import packMatrix::*;
    (
      input  param P,
      output param soma
    );

      param tc, tc;
      // reg32 soma;

      always_comb begin

        CSA_3 sc0(P[0], P[2], P[4], tc[0]);
        assign soma[0] = tc[0];
        CSA_3 sc2(P[1], P[3], P[5], tc[2]);
        assign soma[2] = tc[2];

        CSA_2 sc1(P[2], P[6], tc[1]);
        assign soma[1] = tc[1] - P[4];
        CSA_2 sc3(P[3], P[7], tc[3]);
        assign soma[3] = tc[3] - P[5];
    end
endmodule


