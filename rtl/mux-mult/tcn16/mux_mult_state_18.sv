//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 18;
  parameter int SMULT = 2;
endpackage


module MuxMult
  import pack_mux_mult::*;
  (
    input  state_type current_st,  // current state
    output logic[5:0] idx[0:NMULT-1]    // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (current_st)
      default: begin idx[0]=0; idx[1]=1; idx[2]=2; idx[3]=3; idx[4]=4; idx[5]=5; idx[6]=6; idx[7]=7; idx[8]=8; idx[9]=9; idx[10]=10; idx[11]=11; idx[12]=12; idx[13]=13; idx[14]=14; idx[15]=15; idx[16]=16; idx[17]=17; end
      MULT1: begin idx[0]=18; idx[1]=19; idx[2]=20; idx[3]=21; idx[4]=22; idx[5]=23; idx[6]=24; idx[7]=25; idx[8]=26; idx[9]=27; idx[10]=28; idx[11]=29; idx[12]=30; idx[13]=31; idx[14]=32; idx[15]=33; idx[16]=34; idx[17]=35; end
    endcase
  end

endmodule
