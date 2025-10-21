//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 6;
  parameter int SMULT = 1;
endpackage


module MuxMult
  (
    input  logic[$clog2(1-1):0] idx_in, // current state
    output logic[$clog2(1*6-1):0] idx_out[0:6-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; end
    endcase
  end

endmodule
