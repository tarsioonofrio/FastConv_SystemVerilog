//-------------------------------------------------------------------------
// FERNANDO MORAES                                          24/October/2024
//-------------------------------------------------------------------------
package packConv;

  timeunit 1ns;
  timeprecision 1ps;

  // parameter int NBITS = 20;

  parameter int NMULT = 6;
  parameter int SMULT = 6;

  localparam logic [5:0] addr [0:SMULT-1][0:NMULT-1] = '{
    '{  0,  1,  2,  3,  4,  5 },
    '{  6,  7,  8,  9, 10, 11 },
    '{ 12, 13, 14, 15, 16, 17 },
    '{ 18, 19, 20, 21, 22, 23 },
    '{ 24, 25, 26, 27, 28, 29 },
    '{ 30, 31, 32, 33, 34, 35 }
  };

  // MU[SMULT]
  typedef enum {MULT[6], WR_OUT, IDLE, WR_IFMAP, WR_MC} state_type;

endpackage
