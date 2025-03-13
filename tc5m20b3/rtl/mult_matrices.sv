//-------------------------------------------------------------------------
// FERNANDO MORAES                                             October/2024
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------
//Matrix A  --  X (rows): 9     Y (columns): 25     max shift: 4 
//-------------------------------------------------------------------------
module MatrixA
   import packConv::*;
    (
      input  param25 P,
      output param9 soma
    );

  timeunit 1ns;
  timeprecision 1ps;
  

      param25 ap, an;
      regC  s1P3, s2P3, s1P8, s2P8, s1P13, s2P13, s1P15, s2P15, s1P16, s2P16, s1P17, s2P17, s1P18, s2P18, s3P18, s4P18, s1P19, s2P19, s1P23, s2P23;

      always_comb begin
        s1P3 = {P[3][NBITS-2:0],  1'b0};
        s2P3 = {P[3][NBITS-3:0],  2'b00};
        s1P8 = {P[8][NBITS-2:0],  1'b0};
        s2P8 = {P[8][NBITS-3:0],  2'b00};
        s1P13 = {P[13][NBITS-2:0],  1'b0};
        s2P13 = {P[13][NBITS-3:0],  2'b00};
        s1P15 = {P[15][NBITS-2:0],  1'b0};
        s2P15 = {P[15][NBITS-3:0],  2'b00};
        s1P16 = {P[16][NBITS-2:0],  1'b0};
        s2P16 = {P[16][NBITS-3:0],  2'b00};
        s1P17 = {P[17][NBITS-2:0],  1'b0};
        s2P17 = {P[17][NBITS-3:0],  2'b00};
        s1P18 = {P[18][NBITS-2:0],  1'b0};
        s2P18 = {P[18][NBITS-3:0],  2'b00};
        s3P18 = {P[18][NBITS-4:0],  3'b000};
        s4P18 = {P[18][NBITS-5:0],  4'b0000};
        s1P19 = {P[19][NBITS-2:0],  1'b0};
        s2P19 = {P[19][NBITS-3:0],  2'b00};
        s1P23 = {P[23][NBITS-2:0],  1'b0};
        s2P23 = {P[23][NBITS-3:0],  2'b00};
      end

        CSA_16 sp0 (P[0], P[1], P[2], P[3], P[5], P[6], P[7], P[8], P[10], P[11], P[12], P[13], P[15], P[16], P[17], P[18],  ap[0]);
        assign soma[0] =  ap[0];

        CSA_8 sp1 (P[1], s1P3, P[6], s1P8, P[11], s1P13, P[16], s1P18,  ap[1]);
        CSA_4 sn1 (P[2], P[7], P[12], P[17], an[1] );
        assign soma[1] =  ap[1] - an[1];

        CSA_16 sp2 (P[1], P[2], s2P3, P[4], P[6], P[7], s2P8, P[9], P[11], P[12], s2P13, P[14], P[16], P[17], s2P18, P[19],  ap[2]);
        assign soma[2] =  ap[2];

        CSA_8 sp3 (P[5], P[6], P[7], P[8], s1P15, s1P16, s1P17, s1P18,  ap[3]);
        CSA_4 sn3 (P[10], P[11], P[12], P[13], an[3] );
        assign soma[3] =  ap[3] - an[3];

        CSA_5 sp4 (P[6], s1P8, P[12], s1P16, s2P18,  ap[4]);
        CSA_4 sn4 (P[7], P[11], s1P13, s1P17, an[4] );
        assign soma[4] =  ap[4] - an[4];

        CSA_8 sp5 (P[6], P[7], s2P8, P[9], s1P16, s1P17, s3P18, s1P19,  ap[5]);
        CSA_4 sn5 (P[11], P[12], s2P13, P[14], an[5] );
        assign soma[5] =  ap[5] - an[5];

        CSA_16 sp6 (P[5], P[6], P[7], P[8], P[10], P[11], P[12], P[13], s2P15, s2P16, s2P17, s2P18, P[20], P[21], P[22], P[23],  ap[6]);
        assign soma[6] =  ap[6];

        CSA_8 sp7 (P[6], s1P8, P[11], s1P13, s2P16, s3P18, P[21], s1P23,  ap[7]);
        CSA_4 sn7 (P[7], P[12], s2P17, P[22], an[7] );
        assign soma[7] =  ap[7] - an[7];

        CSA_16 sp8 (P[6], P[7], s2P8, P[9], P[11], P[12], s2P13, P[14], s2P16, s2P17, s4P18, s2P19, P[21], P[22], s2P23, P[24],  ap[8]);
        assign soma[8] =  ap[8];


endmodule

//-------------------------------------------------------------------------
//Matrix C   ---  (rows): 25     Y (columns): 25     max shift: 3 
//-------------------------------------------------------------------------
module MatrixC
   import packConv::*;
    (
      input  param25 P,
      output param25 soma
    );

  timeunit 1ns;
  timeprecision 1ps;
  

      param25 cp, cn;
      regC  s2P0, s1P1, s2P1, s1P2, s2P2, s1P3, s2P3, s1P4, s1P5, s2P5, s1P6, s2P6, s1P7, s2P7, s1P8, s2P8, s1P9, s1P10, s2P10, s1P11, s2P11, s1P12, s2P12, s3P12, s1P13, s2P13, s1P14, s1P15, s2P15, s1P16, s2P16, s1P17, s2P17, s1P18, s2P18, s1P19, s1P20, s1P21, s1P22, s1P23;

      always_comb begin
        s2P0 = {P[0][NBITS-3:0],  2'b00};
        s1P1 = {P[1][NBITS-2:0],  1'b0};
        s2P1 = {P[1][NBITS-3:0],  2'b00};
        s1P2 = {P[2][NBITS-2:0],  1'b0};
        s2P2 = {P[2][NBITS-3:0],  2'b00};
        s1P3 = {P[3][NBITS-2:0],  1'b0};
        s2P3 = {P[3][NBITS-3:0],  2'b00};
        s1P4 = {P[4][NBITS-2:0],  1'b0};
        s1P5 = {P[5][NBITS-2:0],  1'b0};
        s2P5 = {P[5][NBITS-3:0],  2'b00};
        s1P6 = {P[6][NBITS-2:0],  1'b0};
        s2P6 = {P[6][NBITS-3:0],  2'b00};
        s1P7 = {P[7][NBITS-2:0],  1'b0};
        s2P7 = {P[7][NBITS-3:0],  2'b00};
        s1P8 = {P[8][NBITS-2:0],  1'b0};
        s2P8 = {P[8][NBITS-3:0],  2'b00};
        s1P9 = {P[9][NBITS-2:0],  1'b0};
        s1P10 = {P[10][NBITS-2:0],  1'b0};
        s2P10 = {P[10][NBITS-3:0],  2'b00};
        s1P11 = {P[11][NBITS-2:0],  1'b0};
        s2P11 = {P[11][NBITS-3:0],  2'b00};
        s1P12 = {P[12][NBITS-2:0],  1'b0};
        s2P12 = {P[12][NBITS-3:0],  2'b00};
        s3P12 = {P[12][NBITS-4:0],  3'b000};
        s1P13 = {P[13][NBITS-2:0],  1'b0};
        s2P13 = {P[13][NBITS-3:0],  2'b00};
        s1P14 = {P[14][NBITS-2:0],  1'b0};
        s1P15 = {P[15][NBITS-2:0],  1'b0};
        s2P15 = {P[15][NBITS-3:0],  2'b00};
        s1P16 = {P[16][NBITS-2:0],  1'b0};
        s2P16 = {P[16][NBITS-3:0],  2'b00};
        s1P17 = {P[17][NBITS-2:0],  1'b0};
        s2P17 = {P[17][NBITS-3:0],  2'b00};
        s1P18 = {P[18][NBITS-2:0],  1'b0};
        s2P18 = {P[18][NBITS-3:0],  2'b00};
        s1P19 = {P[19][NBITS-2:0],  1'b0};
        s1P20 = {P[20][NBITS-2:0],  1'b0};
        s1P21 = {P[21][NBITS-2:0],  1'b0};
        s1P22 = {P[22][NBITS-2:0],  1'b0};
        s1P23 = {P[23][NBITS-2:0],  1'b0};
      end

        CSA_8 sp0 (s2P0, s1P3, P[6], s1P7, s1P11, s2P12, s1P15, P[18],  cp[0]);
        CSA_8 sn0 (s1P1, s2P2, s1P5, P[8], s2P10, s1P13, P[16], s1P17, cn[0] );
        assign soma[0] =  cp[0] - cn[0];

        CSA_6 sp1 (s1P3, s1P6, P[7], s2P11, s1P12, P[18],  cp[1]);
        CSA_6 sn1 (s2P1, s1P2, P[8], s1P13, s1P16, P[17], cn[1] );
        assign soma[1] =  cp[1] - cn[1];

        CSA_8 sp2 (s2P1, s1P3, P[7], s1P7, s1P12, s2P12, s1P16, P[18],  cp[2]);
        CSA_8 sn2 (s1P2, s2P2, s1P6, P[8], s2P11, s1P13, P[17], s1P17, cn[2] );
        assign soma[2] =  cp[2] - cn[2];

        CSA_4 sp3 (s1P3, P[6], s1P11, P[18],  cp[3]);
        CSA_4 sn3 (s1P1, P[8], s1P13, P[16], cn[3] );
        assign soma[3] =  cp[3] - cn[3];

        CSA_8 sp4 (s2P1, s1P4, P[7], s1P8, s1P12, s2P13, s1P16, P[19],  cp[4]);
        CSA_8 sn4 (s1P2, s2P3, s1P6, P[9], s2P11, s1P14, P[17], s1P18, cn[4] );
        assign soma[4] =  cp[4] - cn[4];

        CSA_6 sp5 (s1P6, s2P7, P[11], s1P12, s1P15, P[18],  cp[5]);
        CSA_6 sn5 (s2P5, s1P8, s1P10, P[13], P[16], s1P17, cn[5] );
        assign soma[5] =  cp[5] - cn[5];

        CSA_5 sp6 (s2P6, s1P7, s1P11, P[12], P[18],  cp[6]);
        CSA_4 sn6 (s1P8, P[13], s1P16, P[17], cn[6] );
        assign soma[6] =  cp[6] - cn[6];

        CSA_6 sp7 (s1P7, s2P7, P[12], s1P12, s1P16, P[18],  cp[7]);
        CSA_6 sn7 (s2P6, s1P8, s1P11, P[13], P[17], s1P17, cn[7] );
        assign soma[7] =  cp[7] - cn[7];

        CSA_3 sp8 (s1P6, P[11], P[18],  cp[8]);
        CSA_3 sn8 (s1P8, P[13], P[16], cn[8] );
        assign soma[8] =  cp[8] - cn[8];

        CSA_6 sp9 (s1P7, s2P8, P[12], s1P13, s1P16, P[19],  cp[9]);
        CSA_6 sn9 (s2P6, s1P9, s1P11, P[14], P[17], s1P18, cn[9] );
        assign soma[9] =  cp[9] - cn[9];

        CSA_8 sp10 (s2P5, s1P8, P[11], s1P11, s1P12, s2P12, s1P15, P[18],  cp[10]);
        CSA_8 sn10 (s1P6, s2P7, s1P10, s2P10, P[13], s1P13, P[16], s1P17, cn[10] );
        assign soma[10] =  cp[10] - cn[10];

        CSA_6 sp11 (s1P8, s1P11, s2P11, P[12], s1P12, P[18],  cp[11]);
        CSA_6 sn11 (s2P6, s1P7, P[13], s1P13, s1P16, P[17], cn[11] );
        assign soma[11] =  cp[11] - cn[11];

        CSA_6 sp12 (s2P6, s1P8, P[12], s3P12, s1P16, P[18],  cp[12]);
        CSA_8 sn12 (s1P7, s2P7, s1P11, s2P11, P[13], s1P13, P[17], s1P17, cn[12] );
        assign soma[12] =  cp[12] - cn[12];

        CSA_4 sp13 (s1P8, P[11], s1P11, P[18],  cp[13]);
        CSA_4 sn13 (s1P6, P[13], s1P13, P[16], cn[13] );
        assign soma[13] =  cp[13] - cn[13];

        CSA_8 sp14 (s2P6, s1P9, P[12], s1P12, s1P13, s2P13, s1P16, P[19],  cp[14]);
        CSA_8 sn14 (s1P7, s2P8, s1P11, s2P11, P[14], s1P14, P[17], s1P18, cn[14] );
        assign soma[14] =  cp[14] - cn[14];

        CSA_4 sp15 (P[6], s1P7, s1P15, P[18],  cp[15]);
        CSA_4 sn15 (s1P5, P[8], P[16], s1P17, cn[15] );
        assign soma[15] =  cp[15] - cn[15];

        CSA_3 sp16 (s1P6, P[7], P[18],  cp[16]);
        CSA_3 sn16 (P[8], s1P16, P[17], cn[16] );
        assign soma[16] =  cp[16] - cn[16];

        CSA_4 sp17 (P[7], s1P7, s1P16, P[18],  cp[17]);
        CSA_4 sn17 (s1P6, P[8], P[17], s1P17, cn[17] );
        assign soma[17] =  cp[17] - cn[17];

        CSA_2 sp18 (P[6], P[18],  cp[18]);
        CSA_2 sn18 (P[8], P[16], cn[18] );
        assign soma[18] =  cp[18] - cn[18];

        CSA_4 sp19 (P[7], s1P8, s1P16, P[19],  cp[19]);
        CSA_4 sn19 (s1P6, P[9], P[17], s1P18, cn[19] );
        assign soma[19] =  cp[19] - cn[19];

        CSA_8 sp20 (s2P5, s1P8, P[11], s1P12, s1P16, s2P17, s1P20, P[23],  cp[20]);
        CSA_8 sn20 (s1P6, s2P7, s1P10, P[13], s2P15, s1P18, P[21], s1P22, cn[20] );
        assign soma[20] =  cp[20] - cn[20];

        CSA_6 sp21 (s1P8, s1P11, P[12], s2P16, s1P17, P[23],  cp[21]);
        CSA_6 sn21 (s2P6, s1P7, P[13], s1P18, s1P21, P[22], cn[21] );
        assign soma[21] =  cp[21] - cn[21];

        CSA_8 sp22 (s2P6, s1P8, P[12], s1P12, s1P17, s2P17, s1P21, P[23],  cp[22]);
        CSA_8 sn22 (s1P7, s2P7, s1P11, P[13], s2P16, s1P18, P[22], s1P22, cn[22] );
        assign soma[22] =  cp[22] - cn[22];

        CSA_4 sp23 (s1P8, P[11], s1P16, P[23],  cp[23]);
        CSA_4 sn23 (s1P6, P[13], s1P18, P[21], cn[23] );
        assign soma[23] =  cp[23] - cn[23];

        CSA_8 sp24 (s2P6, s1P9, P[12], s1P13, s1P17, s2P18, s1P21, P[24],  cp[24]);
        CSA_8 sn24 (s1P7, s2P8, s1P11, P[14], s2P16, s1P19, P[22], s1P23, cn[24] );
        assign soma[24] =  cp[24] - cn[24];

endmodule


