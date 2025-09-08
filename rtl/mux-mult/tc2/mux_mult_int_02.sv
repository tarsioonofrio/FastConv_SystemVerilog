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
    input  logic[6:0] idx_in, // current state
    output logic[6:0] idx_out[0:NMULT-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; end
      MULT1: begin idx_out[0]=2; idx_out[1]=3; end
    endcase
  end

endmodule
