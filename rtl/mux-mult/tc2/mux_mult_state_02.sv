//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 2;
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
      default: begin idx[0]=0; idx[1]=1; end
      MULT1: begin idx[0]=2; idx[1]=3; end
    endcase
  end

endmodule
