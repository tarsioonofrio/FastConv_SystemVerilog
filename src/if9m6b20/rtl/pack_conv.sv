//-------------------------------------------------------------------------
// FERNANDO MORAES                                          24/October/2024
//-------------------------------------------------------------------------
package packConv;

  timeunit 1ns;
  timeprecision 1ps;
  
    parameter int NBITS = 20;  

    typedef logic [NBITS-1:0] logic_vector;

    // definitions for matrix multiplications
    typedef logic_vector logic_vector36 [35:0];   
    typedef logic_vector logic_vector25 [24:0];  
    typedef logic_vector logic_vector9  [8:0];  
  
    // definitions for the CSA adders
    typedef logic_vector [1:0] two_words;
    typedef logic_vector [3:0] four_words;
    typedef logic_vector [5:0] six_words;
    typedef logic_vector [7:0] eight_words;
    typedef logic_vector [9:0] ten_words;

endpackage
