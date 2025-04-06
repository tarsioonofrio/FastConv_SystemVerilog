//-------------------------------------------------------------------------
// FERNANDO MORAES                                             October/2024
//-------------------------------------------------------------------------
package packConv;


  timeunit 1ns;
  timeprecision 1ps;


    parameter int NBITS = 20;   // 32 bits generate too large hardware!!

    typedef logic [NBITS-1:0] logic_vector;

    // definitions for matrix multiplications
    typedef logic_vector type_input  [0:24];  // array with 25 parameters
    typedef logic_vector type_weight [0:24];  // array with 25 parameters
    typedef logic_vector type_output [0:8];   // array with  9 parameters

    // definitions for the CSA adders
    typedef logic_vector two_words  [1:0];
    typedef logic_vector four_words [3:0];
    typedef logic_vector six_words  [5:0];
    typedef logic_vector ten_words  [9:0];

    // constants to control the multipliers
    typedef enum logic [1:0] {
        ALBL, ALBH, AHBL, AHBH
    } mul_states;

endpackage
