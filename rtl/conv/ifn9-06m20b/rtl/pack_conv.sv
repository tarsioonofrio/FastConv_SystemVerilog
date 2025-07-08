//-------------------------------------------------------------------------
// FERNANDO MORAES                                          24/October/2024
//-------------------------------------------------------------------------
package packConv;
  import data::*;

  timeunit 1ns;
  timeprecision 1ps;

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
  typedef enum {MU[6], WR_OUT, IDLE, WR_IFMAP, WR_MC} state_type;

  parameter int NBITS = 20;

  typedef logic [NBITS-1:0] logic_vector;

  // definitions for matrix multiplications
  typedef logic_vector type_weight   [35:0];
  typedef logic_vector type_input    [24:0];
  typedef logic_vector type_output   [8:0];
  typedef logic_vector type_matrix_c [0:C1_SIZE*M1_SIZE];
  typedef logic_vector type_matrix_a [0:A1_SIZE*M1_SIZE];


  // definitions for the CSA adders
  typedef logic_vector [1:0] two_words;
  typedef logic_vector [3:0] four_words;
  typedef logic_vector [5:0] six_words;
  typedef logic_vector [7:0] eight_words;
  typedef logic_vector [9:0] ten_words;

endpackage
