//-------------------------------------------------------------------------
// FERNANDO MORAES                                             October/2024
//-------------------------------------------------------------------------
package packConv;
  import data::*;

  timeunit 1ns;
  timeprecision 1ps;


  parameter int NBITS = 20;   // 32 bits generate too large hardware!!

  typedef logic [NBITS-1:0] logic_vector;

  // definitions for matrix multiplications
  typedef logic_vector type_input    [0:C1_SIZE*C1_SIZE];  // array with 16 parameters
  typedef logic_vector type_output   [0:A1_SIZE*A1_SIZE];     // array with  4 parameters
  typedef logic_vector type_matrix_a [0:A1_SIZE*C1_SIZE];     // array with  8 parameters
  typedef logic_vector type_matrix_c [0:C1_SIZE*C1_SIZE];     // array with 16 parameters

  // definitions for the CSA adders
  typedef logic_vector[1:0] two_words   ;
  typedef logic_vector[3:0] four_words  ;
  typedef logic_vector[5:0] six_words   ;
  typedef logic_vector[7:0] eight_words ;
  typedef logic_vector[9:0] ten_words   ;

  // constants to control the multipliers
  typedef enum  {
      MU1, MU2, MU3, MU4
  } mul_states;

endpackage
