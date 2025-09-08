package data;

  timeunit 1ns;
  timeprecision 1ps;

  localparam int QUANT_BITS = 8;
  localparam int W1_SIZE = 1;
  localparam int W2_SIZE = 16;
  localparam int FIN1_SIZE = 1;
  localparam int FIN2_SIZE = 16;
  localparam int FOUT1_SIZE = 1;
  localparam int FOUT2_SIZE = 4;

  const int const_weight[1][16] = '{
    '{0, -384, -128, -512, -1152, 2304, 768, 1920, -384, 768, 256, 640, -1536, 2688, 896, 2048}
  };

  const int const_feat_in[1][16] = '{
    '{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
  };

  const int const_feat_out[1][4] = '{
    '{258, 294, 402, 438}
  };

endpackage
