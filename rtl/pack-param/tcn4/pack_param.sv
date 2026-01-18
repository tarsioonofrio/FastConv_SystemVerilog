package pack_param;

  timeunit 1ns;
  timeprecision 1ps;

  localparam int A1_SIZE = 2;
  localparam int B1_SIZE = 3;
  localparam int C1_SIZE = 4;
  localparam int M1_SIZE = 4;
  localparam int A2_SIZE = 2;
  localparam int B2_SIZE = 3;
  localparam int C2_SIZE = 4;
  localparam int M2_SIZE = 4;
  const int c_index[16] = '{
    0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15
  };

endpackage
