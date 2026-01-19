module Inverse
  import pack_typedef::*;
  (
    input  type_weight pin,
    output type_output pout
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign pout[0] = pin[0] + pin[1] + pin[2] + pin[3] + pin[5] + pin[6] + pin[7] + pin[8] + pin[10] + pin[11] + pin[12] + pin[13] + pin[15] + pin[16] + pin[17] + pin[18];
  assign pout[1] = pin[1] + (pin[3] * 2) + pin[6] + (pin[8] * 2) + pin[11] + (pin[13] * 2) + pin[16] + (pin[18] * 2) - (pin[2] + pin[7] + pin[12] + pin[17]);
  assign pout[2] = pin[1] + pin[2] + (pin[3] * 4) + pin[4] + pin[6] + pin[7] + (pin[8] * 4) + pin[9] + pin[11] + pin[12] + (pin[13] * 4) + pin[14] + pin[16] + pin[17] + (pin[18] * 4) + pin[19];
  assign pout[3] = pin[5] + pin[6] + pin[7] + pin[8] + (pin[15] * 2) + (pin[16] * 2) + (pin[17] * 2) + (pin[18] * 2) - (pin[10] + pin[11] + pin[12] + pin[13]);
  assign pout[4] = pin[6] + (pin[8] * 2) + pin[12] + (pin[16] * 2) + (pin[18] * 4) - (pin[7] + pin[11] + (pin[13] * 2) + (pin[17] * 2));
  assign pout[5] = pin[6] + pin[7] + (pin[8] * 4) + pin[9] + (pin[16] * 2) + (pin[17] * 2) + (pin[18] * 8) + (pin[19] * 2) - (pin[11] + pin[12] + (pin[13] * 4) + pin[14]);
  assign pout[6] = pin[5] + pin[6] + pin[7] + pin[8] + pin[10] + pin[11] + pin[12] + pin[13] + (pin[15] * 4) + (pin[16] * 4) + (pin[17] * 4) + (pin[18] * 4) + pin[20] + pin[21] + pin[22] + pin[23];
  assign pout[7] = pin[6] + (pin[8] * 2) + pin[11] + (pin[13] * 2) + (pin[16] * 4) + (pin[18] * 8) + pin[21] + (pin[23] * 2) - (pin[7] + pin[12] + (pin[17] * 4) + pin[22]);
  assign pout[8] = pin[6] + pin[7] + (pin[8] * 4) + pin[9] + pin[11] + pin[12] + (pin[13] * 4) + pin[14] + (pin[16] * 4) + (pin[17] * 4) + (pin[18] * 16) + (pin[19] * 4) + pin[21] + pin[22] + (pin[23] * 4) + pin[24];
endmodule


module Transform
  import pack_typedef::*;
  (
    input  type_input pin,
    output type_weight pout
  );
  timeunit 1ns;
  timeprecision 1ps;

  assign pout[0] = (pin[0] * 4) + (pin[3] * 2) + pin[6] + (pin[7] * 2) + (pin[11] * 2) + (pin[12] * 4) + (pin[15] * 2) + pin[18] - ((pin[1] * 2) + (pin[2] * 4) + (pin[5] * 2) + pin[8] + (pin[10] * 4) + (pin[13] * 2) + pin[16] + (pin[17] * 2));
  assign pout[1] = (pin[3] * 2) + (pin[6] * 2) + pin[7] + (pin[11] * 4) + (pin[12] * 2) + pin[18] - ((pin[1] * 4) + (pin[2] * 2) + pin[8] + (pin[13] * 2) + (pin[16] * 2) + pin[17]);
  assign pout[2] = (pin[1] * 4) + (pin[3] * 2) + (pin[7] * 3) + (pin[12] * 6) + (pin[16] * 2) + pin[18] - ((pin[2] * 6) + (pin[6] * 2) + pin[8] + (pin[11] * 4) + (pin[13] * 2) + (pin[17] * 3));
  assign pout[3] = (pin[3] * 2) + pin[6] + (pin[11] * 2) + pin[18] - ((pin[1] * 2) + pin[8] + (pin[13] * 2) + pin[16]);
  assign pout[4] = (pin[1] * 4) + (pin[4] * 2) + pin[7] + (pin[8] * 2) + (pin[12] * 2) + (pin[13] * 4) + (pin[16] * 2) + pin[19] - ((pin[2] * 2) + (pin[3] * 4) + (pin[6] * 2) + pin[9] + (pin[11] * 4) + (pin[14] * 2) + pin[17] + (pin[18] * 2));
  assign pout[5] = (pin[6] * 2) + (pin[7] * 4) + pin[11] + (pin[12] * 2) + (pin[15] * 2) + pin[18] - ((pin[5] * 4) + (pin[8] * 2) + (pin[10] * 2) + pin[13] + pin[16] + (pin[17] * 2));
  assign pout[6] = (pin[6] * 4) + (pin[7] * 2) + (pin[11] * 2) + pin[12] + pin[18] - ((pin[8] * 2) + pin[13] + (pin[16] * 2) + pin[17]);
  assign pout[7] = (pin[7] * 6) + (pin[12] * 3) + (pin[16] * 2) + pin[18] - ((pin[6] * 4) + (pin[8] * 2) + (pin[11] * 2) + pin[13] + (pin[17] * 3));
  assign pout[8] = (pin[6] * 2) + pin[11] + pin[18] - ((pin[8] * 2) + pin[13] + pin[16]);
  assign pout[9] = (pin[7] * 2) + (pin[8] * 4) + pin[12] + (pin[13] * 2) + (pin[16] * 2) + pin[19] - ((pin[6] * 4) + (pin[9] * 2) + (pin[11] * 2) + pin[14] + pin[17] + (pin[18] * 2));
  assign pout[10] = (pin[5] * 4) + (pin[8] * 2) + (pin[11] * 3) + (pin[12] * 6) + (pin[15] * 2) + pin[18] - ((pin[6] * 2) + (pin[7] * 4) + (pin[10] * 6) + (pin[13] * 3) + pin[16] + (pin[17] * 2));
  assign pout[11] = (pin[8] * 2) + (pin[11] * 6) + (pin[12] * 3) + pin[18] - ((pin[6] * 4) + (pin[7] * 2) + (pin[13] * 3) + (pin[16] * 2) + pin[17]);
  assign pout[12] = (pin[6] * 4) + (pin[8] * 2) + (pin[12] * 9) + (pin[16] * 2) + pin[18] - ((pin[7] * 6) + (pin[11] * 6) + (pin[13] * 3) + (pin[17] * 3));
  assign pout[13] = (pin[8] * 2) + (pin[11] * 3) + pin[18] - ((pin[6] * 2) + (pin[13] * 3) + pin[16]);
  assign pout[14] = (pin[6] * 4) + (pin[9] * 2) + (pin[12] * 3) + (pin[13] * 6) + (pin[16] * 2) + pin[19] - ((pin[7] * 2) + (pin[8] * 4) + (pin[11] * 6) + (pin[14] * 3) + pin[17] + (pin[18] * 2));
  assign pout[15] = pin[6] + (pin[7] * 2) + (pin[15] * 2) + pin[18] - ((pin[5] * 2) + pin[8] + pin[16] + (pin[17] * 2));
  assign pout[16] = (pin[6] * 2) + pin[7] + pin[18] - (pin[8] + (pin[16] * 2) + pin[17]);
  assign pout[17] = (pin[7] * 3) + (pin[16] * 2) + pin[18] - ((pin[6] * 2) + pin[8] + (pin[17] * 3));
  assign pout[18] = pin[6] + pin[18] - (pin[8] + pin[16]);
  assign pout[19] = pin[7] + (pin[8] * 2) + (pin[16] * 2) + pin[19] - ((pin[6] * 2) + pin[9] + pin[17] + (pin[18] * 2));
  assign pout[20] = (pin[5] * 4) + (pin[8] * 2) + pin[11] + (pin[12] * 2) + (pin[16] * 2) + (pin[17] * 4) + (pin[20] * 2) + pin[23] - ((pin[6] * 2) + (pin[7] * 4) + (pin[10] * 2) + pin[13] + (pin[15] * 4) + (pin[18] * 2) + pin[21] + (pin[22] * 2));
  assign pout[21] = (pin[8] * 2) + (pin[11] * 2) + pin[12] + (pin[16] * 4) + (pin[17] * 2) + pin[23] - ((pin[6] * 4) + (pin[7] * 2) + pin[13] + (pin[18] * 2) + (pin[21] * 2) + pin[22]);
  assign pout[22] = (pin[6] * 4) + (pin[8] * 2) + (pin[12] * 3) + (pin[17] * 6) + (pin[21] * 2) + pin[23] - ((pin[7] * 6) + (pin[11] * 2) + pin[13] + (pin[16] * 4) + (pin[18] * 2) + (pin[22] * 3));
  assign pout[23] = (pin[8] * 2) + pin[11] + (pin[16] * 2) + pin[23] - ((pin[6] * 2) + pin[13] + (pin[18] * 2) + pin[21]);
  assign pout[24] = (pin[6] * 4) + (pin[9] * 2) + pin[12] + (pin[13] * 2) + (pin[17] * 2) + (pin[18] * 4) + (pin[21] * 2) + pin[24] - ((pin[7] * 2) + (pin[8] * 4) + (pin[11] * 2) + pin[14] + (pin[16] * 4) + (pin[19] * 2) + pin[22] + (pin[23] * 2));
endmodule
