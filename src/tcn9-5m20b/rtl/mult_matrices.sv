//-------------------------------------------------------------------------
// FERNANDO MORAES                                             October/2024
//-------------------------------------------------------------------------


//-------------------------------------------------------------------------
//Matrix C   ---  (rows): 25     Y (columns): 25     max shift: 3 
//-------------------------------------------------------------------------
module MatrixC
  import packConv::*;
  (
    input  type_input P,
    output type_input soma
  );

  timeunit 1ns;
  timeprecision 1ps;
  

  type_input cp, cn;
  logic_vector sb0, sb1, sb1, sb2, sb2, sb3, sb3, sb4, sb5, sb5, sb6, sb6, sb7, sb7, sb8, sb8, sb9, sb10, sb10, sb11, sb11, sb12, sb12, sb12, sb13, sb13, sb14, sb15, sb15, sb16, sb16, sb17, sb17, sb18, sb18, sb19, sb20, sb21, sb22, sb23;

  always_comb begin
    
    sb0  = P[0 ] <<< 2;
    sb5  = P[5 ] <<< 2;
    sb10 = P[10] <<< 2;
    sb15 = P[15] <<< 2;
    sb20 = P[20] <<< 2;

    sb2  = P[2 ] <<< 2;
    sb7  = P[7 ] <<< 2;
    sb12 = P[12] <<< 2;
    sb17 = P[17] <<< 2;
    sb22 = P[22] <<< 2;

    sb1  = P[1 ] <<< 2;
    sb6  = P[6 ] <<< 2;
    sb11 = P[11] <<< 2;
    sb16 = P[16] <<< 2;
    sb21 = P[21] <<< 2;

    sb3  = P[3 ] <<< 2;
    sb8  = P[8 ] <<< 2;
    sb13 = P[13] <<< 2;
    sb18 = P[18] <<< 2;
    sb23 = P[23] <<< 2;
  end

  CSA_2 sp0 (sb0 ,  P[3],  cp[0 ]);
  CSA_2 sp5 (sb5 ,  P[8],  cp[5 ]);
  CSA_2 sp10(sb10, P[13],  cp[10]);
  CSA_2 sp15(sb15, P[18],  cp[15]);
  CSA_2 sp20(sb20, P[23],  cp[20]);
  CSA_2 sn0 (P[1 ], sb2,  cn[0 ]);
  CSA_2 sn5 (P[6 ], sb7,  cn[5 ]);
  CSA_2 sn10(P[11], sb12, cn[10]);
  CSA_2 sn15(P[16], sb17, cn[15]);
  CSA_2 sn20(P[21], sb22, cn[20]);
  assign soma[0 ] = cp[0 ] - cn[0 ];
  assign soma[5 ] = cp[5 ] - cn[5 ];
  assign soma[10] = cp[10] - cn[10];
  assign soma[15] = cp[15] - cn[15];
  assign soma[20] = cp[20] - cn[20];

  CSA_2 sn1 (sb1 , P[2 ]  cn[1 ]);
  CSA_2 sn6 (sb6 , P[7 ]  cn[6 ]);
  CSA_2 sn11(sb11, P[12], cn[11]);
  CSA_2 sn16(sb16, P[17], cn[16]);
  CSA_2 sn21(sb21, P[22], cn[21]);
  assign soma[1 ] = P[3 ] - cn[1 ];
  assign soma[6 ] = P[8 ] - cn[6 ];
  assign soma[11] = P[13] - cn[11];
  assign soma[16] = P[18] - cn[16];
  assign soma[21] = P[23] - cn[21];

  CSA_2 sp3 (sb1 , P[3 ]  cp[2 ]);
  CSA_2 sp8 (sb6 , P[8 ]  cp[7 ]);
  CSA_2 sp13(sb11, P[13], cp[12]);
  CSA_2 sp18(sb16, P[18], cp[17]);
  CSA_2 sp23(sb21, P[23], cp[22]);
  CSA_2 sn2 (sb2 , P[2 ], cn[2 ]);
  CSA_2 sn7 (sb7 , P[7 ], cn[7 ]);
  CSA_2 sn12(sb12, P[12], cn[12]);
  CSA_2 sn17(sb17, P[17], cn[17]);
  CSA_2 sn22(sb22, P[22], cn[22]);
  assign soma[2 ] = cp[2 ] - cn[2 ];
  assign soma[7 ] = cp[7 ] - cn[7 ];
  assign soma[12] = cp[12] - cn[12];
  assign soma[17] = cp[17] - cn[17];
  assign soma[22] = cp[22] - cn[22];

  assign soma[3 ] = P[3 ] - P[1 ];
  assign soma[8 ] = P[8 ] - P[6 ];
  assign soma[13] = P[13] - P[11];
  assign soma[18] = P[18] - P[16];
  assign soma[23] = P[23] - P[21];

  CSA_2 sp4 (sb1 , P[4 ]  cp[4 ]);
  CSA_2 sp9 (sb6 , P[9 ]  cp[9 ]);
  CSA_2 sp14(sb11, P[14], cp[14]);
  CSA_2 sp18(sb16, P[18], cp[18]);
  CSA_2 sp23(sb21, P[23], cp[23]);
  CSA_2 sn4 (P[2 ], sb3 , cn[4 ]);
  CSA_2 sn9 (P[7 ], sb8 , cn[9 ]);
  CSA_2 sn14(P[12], sb13, cn[14]);
  CSA_2 sn18(P[17], sb18, cn[18]);
  CSA_2 sn23(P[22], sb23, cn[23]);
  assign soma[4 ] = cp[4 ] - cn[4 ];
  assign soma[9 ] = cp[9 ] - cn[9 ];
  assign soma[14] = cp[14] - cn[14];
  assign soma[18] = cp[18] - cn[18];
  assign soma[23] = cp[23] - cn[23];


endmodule


//-------------------------------------------------------------------------
//Matrix A  --  X (rows): 9     Y (columns): 25     max shift: 4 
//-------------------------------------------------------------------------
module MatrixA
   import packConv::*;
    (
      input  type_input P,
      output type_output soma
    );

  timeunit 1ns;
  timeprecision 1ps;
  

      type_input ap, an;
      logic_vector  s1P3, s2P3, s1P8, s2P8, s1P13, s2P13, s1P15, s2P15, s1P16, s2P16, s1P17, s2P17, s1P18, s2P18, s3P18, s4P18, s1P19, s2P19, s1P23, s2P23;

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
