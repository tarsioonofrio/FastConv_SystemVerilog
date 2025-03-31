//-------------------------------------------------------------------------
// FERNANDO MORAES                                             October/2024
//-------------------------------------------------------------------------
package packConv;

  timeunit 1ns;
  timeprecision 1ps;
  

  parameter int NBITS = 20;   // 32 bits generate too large hardware!!

  typedef logic [NBITS-1:0] logic_vector;

  // definitions for matrix multiplications
  typedef logic_vector[16:0] logic_vector16;  // array with 16 parameters
  typedef logic_vector[08:0] logic_vector8;     // array with  8 parameters
  typedef logic_vector[04:0] logic_vector4;     // array with  4 parameters

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
