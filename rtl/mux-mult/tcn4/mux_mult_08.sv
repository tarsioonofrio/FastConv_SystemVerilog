//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 8;
  parameter int SMULT = 2;
endpackage


module MuxMult
  (
    input  logic[$clog2(2-1):0] idx_in, // current state
    output logic[$clog2(2*8-1):0] idx_out[0:8-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; end
      1: begin idx_out[0]=8; idx_out[1]=9; idx_out[2]=10; idx_out[3]=11; idx_out[4]=12; idx_out[5]=13; idx_out[6]=14; idx_out[7]=15; end
    endcase
  end

endmodule
