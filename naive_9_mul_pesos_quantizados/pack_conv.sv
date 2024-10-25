//-------------------------------------------------------------------------
// FERNANDO MORAES                                             October/2024
//-------------------------------------------------------------------------
package packConv;


  timeunit 1ns;
  timeprecision 1ps;
  

    parameter int NBITS = 20;   // 32 bits generate too large hardware!!

    typedef logic [NBITS-1:0] regC;

    // definitions for matrix multiplications
    typedef regC param25 [0:24];  // array with 25 parameters
    typedef regC param9  [0:8];   // array with  9 parameters
  

endpackage
