package pack_param;

  timeunit 1ns;
  timeprecision 1ps;

  localparam int TRANSFORM_SIZE = 2;
  localparam int KERNEL_SIZE = 3;
  localparam int INVERSE_SIZE = 4;
  localparam int HADAMARD_SIZE = 4;
  const int c_index[16] = '{
    0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15
  };

endpackage
