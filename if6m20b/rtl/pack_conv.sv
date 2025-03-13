//-------------------------------------------------------------------------
// FERNANDO MORAES                                          24/October/2024
//-------------------------------------------------------------------------
package packConv;

  timeunit 1ns;
  timeprecision 1ps;
  
    parameter int NBITS = 20;  

    typedef logic [NBITS-1:0] regC;

    // definitions for matrix multiplications
    typedef regC [35:0] param36;   
    typedef regC [24:0] param25 ;  
    typedef regC [8:0] param9;  
  
    // definitions for the CSA adders
    typedef regC [1:0] two_words;
    typedef regC [3:0] four_words;
    typedef regC [5:0] six_words;
    typedef regC [7:0] eight_words;
    typedef regC [9:0] ten_words;

endpackage
