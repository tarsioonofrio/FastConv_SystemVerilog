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
      default: begin idx[0]=0; idx[1]=1; idx[2]=2; idx[3]=3; idx[4]=4; idx[5]=5; idx[6]=6; idx[7]=7; idx[8]=8; idx[9]=9; idx[10]=10; idx[11]=11; end
      MULT1: begin idx[0]=12; idx[1]=13; idx[2]=14; idx[3]=15; idx[4]=16; idx[5]=17; idx[6]=18; idx[7]=19; idx[8]=20; idx[9]=21; idx[10]=22; idx[11]=23; end
      MULT2: begin idx[0]=24; idx[1]=25; idx[2]=26; idx[3]=27; idx[4]=28; idx[5]=29; idx[6]=30; idx[7]=31; idx[8]=32; idx[9]=33; idx[10]=34; idx[11]=35; end
    endcase
  end

endmodule
