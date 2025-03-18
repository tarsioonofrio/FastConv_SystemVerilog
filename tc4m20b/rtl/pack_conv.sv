//-------------------------------------------------------------------------
// FERNANDO MORAES                                             October/2024
//-------------------------------------------------------------------------
package packConv;


  timeunit 1ns;
  timeprecision 1ps;
  

    parameter int NBITS = 20;   // 32 bits generate too large hardware!!

    typedef logic [NBITS-1:0] regC;

    // definitions for matrix multiplications
    typedef regC param16 [0:16];  // array with 16 parameters
    typedef regC param8  [0:8];   // array with  8 parameters
    typedef regC param4  [0:4];   // array with  4 parameters
  
    // definitions for the CSA adders
    typedef regC two_words    [1:0];
    typedef regC four_words   [3:0];
    typedef regC six_words    [5:0];
    typedef regC eight_words  [7:0];
    typedef regC ten_words    [9:0];
  
    // constants to control the multipliers
    typedef enum  {
        MU1, MU2, MU3, MU4
    } mul_states;

endpackage
