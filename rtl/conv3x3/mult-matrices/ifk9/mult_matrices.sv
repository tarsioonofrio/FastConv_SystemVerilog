module Inverse
  import pack_typedef::*;
  (
    input  type_weight pin,
    output type_output pout
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign pout[0] = pin[0] + pin[3] + pin[4] + pin[18] + pin[21] + pin[22] + pin[24] + pin[27] + pin[28];
  assign pout[1] = pin[1] + pin[3] + pin[5] + pin[19] + pin[21] + pin[23] + pin[25] + pin[27] + pin[29];
  assign pout[2] = pin[2] + pin[4] + pin[5] + pin[20] + pin[22] + pin[23] + pin[26] + pin[28] + pin[29];
  assign pout[3] = pin[6] + pin[9] + pin[10] + pin[18] + pin[21] + pin[22] + pin[30] + pin[33] + pin[34];
  assign pout[4] = pin[7] + pin[9] + pin[11] + pin[19] + pin[21] + pin[23] + pin[31] + pin[33] + pin[35];
  assign pout[5] = pin[8] + pin[10] + pin[11] + pin[20] + pin[22] + pin[23] + pin[32] + pin[34] + pin[35];
  assign pout[6] = pin[12] + pin[15] + pin[16] + pin[24] + pin[27] + pin[28] + pin[30] + pin[33] + pin[34];
  assign pout[7] = pin[13] + pin[15] + pin[17] + pin[25] + pin[27] + pin[29] + pin[31] + pin[33] + pin[35];
  assign pout[8] = pin[14] + pin[16] + pin[17] + pin[26] + pin[28] + pin[29] + pin[32] + pin[34] + pin[35];
endmodule


module Transform
  import pack_typedef::*;
  (
    input  type_input pin,
    output type_weight pout
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign pout[0] = pin[0] + pin[6] + pin[7] + pin[11] + pin[12] - (pin[1] + pin[2] + pin[5] + pin[10]);
  assign pout[1] = pin[2] + pin[6] + pin[8] + pin[11] + pin[13] - (pin[1] + pin[3] + pin[7] + pin[12]);
  assign pout[2] = pin[4] + pin[7] + pin[8] + pin[12] + pin[13] - (pin[2] + pin[3] + pin[9] + pin[14]);
  assign pout[3] = pin[1] - (pin[6] + pin[11]);
  assign pout[4] = pin[2] - (pin[7] + pin[12]);
  assign pout[5] = pin[3] - (pin[8] + pin[13]);
  assign pout[6] = pin[6] + pin[7] + pin[10] + pin[16] + pin[17] - (pin[5] + pin[11] + pin[12] + pin[15]);
  assign pout[7] = pin[6] + pin[8] + pin[12] + pin[16] + pin[18] - (pin[7] + pin[11] + pin[13] + pin[17]);
  assign pout[8] = pin[7] + pin[8] + pin[14] + pin[17] + pin[18] - (pin[9] + pin[12] + pin[13] + pin[19]);
  assign pout[9] = pin[11] - (pin[6] + pin[16]);
  assign pout[10] = pin[12] - (pin[7] + pin[17]);
  assign pout[11] = pin[13] - (pin[8] + pin[18]);
  assign pout[12] = pin[11] + pin[12] + pin[16] + pin[17] + pin[20] - (pin[10] + pin[15] + pin[21] + pin[22]);
  assign pout[13] = pin[11] + pin[13] + pin[16] + pin[18] + pin[22] - (pin[12] + pin[17] + pin[21] + pin[23]);
  assign pout[14] = pin[12] + pin[13] + pin[17] + pin[18] + pin[24] - (pin[14] + pin[19] + pin[22] + pin[23]);
  assign pout[15] = pin[21] - (pin[11] + pin[16]);
  assign pout[16] = pin[22] - (pin[12] + pin[17]);
  assign pout[17] = pin[23] - (pin[13] + pin[18]);
  assign pout[18] = pin[5] - (pin[6] + pin[7]);
  assign pout[19] = pin[7] - (pin[6] + pin[8]);
  assign pout[20] = pin[9] - (pin[7] + pin[8]);
  assign pout[21] = pin[6];
  assign pout[22] = pin[7];
  assign pout[23] = pin[8];
  assign pout[24] = pin[10] - (pin[11] + pin[12]);
  assign pout[25] = pin[12] - (pin[11] + pin[13]);
  assign pout[26] = pin[14] - (pin[12] + pin[13]);
  assign pout[27] = pin[11];
  assign pout[28] = pin[12];
  assign pout[29] = pin[13];
  assign pout[30] = pin[15] - (pin[16] + pin[17]);
  assign pout[31] = pin[17] - (pin[16] + pin[18]);
  assign pout[32] = pin[19] - (pin[17] + pin[18]);
  assign pout[33] = pin[16];
  assign pout[34] = pin[17];
  assign pout[35] = pin[18];
endmodule
