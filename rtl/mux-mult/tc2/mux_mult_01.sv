//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 1;
  parameter int SMULT = 4;
endpackage


module MuxMult
  (
    input  logic[$clog2(1-1):0] idx_in, // current state
    output logic[$clog2(1*1-1):0] idx_out[0:1-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; end
      1: begin idx_out[0]=1; end
      2: begin idx_out[0]=2; end
      3: begin idx_out[0]=3; end
    endcase
  end

endmodule
