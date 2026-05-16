package pack_param;

  timeunit 1ns;
  timeprecision 1ps;

  localparam int TRANSFORM_SIZE = 3;
  localparam int KERNEL_SIZE = 3;
  localparam int INVERSE_SIZE = 5;
  localparam int HADAMARD_SIZE = 5;
  const int c_index[25] = '{
    0, 5, 10, 15, 20, 1, 6, 11, 16, 21, 2, 7, 12, 17, 22, 3, 8, 13, 18, 23, 4, 9, 14, 19, 24
  };

endpackage
