//-------------------------------------------------------------------------
// FERNANDO MORAES                                             October/2024
//-------------------------------------------------------------------------
package packConv;


  timeunit 1ns;
  timeprecision 1ps;
  

    parameter int NBITS = 20;   // 32 bits generate too large hardware!!

    typedef logic [NBITS-1:0] logic_vector;

    // definitions for matrix multiplications
    typedef logic_vector type_input [0:24];  // array with 25 parameters
    typedef logic_vector type_output  [0:8];   // array with  9 parameters
    typedef logic_vector type_weight  [0:8];   // array with  9 parameters
  

endpackage
