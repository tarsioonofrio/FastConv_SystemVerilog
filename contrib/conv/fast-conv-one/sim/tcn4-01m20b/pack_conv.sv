//-------------------------------------------------------------------------
// FERNANDO MORAES                                             October/2024
//-------------------------------------------------------------------------
package packConv;
  import data::*;

  timeunit 1ns;
  timeprecision 1ps;


  parameter int NBITS = 20;   // 32 bits generate too large hardware!!

  typedef enum {MULT[16], WR_OUT, IDLE, WR_IFMAP, WR_MC} state_type;


  typedef logic [NBITS-1:0] logic_vector;

  // definitions for matrix multiplications
  typedef logic_vector type_input    [C1_SIZE*C1_SIZE-1:0];  // array with 16 parameters
  typedef logic_vector type_output   [A1_SIZE*A1_SIZE-1:0];     // array with  4 parameters
  typedef logic_vector type_weight   [M1_SIZE*M1_SIZE-1:0];     // array with 16 parameters
  typedef logic_vector type_matrix_c [C1_SIZE*M1_SIZE-1:0];     // array with 16 parameters
  typedef logic_vector type_matrix_a [C1_SIZE*M1_SIZE-1:0];     // array with  8 parameters

  // definitions for the CSA adders
  typedef logic_vector[1:0] two_words   ;
  typedef logic_vector[3:0] four_words  ;
  typedef logic_vector[5:0] six_words   ;
  typedef logic_vector[7:0] eight_words ;
  typedef logic_vector[9:0] ten_words   ;
endpackage
