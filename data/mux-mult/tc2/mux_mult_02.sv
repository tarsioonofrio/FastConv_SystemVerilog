//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 2;
  parameter int STATE_MULT = 2;
endpackage


module MuxMult
  (
    input  logic[$clog2(2-1):0] idx_in, // current state
    output logic[$clog2(2*2-1):0] idx_out[0:2-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; end
      1: begin idx_out[0]=2; idx_out[1]=3; end
    endcase
  end

endmodule
