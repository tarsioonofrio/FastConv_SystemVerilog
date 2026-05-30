package data;

  timeunit 1ns;
  timeprecision 1ps;

  localparam int QUANT_BITS = 8;
  localparam int W1_SIZE = 1;
  localparam int W2_SIZE = 25;
  localparam int FIN1_SIZE = 1;
  localparam int FIN2_SIZE = 25;
  localparam int FOUT1_SIZE = 1;
  localparam int FOUT2_SIZE = 9;

  const int const_weight[1][25] = '{
    '{0, -192, -22, 213, 256, -576, 2304, 256, -1984, -1920, -64, 256, 28, -221, -214, 640, -2368, -264, 1991, 1877, 768, -2688, -299, 2218, 2048}
  };
  const int const_feat_in[1][25] = '{
    '{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24}
  };

  const int const_feat_out[1][9] = '{
    '{312, 348, 384, 492, 528, 564, 672, 708, 744}
  };
endpackage
