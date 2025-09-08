//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

module MuxMult
  import packConv::*;
  (
    input  logic[6:0] idx_in, // current state
    output logic[6:0] idx_out[0:NMULT-1]  // index array output
  );

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; end
      MULT1: begin idx_out[0]=2; idx_out[1]=3; end
      MULT2: begin idx_out[0]=4; idx_out[1]=5; end
    endcase
  end

endmodule
