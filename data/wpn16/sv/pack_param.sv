package pack_param;

  timeunit 1ns;
  timeprecision 1ps;

  localparam int A1_SIZE = 4;
  localparam int B1_SIZE = 3;
  localparam int C1_SIZE = 6;
  localparam int M1_SIZE = 8;
  localparam int A2_SIZE = 4;
  localparam int B2_SIZE = 3;
  localparam int C2_SIZE = 6;
  localparam int M2_SIZE = 8;
  const int c_index[36] = '{
    0, 6, 12, 18, 24, 30, 1, 7, 13, 19, 25, 31, 2, 8, 14, 20, 26, 32, 3, 9, 15, 21, 27, 33, 4, 10, 16, 22, 28, 34, 5, 11, 17, 23, 29, 35
  };

endpackage
