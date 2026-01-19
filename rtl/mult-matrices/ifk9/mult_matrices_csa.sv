module Inverse
  import pack_typedef::*;
  (
    input  type_weight pin,
    output type_output pout
  );
  timeunit 1ns;
  timeprecision 1ps;

  CSA_9 sp0 (pin[0], pin[3], pin[4], pin[18], pin[21], pin[22], pin[24], pin[27], pin[28],  pout[0]);

  CSA_9 sp1 (pin[1], pin[3], pin[5], pin[19], pin[21], pin[23], pin[25], pin[27], pin[29],  pout[1]);

  CSA_9 sp2 (pin[2], pin[4], pin[5], pin[20], pin[22], pin[23], pin[26], pin[28], pin[29],  pout[2]);

  CSA_9 sp3 (pin[6], pin[9], pin[10], pin[18], pin[21], pin[22], pin[30], pin[33], pin[34],  pout[3]);

  CSA_9 sp4 (pin[7], pin[9], pin[11], pin[19], pin[21], pin[23], pin[31], pin[33], pin[35],  pout[4]);

  CSA_9 sp5 (pin[8], pin[10], pin[11], pin[20], pin[22], pin[23], pin[32], pin[34], pin[35],  pout[5]);

  CSA_9 sp6 (pin[12], pin[15], pin[16], pin[24], pin[27], pin[28], pin[30], pin[33], pin[34],  pout[6]);

  CSA_9 sp7 (pin[13], pin[15], pin[17], pin[25], pin[27], pin[29], pin[31], pin[33], pin[35],  pout[7]);

  CSA_9 sp8 (pin[14], pin[16], pin[17], pin[26], pin[28], pin[29], pin[32], pin[34], pin[35],  pout[8]);
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

  CSA_5 sp0 (pin[0], pin[6], pin[7], pin[11], pin[12],  cp[0]);
  CSA_4 sn0 (pin[1], pin[2], pin[5], pin[10], cn[0] );
  assign pout[0] =  cp[0] - cn[0];

  CSA_5 sp1 (pin[2], pin[6], pin[8], pin[11], pin[13],  cp[1]);
  CSA_4 sn1 (pin[1], pin[3], pin[7], pin[12], cn[1] );
  assign pout[1] =  cp[1] - cn[1];

  CSA_5 sp2 (pin[4], pin[7], pin[8], pin[12], pin[13],  cp[2]);
  CSA_4 sn2 (pin[2], pin[3], pin[9], pin[14], cn[2] );
  assign pout[2] =  cp[2] - cn[2];

  CSA_1 sp3 (pin[1],  cp[3]);
  CSA_2 sn3 (pin[6], pin[11], cn[3] );
  assign pout[3] =  cp[3] - cn[3];

  CSA_1 sp4 (pin[2],  cp[4]);
  CSA_2 sn4 (pin[7], pin[12], cn[4] );
  assign pout[4] =  cp[4] - cn[4];

  CSA_1 sp5 (pin[3],  cp[5]);
  CSA_2 sn5 (pin[8], pin[13], cn[5] );
  assign pout[5] =  cp[5] - cn[5];

  CSA_5 sp6 (pin[6], pin[7], pin[10], pin[16], pin[17],  cp[6]);
  CSA_4 sn6 (pin[5], pin[11], pin[12], pin[15], cn[6] );
  assign pout[6] =  cp[6] - cn[6];

  CSA_5 sp7 (pin[6], pin[8], pin[12], pin[16], pin[18],  cp[7]);
  CSA_4 sn7 (pin[7], pin[11], pin[13], pin[17], cn[7] );
  assign pout[7] =  cp[7] - cn[7];

  CSA_5 sp8 (pin[7], pin[8], pin[14], pin[17], pin[18],  cp[8]);
  CSA_4 sn8 (pin[9], pin[12], pin[13], pin[19], cn[8] );
  assign pout[8] =  cp[8] - cn[8];

  CSA_1 sp9 (pin[11],  cp[9]);
  CSA_2 sn9 (pin[6], pin[16], cn[9] );
  assign pout[9] =  cp[9] - cn[9];

  CSA_1 sp10 (pin[12],  cp[10]);
  CSA_2 sn10 (pin[7], pin[17], cn[10] );
  assign pout[10] =  cp[10] - cn[10];

  CSA_1 sp11 (pin[13],  cp[11]);
  CSA_2 sn11 (pin[8], pin[18], cn[11] );
  assign pout[11] =  cp[11] - cn[11];

  CSA_5 sp12 (pin[11], pin[12], pin[16], pin[17], pin[20],  cp[12]);
  CSA_4 sn12 (pin[10], pin[15], pin[21], pin[22], cn[12] );
  assign pout[12] =  cp[12] - cn[12];

  CSA_5 sp13 (pin[11], pin[13], pin[16], pin[18], pin[22],  cp[13]);
  CSA_4 sn13 (pin[12], pin[17], pin[21], pin[23], cn[13] );
  assign pout[13] =  cp[13] - cn[13];

  CSA_5 sp14 (pin[12], pin[13], pin[17], pin[18], pin[24],  cp[14]);
  CSA_4 sn14 (pin[14], pin[19], pin[22], pin[23], cn[14] );
  assign pout[14] =  cp[14] - cn[14];

  CSA_1 sp15 (pin[21],  cp[15]);
  CSA_2 sn15 (pin[11], pin[16], cn[15] );
  assign pout[15] =  cp[15] - cn[15];

  CSA_1 sp16 (pin[22],  cp[16]);
  CSA_2 sn16 (pin[12], pin[17], cn[16] );
  assign pout[16] =  cp[16] - cn[16];

  CSA_1 sp17 (pin[23],  cp[17]);
  CSA_2 sn17 (pin[13], pin[18], cn[17] );
  assign pout[17] =  cp[17] - cn[17];

  CSA_1 sp18 (pin[5],  cp[18]);
  CSA_2 sn18 (pin[6], pin[7], cn[18] );
  assign pout[18] =  cp[18] - cn[18];

  CSA_1 sp19 (pin[7],  cp[19]);
  CSA_2 sn19 (pin[6], pin[8], cn[19] );
  assign pout[19] =  cp[19] - cn[19];

  CSA_1 sp20 (pin[9],  cp[20]);
  CSA_2 sn20 (pin[7], pin[8], cn[20] );
  assign pout[20] =  cp[20] - cn[20];

  CSA_1 sp21 (pin[6],  cp[21]);
  assign pout[21] =  cp[21];

  CSA_1 sp22 (pin[7],  cp[22]);
  assign pout[22] =  cp[22];

  CSA_1 sp23 (pin[8],  cp[23]);
  assign pout[23] =  cp[23];

  CSA_1 sp24 (pin[10],  cp[24]);
  CSA_2 sn24 (pin[11], pin[12], cn[24] );
  assign pout[24] =  cp[24] - cn[24];

  CSA_1 sp25 (pin[12],  cp[25]);
  CSA_2 sn25 (pin[11], pin[13], cn[25] );
  assign pout[25] =  cp[25] - cn[25];

  CSA_1 sp26 (pin[14],  cp[26]);
  CSA_2 sn26 (pin[12], pin[13], cn[26] );
  assign pout[26] =  cp[26] - cn[26];

  CSA_1 sp27 (pin[11],  cp[27]);
  assign pout[27] =  cp[27];

  CSA_1 sp28 (pin[12],  cp[28]);
  assign pout[28] =  cp[28];

  CSA_1 sp29 (pin[13],  cp[29]);
  assign pout[29] =  cp[29];

  CSA_1 sp30 (pin[15],  cp[30]);
  CSA_2 sn30 (pin[16], pin[17], cn[30] );
  assign pout[30] =  cp[30] - cn[30];

  CSA_1 sp31 (pin[17],  cp[31]);
  CSA_2 sn31 (pin[16], pin[18], cn[31] );
  assign pout[31] =  cp[31] - cn[31];

  CSA_1 sp32 (pin[19],  cp[32]);
  CSA_2 sn32 (pin[17], pin[18], cn[32] );
  assign pout[32] =  cp[32] - cn[32];

  CSA_1 sp33 (pin[16],  cp[33]);
  assign pout[33] =  cp[33];

  CSA_1 sp34 (pin[17],  cp[34]);
  assign pout[34] =  cp[34];

  CSA_1 sp35 (pin[18],  cp[35]);
  assign pout[35] =  cp[35];
endmodule
