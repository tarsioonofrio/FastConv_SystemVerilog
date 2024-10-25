//-------------------------------------------------------------------------
// FERNANDO MORAES                                          24/October/2024
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------
// X (rows): 9     Y (coluns): 36     max shift: 0 
//-------------------------------------------------------------------------
module MatrixA
   import packConv::*;
    (
      input  param36 P,
      output param9 soma
    );

  timeunit 1ns;
  timeprecision 1ps;

      
        CSA_9 sp0 (P[0], P[3], P[4], P[18], P[21], P[22], P[24], P[27], P[28],  soma[0]);

        CSA_9 sp1 (P[1], P[3], P[5], P[19], P[21], P[23], P[25], P[27], P[29],  soma[1]);

        CSA_9 sp2 (P[2], P[4], P[5], P[20], P[22], P[23], P[26], P[28], P[29],  soma[2]);

        CSA_9 sp3 (P[6], P[9], P[10], P[18], P[21], P[22], P[30], P[33], P[34],  soma[3]);

        CSA_9 sp4 (P[7], P[9], P[11], P[19], P[21], P[23], P[31], P[33], P[35],  soma[4]);

        CSA_9 sp5 (P[8], P[10], P[11], P[20], P[22], P[23], P[32], P[34], P[35],  soma[5]);

        CSA_9 sp6 (P[12], P[15], P[16], P[24], P[27], P[28], P[30], P[33], P[34],  soma[6]);

        CSA_9 sp7 (P[13], P[15], P[17], P[25], P[27], P[29], P[31], P[33], P[35],  soma[7]);

        CSA_9 sp8 (P[14], P[16], P[17], P[26], P[28], P[29], P[32], P[34], P[35],  soma[8]);

endmodule

