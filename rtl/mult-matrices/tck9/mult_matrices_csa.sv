module Inverse
  import pack_typedef::*;
  (
    input  type_weight pin,
    output type_output pout
  );
  timeunit 1ns;
  timeprecision 1ps;

  type_output cp, cn;

  CSA_16 sp0 (pin[0], pin[1], pin[2], pin[3], pin[5], pin[6], pin[7], pin[8], pin[10], pin[11], pin[12], pin[13], pin[15], pin[16], pin[17], pin[18],  cp[0]);
  assign pout[0] =  cp[0];

  CSA_8 sp1 (pin[1], pin[3] <<< 1, pin[6], pin[8] <<< 1, pin[11], pin[13] <<< 1, pin[16], pin[18] <<< 1,  cp[1]);
  CSA_4 sn1 (pin[2], pin[7], pin[12], pin[17], cn[1] );
  assign pout[1] =  cp[1] - cn[1];

  CSA_16 sp2 (pin[1], pin[2], pin[3] <<< 2, pin[4], pin[6], pin[7], pin[8] <<< 2, pin[9], pin[11], pin[12], pin[13] <<< 2, pin[14], pin[16], pin[17], pin[18] <<< 2, pin[19],  cp[2]);
  assign pout[2] =  cp[2];

  CSA_8 sp3 (pin[5], pin[6], pin[7], pin[8], pin[15] <<< 1, pin[16] <<< 1, pin[17] <<< 1, pin[18] <<< 1,  cp[3]);
  CSA_4 sn3 (pin[10], pin[11], pin[12], pin[13], cn[3] );
  assign pout[3] =  cp[3] - cn[3];

  CSA_5 sp4 (pin[6], pin[8] <<< 1, pin[12], pin[16] <<< 1, pin[18] <<< 2,  cp[4]);
  CSA_4 sn4 (pin[7], pin[11], pin[13] <<< 1, pin[17] <<< 1, cn[4] );
  assign pout[4] =  cp[4] - cn[4];

  CSA_8 sp5 (pin[6], pin[7], pin[8] <<< 2, pin[9], pin[16] <<< 1, pin[17] <<< 1, pin[18] <<< 3, pin[19] <<< 1,  cp[5]);
  CSA_4 sn5 (pin[11], pin[12], pin[13] <<< 2, pin[14], cn[5] );
  assign pout[5] =  cp[5] - cn[5];

  CSA_16 sp6 (pin[5], pin[6], pin[7], pin[8], pin[10], pin[11], pin[12], pin[13], pin[15] <<< 2, pin[16] <<< 2, pin[17] <<< 2, pin[18] <<< 2, pin[20], pin[21], pin[22], pin[23],  cp[6]);
  assign pout[6] =  cp[6];

  CSA_8 sp7 (pin[6], pin[8] <<< 1, pin[11], pin[13] <<< 1, pin[16] <<< 2, pin[18] <<< 3, pin[21], pin[23] <<< 1,  cp[7]);
  CSA_4 sn7 (pin[7], pin[12], pin[17] <<< 2, pin[22], cn[7] );
  assign pout[7] =  cp[7] - cn[7];

  CSA_16 sp8 (pin[6], pin[7], pin[8] <<< 2, pin[9], pin[11], pin[12], pin[13] <<< 2, pin[14], pin[16] <<< 2, pin[17] <<< 2, pin[18] <<< 4, pin[19] <<< 2, pin[21], pin[22], pin[23] <<< 2, pin[24],  cp[8]);
  assign pout[8] =  cp[8];
endmodule


