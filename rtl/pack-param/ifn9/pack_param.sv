package pack_param;

  timeunit 1ns;
  timeprecision 1ps;

  localparam int CONV_OUTPUT_SIZE = 3;
  localparam int CONV_KERNEL_SIZE = 3;
  localparam int CONV_INPUT_SIZE = 5;
  localparam int HADAMARD_SIZE = 6;
  const int c_index[25] = '{
    0, 5, 10, 15, 20, 1, 6, 11, 16, 21, 2, 7, 12, 17, 22, 3, 8, 13, 18, 23, 4, 9, 14, 19, 24
  };

endpackage
