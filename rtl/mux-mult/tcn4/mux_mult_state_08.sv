//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 8;
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
      default: begin idx[0]=0; idx[1]=1; idx[2]=2; idx[3]=3; idx[4]=4; idx[5]=5; idx[6]=6; idx[7]=7; end
      MULT1: begin idx[0]=8; idx[1]=9; idx[2]=10; idx[3]=11; idx[4]=12; idx[5]=13; idx[6]=14; idx[7]=15; end
    endcase
  end

endmodule
