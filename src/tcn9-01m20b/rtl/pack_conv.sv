//-------------------------------------------------------------------------
// FERNANDO MORAES                                             October/2024
//-------------------------------------------------------------------------
package packConv;
  import data::*;

  timeunit 1ns;
  timeprecision 1ps;

  parameter int NBITS = 20;   // 32 bits generate too large hardware!!
  // MU[SMULT]
  typedef enum {MU[25], WR_OUT, IDLE, WR_IFMAP, WR_MC} state_type;

  typedef logic [NBITS-1:0] logic_vector;

  // definitions for matrix multiplications
  typedef logic_vector type_input    [0:C1_SIZE*C1_SIZE];  // array with 16 parameters
  typedef logic_vector type_output   [0:A1_SIZE*A1_SIZE];     // array with  4 parameters
  typedef logic_vector type_weight   [0:M1_SIZE*M1_SIZE];     // array with 16 parameters
  typedef logic_vector type_matrix_c [0:C1_SIZE*M1_SIZE];     // array with 16 parameters
  typedef logic_vector type_matrix_a [0:C1_SIZE*M1_SIZE];     // array with  8 parameters

  // definitions for the CSA adders
  typedef logic_vector two_words    [1:0];
  typedef logic_vector four_words   [3:0];
  typedef logic_vector six_words    [5:0];
  typedef logic_vector eight_words  [7:0];
  typedef logic_vector ten_words    [9:0];

endpackage
