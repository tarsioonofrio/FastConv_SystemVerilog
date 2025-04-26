//-------------------------------------------------------------------------
// FERNANDO MORAES                                             October/2024
//-------------------------------------------------------------------------
package packConv;


  timeunit 1ns;
  timeprecision 1ps;
  

    parameter int NBITS = 20;   // 32 bits generate too large hardware!!

    typedef logic [NBITS-1:0] logic_vector;

    // definitions for matrix multiplications
    typedef logic_vector type_input [0:16];  // array with 16 parameters
    typedef logic_vector type_weight [0:16];  // array with 16 parameters
    typedef logic_vector type_matrix  [0:8];   // array with  8 parameters
    typedef logic_vector type_output  [0:4];   // array with  4 parameters
  
    // definitions for the CSA adders
    typedef logic_vector two_words    [1:0];
    typedef logic_vector four_words   [3:0];
    typedef logic_vector six_words    [5:0];
    typedef logic_vector eight_words  [7:0];
    typedef logic_vector ten_words    [9:0];
  
    // constants to control the multipliers
    typedef enum  {
        MU1, MU2, MU3, MU4
    } mul_states;

endpackage