//-------------------------------------------------------------------------
// X (rows): 36     Y (coluns): 25     max shift: 0 
//-------------------------------------------------------------------------
module MatrixC
   import packConv::*;
    (
      input  param36 P,
      output param36 soma
    );

  timeunit 1ns;
  timeprecision 1ps;
  

      param36 cp, cn;


        CSA_5 sp0 (P[0], P[6], P[7], P[11], P[12],  cp[0]);
        CSA_4 sn0 (P[1], P[2], P[5], P[10], cn[0] );
        assign soma[0] =  cp[0] - cn[0];

        CSA_5 sp1 (P[2], P[6], P[8], P[11], P[13],  cp[1]);
        CSA_4 sn1 (P[1], P[3], P[7], P[12], cn[1] );
        assign soma[1] =  cp[1] - cn[1];

        CSA_5 sp2 (P[4], P[7], P[8], P[12], P[13],  cp[2]);
        CSA_4 sn2 (P[2], P[3], P[9], P[14], cn[2] );
        assign soma[2] =  cp[2] - cn[2];

        CSA_1 sp3 (P[1],  cp[3]);
        CSA_2 sn3 (P[6], P[11], cn[3] );
        assign soma[3] =  cp[3] - cn[3];

        CSA_1 sp4 (P[2],  cp[4]);
        CSA_2 sn4 (P[7], P[12], cn[4] );
        assign soma[4] =  cp[4] - cn[4];

        CSA_1 sp5 (P[3],  cp[5]);
        CSA_2 sn5 (P[8], P[13], cn[5] );
        assign soma[5] =  cp[5] - cn[5];

        CSA_5 sp6 (P[6], P[7], P[10], P[16], P[17],  cp[6]);
        CSA_4 sn6 (P[5], P[11], P[12], P[15], cn[6] );
        assign soma[6] =  cp[6] - cn[6];

        CSA_5 sp7 (P[6], P[8], P[12], P[16], P[18],  cp[7]);
        CSA_4 sn7 (P[7], P[11], P[13], P[17], cn[7] );
        assign soma[7] =  cp[7] - cn[7];

        CSA_5 sp8 (P[7], P[8], P[14], P[17], P[18],  cp[8]);
        CSA_4 sn8 (P[9], P[12], P[13], P[19], cn[8] );
        assign soma[8] =  cp[8] - cn[8];

        CSA_1 sp9 (P[11],  cp[9]);
        CSA_2 sn9 (P[6], P[16], cn[9] );
        assign soma[9] =  cp[9] - cn[9];

        CSA_1 sp10 (P[12],  cp[10]);
        CSA_2 sn10 (P[7], P[17], cn[10] );
        assign soma[10] =  cp[10] - cn[10];

        CSA_1 sp11 (P[13],  cp[11]);
        CSA_2 sn11 (P[8], P[18], cn[11] );
        assign soma[11] =  cp[11] - cn[11];

        CSA_5 sp12 (P[11], P[12], P[16], P[17], P[20],  cp[12]);
        CSA_4 sn12 (P[10], P[15], P[21], P[22], cn[12] );
        assign soma[12] =  cp[12] - cn[12];

        CSA_5 sp13 (P[11], P[13], P[16], P[18], P[22],  cp[13]);
        CSA_4 sn13 (P[12], P[17], P[21], P[23], cn[13] );
        assign soma[13] =  cp[13] - cn[13];

        CSA_5 sp14 (P[12], P[13], P[17], P[18], P[24],  cp[14]);
        CSA_4 sn14 (P[14], P[19], P[22], P[23], cn[14] );
        assign soma[14] =  cp[14] - cn[14];

        CSA_1 sp15 (P[21],  cp[15]);
        CSA_2 sn15 (P[11], P[16], cn[15] );
        assign soma[15] =  cp[15] - cn[15];

        CSA_1 sp16 (P[22],  cp[16]);
        CSA_2 sn16 (P[12], P[17], cn[16] );
        assign soma[16] =  cp[16] - cn[16];

        CSA_1 sp17 (P[23],  cp[17]);
        CSA_2 sn17 (P[13], P[18], cn[17] );
        assign soma[17] =  cp[17] - cn[17];

        CSA_1 sp18 (P[5],  cp[18]);
        CSA_2 sn18 (P[6], P[7], cn[18] );
        assign soma[18] =  cp[18] - cn[18];

        CSA_1 sp19 (P[7],  cp[19]);
        CSA_2 sn19 (P[6], P[8], cn[19] );
        assign soma[19] =  cp[19] - cn[19];

        CSA_1 sp20 (P[9],  cp[20]);
        CSA_2 sn20 (P[7], P[8], cn[20] );
        assign soma[20] =  cp[20] - cn[20];

        CSA_1 sp21 (P[6],  cp[21]);
        assign soma[21] =  cp[21];

        CSA_1 sp22 (P[7],  cp[22]);
        assign soma[22] =  cp[22];

        CSA_1 sp23 (P[8],  cp[23]);
        assign soma[23] =  cp[23];

        CSA_1 sp24 (P[10],  cp[24]);
        CSA_2 sn24 (P[11], P[12], cn[24] );
        assign soma[24] =  cp[24] - cn[24];

        CSA_1 sp25 (P[12],  cp[25]);
        CSA_2 sn25 (P[11], P[13], cn[25] );
        assign soma[25] =  cp[25] - cn[25];

        CSA_1 sp26 (P[14],  cp[26]);
        CSA_2 sn26 (P[12], P[13], cn[26] );
        assign soma[26] =  cp[26] - cn[26];

        CSA_1 sp27 (P[11],  cp[27]);
        assign soma[27] =  cp[27];

        CSA_1 sp28 (P[12],  cp[28]);
        assign soma[28] =  cp[28];

        CSA_1 sp29 (P[13],  cp[29]);
        assign soma[29] =  cp[29];

        CSA_1 sp30 (P[15],  cp[30]);
        CSA_2 sn30 (P[16], P[17], cn[30] );
        assign soma[30] =  cp[30] - cn[30];

        CSA_1 sp31 (P[17],  cp[31]);
        CSA_2 sn31 (P[16], P[18], cn[31] );
        assign soma[31] =  cp[31] - cn[31];

        CSA_1 sp32 (P[19],  cp[32]);
        CSA_2 sn32 (P[17], P[18], cn[32] );
        assign soma[32] =  cp[32] - cn[32];

        CSA_1 sp33 (P[16],  cp[33]);
        assign soma[33] =  cp[33];

        CSA_1 sp34 (P[17],  cp[34]);
        assign soma[34] =  cp[34];

        CSA_1 sp35 (P[18],  cp[35]);
        assign soma[35] =  cp[35];


endmodule


