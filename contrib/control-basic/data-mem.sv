package data;

  timeunit 1ns;
  timeprecision 1ps;

  localparam int QUANT_BITS = 8;
  localparam int W1_SIZE = 1;
  localparam int W2_SIZE = 36;
  localparam int FIN1_SIZE = 1;
  localparam int FIN2_SIZE = 25;
  localparam int FOUT1_SIZE = 1;
  localparam int FOUT2_SIZE = 9;
  localparam int A1_SIZE = 3;
  localparam int B1_SIZE = 3;
  localparam int C1_SIZE = 5;
  localparam int M1_SIZE = 6;
  localparam int A2_SIZE = 3;
  localparam int B2_SIZE = 3;
  localparam int C2_SIZE = 5;
  localparam int M2_SIZE = 6;


  const int const_data[] = '{
    0,
    0,  256,  512,  256,  512,  768,  768, 1024, 1280, 1792, 2048, 2304, 1536, 1792, 2048, 3328, 3584, 3840,  768, 1280, 1792, 2048, 2560, 3072, 1536, 2048, 2560, 3584, 4096, 4608, 2304, 2816, 3328, 5120, 5632, 6144,
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24
  };

  const int const_feat_out[1][9] = '{
    '{312, 348, 384, 492, 528, 564, 672, 708, 744}
  };

endpackage
