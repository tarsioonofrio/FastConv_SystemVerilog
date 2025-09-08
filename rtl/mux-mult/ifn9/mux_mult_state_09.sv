//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

module MuxMult
  import packConv::*;
  (
    input  state_type current_st,  // current state
    output logic[5:0] idx[0:NMULT-1]    // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (current_st)
      default: begin idx[0]=0; idx[1]=1; idx[2]=2; idx[3]=3; idx[4]=4; idx[5]=5; idx[6]=6; idx[7]=7; idx[8]=8; end
      MULT1: begin idx[0]=9; idx[1]=10; idx[2]=11; idx[3]=12; idx[4]=13; idx[5]=14; idx[6]=15; idx[7]=16; idx[8]=17; end
      MULT2: begin idx[0]=18; idx[1]=19; idx[2]=20; idx[3]=21; idx[4]=22; idx[5]=23; idx[6]=24; idx[7]=25; idx[8]=26; end
      MULT3: begin idx[0]=27; idx[1]=28; idx[2]=29; idx[3]=30; idx[4]=31; idx[5]=32; idx[6]=33; idx[7]=34; idx[8]=35; end
    endcase
  end

endmodule
