//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 2;
  parameter int SMULT = 3;
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
      2: begin idx_out[0]=4; idx_out[1]=5; end
    endcase
  end

endmodule
