//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 3;
  parameter int SMULT = 2;
endpackage


module MuxMult
  (
    input  logic[$clog2(3):0] idx_in, // current state
    output logic[$clog2(3):0] idx_out[0:3 - 1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; end
      1: begin idx_out[0]=3; idx_out[1]=4; idx_out[2]=5; end
    endcase
  end

endmodule
