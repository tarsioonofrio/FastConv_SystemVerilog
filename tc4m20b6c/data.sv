package data;

  timeunit 1ns;
  timeprecision 1ps;

  localparam int QUANT_BITS = 8;
  localparam int A1_SIZE = 2;
  localparam int B1_SIZE = 3;
  localparam int C1_SIZE = 4;
  localparam int M1_SIZE = 4;
  localparam int A2_SIZE = 2;
  localparam int B2_SIZE = 3;
  localparam int C2_SIZE = 4;
  localparam int M2_SIZE = 4;

  const int const_weight[][] = '{
    '{0, -384, -128, -512, -1152, 2304, 768, 1920, -384, 768, 256, 640, -1536, 2688, 896, 2048}
  };

  const int const_feat_in[][] = '{
    '{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
  };

  const int const_feat_out[][] = '{
    '{258, 294, 402, 438}
  };

endpackage
