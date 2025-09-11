package pack_sim;

  timeunit 1ns;
  timeprecision 1ps;

  localparam int QUANT_BITS = 8;
  localparam int W1_SIZE = 1;
  localparam int W2_SIZE = 36;
  localparam int FIN1_SIZE = 64;
  localparam int FIN2_SIZE = 36;
  localparam int FOUT1_SIZE = 64;
  localparam int FOUT2_SIZE = 16;

  const int const_weight[1][36] = '{
    '{0, -11, 11, 5, -5, 0, -11, 0, 28, -2, -16, -43, 11, 28, -57, -12, 30, 43, 5, -2, -12, 2, 7, 21, -5, -16, 30, 7, -16, -21, 0, -43, 43, 21, -21, 0}
  };
  const int const_feat_in[64][36] = '{
    '{118, 120, 124, 118, 122, 116, 119, 125, 127, 122, 120, 121, 122, 126, 127, 121, 125, 126, 135, 136, 133, 126, 125, 124, 129, 131, 124, 130, 133, 132, 136, 135, 135, 137, 139, 138},
  };
  const int const_feat_out[64][16] = '{
    '{-21, -10, -30, 4, 3, -3, 9, -14, -47, -17, -53, 0, -15, 21, -39, -32},
  };

endpackage
