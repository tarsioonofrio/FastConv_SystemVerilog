//-------------------------------------------------------------------------
// FERNANDO MORAES                                          24/October/2024
//-------------------------------------------------------------------------
package packConv;
  import data::*;

  timeunit 1ns;
  timeprecision 1ps;

  parameter int NBITS = 20;
  
  parameter int NMULT = 1;
  parameter int SMULT = 36;

  // MU[SMULT]
  typedef enum {MU, WR_OUT, IDLE1, WR_MC} state_type_conv;


  typedef logic [NBITS-1:0] logic_vector;

  // definitions for matrix multiplications
  typedef logic_vector type_weight   [M1_SIZE*M2_SIZE-1:0];
  typedef logic_vector type_input    [C1_SIZE*C2_SIZE-1:0];
  typedef logic_vector type_output   [A1_SIZE*A2_SIZE-1:0];
  typedef logic_vector type_matrix_c [C1_SIZE*M1_SIZE-1:0];
  typedef logic_vector type_matrix_a [A1_SIZE*M1_SIZE-1:0];


  // definitions for the CSA adders
  typedef logic_vector [1:0] two_words;
  typedef logic_vector [3:0] four_words;
  typedef logic_vector [5:0] six_words;
  typedef logic_vector [7:0] eight_words;
  typedef logic_vector [9:0] ten_words;

endpackage
