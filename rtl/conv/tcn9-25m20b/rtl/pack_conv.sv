//-------------------------------------------------------------------------
// FERNANDO MORAES                                             October/2024
//-------------------------------------------------------------------------
package packConv;
  import data::*;

  timeunit 1ns;
  timeprecision 1ps;

  parameter int NBITS = 20;   // 32 bits generate too large hardware!!

  typedef enum {IDLE, WR_IFMAP, WR_MC, MU, WR_OUT} state_type;
  state_type current_st, next_st;

  typedef logic [NBITS-1:0] logic_vector;

  // definitions for matrix multiplications
  typedef logic_vector type_input    [C1_SIZE*C1_SIZE-1:0];  // array with 16 parameters
  typedef logic_vector type_output   [A1_SIZE*A1_SIZE-1:0];     // array with  4 parameters
  typedef logic_vector type_weight   [M1_SIZE*M1_SIZE-1:0];     // array with 16 parameters
  typedef logic_vector type_matrix_c [C1_SIZE*M1_SIZE-1:0];     // array with 16 parameters
  typedef logic_vector type_matrix_a [C1_SIZE*M1_SIZE-1:0];     // array with  8 parameters

  // definitions for the CSA adders
  typedef logic_vector two_words    [1:0];
  typedef logic_vector four_words   [3:0];
  typedef logic_vector six_words    [5:0];
  typedef logic_vector eight_words  [7:0];
  typedef logic_vector ten_words    [9:0];

endpackage