module Transform
  import pack_typedef::*;
  (
    input  type_input pin,
    output type_weight pout
  );
  timeunit 1ns;
  timeprecision 1ps;

  type_weight cp, cn;

  CSA_8 sp0 (pin[0] <<< 2, pin[3] <<< 1, pin[6], pin[7] <<< 1, pin[11] <<< 1, pin[12] <<< 2, pin[15] <<< 1, pin[18],  cp[0]);
  CSA_8 sn0 (pin[1] <<< 1, pin[2] <<< 2, pin[5] <<< 1, pin[8], pin[10] <<< 2, pin[13] <<< 1, pin[16], pin[17] <<< 1, cn[0] );
  assign pout[0] =  cp[0] - cn[0];

  CSA_6 sp1 (pin[3] <<< 1, pin[6] <<< 1, pin[7], pin[11] <<< 2, pin[12] <<< 1, pin[18],  cp[1]);
  CSA_6 sn1 (pin[1] <<< 2, pin[2] <<< 1, pin[8], pin[13] <<< 1, pin[16] <<< 1, pin[17], cn[1] );
  assign pout[1] =  cp[1] - cn[1];

  CSA_8 sp2 (pin[1] <<< 2, pin[3] <<< 1, pin[7], pin[7] <<< 1, pin[12] <<< 1, pin[12] <<< 2, pin[16] <<< 1, pin[18],  cp[2]);
  CSA_8 sn2 (pin[2] <<< 1, pin[2] <<< 2, pin[6] <<< 1, pin[8], pin[11] <<< 2, pin[13] <<< 1, pin[17], pin[17] <<< 1, cn[2] );
  assign pout[2] =  cp[2] - cn[2];

  CSA_4 sp3 (pin[3] <<< 1, pin[6], pin[11] <<< 1, pin[18],  cp[3]);
  CSA_4 sn3 (pin[1] <<< 1, pin[8], pin[13] <<< 1, pin[16], cn[3] );
  assign pout[3] =  cp[3] - cn[3];

  CSA_8 sp4 (pin[1] <<< 2, pin[4] <<< 1, pin[7], pin[8] <<< 1, pin[12] <<< 1, pin[13] <<< 2, pin[16] <<< 1, pin[19],  cp[4]);
  CSA_8 sn4 (pin[2] <<< 1, pin[3] <<< 2, pin[6] <<< 1, pin[9], pin[11] <<< 2, pin[14] <<< 1, pin[17], pin[18] <<< 1, cn[4] );
  assign pout[4] =  cp[4] - cn[4];

  CSA_6 sp5 (pin[6] <<< 1, pin[7] <<< 2, pin[11], pin[12] <<< 1, pin[15] <<< 1, pin[18],  cp[5]);
  CSA_6 sn5 (pin[5] <<< 2, pin[8] <<< 1, pin[10] <<< 1, pin[13], pin[16], pin[17] <<< 1, cn[5] );
  assign pout[5] =  cp[5] - cn[5];

  CSA_5 sp6 (pin[6] <<< 2, pin[7] <<< 1, pin[11] <<< 1, pin[12], pin[18],  cp[6]);
  CSA_4 sn6 (pin[8] <<< 1, pin[13], pin[16] <<< 1, pin[17], cn[6] );
  assign pout[6] =  cp[6] - cn[6];

  CSA_6 sp7 (pin[7] <<< 1, pin[7] <<< 2, pin[12], pin[12] <<< 1, pin[16] <<< 1, pin[18],  cp[7]);
  CSA_6 sn7 (pin[6] <<< 2, pin[8] <<< 1, pin[11] <<< 1, pin[13], pin[17], pin[17] <<< 1, cn[7] );
  assign pout[7] =  cp[7] - cn[7];

  CSA_3 sp8 (pin[6] <<< 1, pin[11], pin[18],  cp[8]);
  CSA_3 sn8 (pin[8] <<< 1, pin[13], pin[16], cn[8] );
  assign pout[8] =  cp[8] - cn[8];

  CSA_6 sp9 (pin[7] <<< 1, pin[8] <<< 2, pin[12], pin[13] <<< 1, pin[16] <<< 1, pin[19],  cp[9]);
  CSA_6 sn9 (pin[6] <<< 2, pin[9] <<< 1, pin[11] <<< 1, pin[14], pin[17], pin[18] <<< 1, cn[9] );
  assign pout[9] =  cp[9] - cn[9];

  CSA_8 sp10 (pin[5] <<< 2, pin[8] <<< 1, pin[11], pin[11] <<< 1, pin[12] <<< 1, pin[12] <<< 2, pin[15] <<< 1, pin[18],  cp[10]);
  CSA_8 sn10 (pin[6] <<< 1, pin[7] <<< 2, pin[10] <<< 1, pin[10] <<< 2, pin[13], pin[13] <<< 1, pin[16], pin[17] <<< 1, cn[10] );
  assign pout[10] =  cp[10] - cn[10];

  CSA_6 sp11 (pin[8] <<< 1, pin[11] <<< 1, pin[11] <<< 2, pin[12], pin[12] <<< 1, pin[18],  cp[11]);
  CSA_6 sn11 (pin[6] <<< 2, pin[7] <<< 1, pin[13], pin[13] <<< 1, pin[16] <<< 1, pin[17], cn[11] );
  assign pout[11] =  cp[11] - cn[11];

  CSA_6 sp12 (pin[6] <<< 2, pin[8] <<< 1, pin[12], pin[12] <<< 3, pin[16] <<< 1, pin[18],  cp[12]);
  CSA_8 sn12 (pin[7] <<< 1, pin[7] <<< 2, pin[11] <<< 1, pin[11] <<< 2, pin[13], pin[13] <<< 1, pin[17], pin[17] <<< 1, cn[12] );
  assign pout[12] =  cp[12] - cn[12];

  CSA_4 sp13 (pin[8] <<< 1, pin[11], pin[11] <<< 1, pin[18],  cp[13]);
  CSA_4 sn13 (pin[6] <<< 1, pin[13], pin[13] <<< 1, pin[16], cn[13] );
  assign pout[13] =  cp[13] - cn[13];

  CSA_8 sp14 (pin[6] <<< 2, pin[9] <<< 1, pin[12], pin[12] <<< 1, pin[13] <<< 1, pin[13] <<< 2, pin[16] <<< 1, pin[19],  cp[14]);
  CSA_8 sn14 (pin[7] <<< 1, pin[8] <<< 2, pin[11] <<< 1, pin[11] <<< 2, pin[14], pin[14] <<< 1, pin[17], pin[18] <<< 1, cn[14] );
  assign pout[14] =  cp[14] - cn[14];

  CSA_4 sp15 (pin[6], pin[7] <<< 1, pin[15] <<< 1, pin[18],  cp[15]);
  CSA_4 sn15 (pin[5] <<< 1, pin[8], pin[16], pin[17] <<< 1, cn[15] );
  assign pout[15] =  cp[15] - cn[15];

  CSA_3 sp16 (pin[6] <<< 1, pin[7], pin[18],  cp[16]);
  CSA_3 sn16 (pin[8], pin[16] <<< 1, pin[17], cn[16] );
  assign pout[16] =  cp[16] - cn[16];

  CSA_4 sp17 (pin[7], pin[7] <<< 1, pin[16] <<< 1, pin[18],  cp[17]);
  CSA_4 sn17 (pin[6] <<< 1, pin[8], pin[17], pin[17] <<< 1, cn[17] );
  assign pout[17] =  cp[17] - cn[17];

  CSA_2 sp18 (pin[6], pin[18],  cp[18]);
  CSA_2 sn18 (pin[8], pin[16], cn[18] );
  assign pout[18] =  cp[18] - cn[18];

  CSA_4 sp19 (pin[7], pin[8] <<< 1, pin[16] <<< 1, pin[19],  cp[19]);
  CSA_4 sn19 (pin[6] <<< 1, pin[9], pin[17], pin[18] <<< 1, cn[19] );
  assign pout[19] =  cp[19] - cn[19];

  CSA_8 sp20 (pin[5] <<< 2, pin[8] <<< 1, pin[11], pin[12] <<< 1, pin[16] <<< 1, pin[17] <<< 2, pin[20] <<< 1, pin[23],  cp[20]);
  CSA_8 sn20 (pin[6] <<< 1, pin[7] <<< 2, pin[10] <<< 1, pin[13], pin[15] <<< 2, pin[18] <<< 1, pin[21], pin[22] <<< 1, cn[20] );
  assign pout[20] =  cp[20] - cn[20];

  CSA_6 sp21 (pin[8] <<< 1, pin[11] <<< 1, pin[12], pin[16] <<< 2, pin[17] <<< 1, pin[23],  cp[21]);
  CSA_6 sn21 (pin[6] <<< 2, pin[7] <<< 1, pin[13], pin[18] <<< 1, pin[21] <<< 1, pin[22], cn[21] );
  assign pout[21] =  cp[21] - cn[21];

  CSA_8 sp22 (pin[6] <<< 2, pin[8] <<< 1, pin[12], pin[12] <<< 1, pin[17] <<< 1, pin[17] <<< 2, pin[21] <<< 1, pin[23],  cp[22]);
  CSA_8 sn22 (pin[7] <<< 1, pin[7] <<< 2, pin[11] <<< 1, pin[13], pin[16] <<< 2, pin[18] <<< 1, pin[22], pin[22] <<< 1, cn[22] );
  assign pout[22] =  cp[22] - cn[22];

  CSA_4 sp23 (pin[8] <<< 1, pin[11], pin[16] <<< 1, pin[23],  cp[23]);
  CSA_4 sn23 (pin[6] <<< 1, pin[13], pin[18] <<< 1, pin[21], cn[23] );
  assign pout[23] =  cp[23] - cn[23];

  CSA_8 sp24 (pin[6] <<< 2, pin[9] <<< 1, pin[12], pin[13] <<< 1, pin[17] <<< 1, pin[18] <<< 2, pin[21] <<< 1, pin[24],  cp[24]);
  CSA_8 sn24 (pin[7] <<< 1, pin[8] <<< 2, pin[11] <<< 1, pin[14], pin[16] <<< 2, pin[19] <<< 1, pin[22], pin[23] <<< 1, cn[24] );
  assign pout[24] =  cp[24] - cn[24];
endmodule
