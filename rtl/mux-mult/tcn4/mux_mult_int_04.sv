//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 4;
  parameter int SMULT = 4;
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
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; end
      MULT1: begin idx_out[0]=4; idx_out[1]=5; idx_out[2]=6; idx_out[3]=7; end
      MULT2: begin idx_out[0]=8; idx_out[1]=9; idx_out[2]=10; idx_out[3]=11; end
      MULT3: begin idx_out[0]=12; idx_out[1]=13; idx_out[2]=14; idx_out[3]=15; end
    endcase
  end

endmodule
