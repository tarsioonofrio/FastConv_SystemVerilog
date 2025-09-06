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
    unique case (current_st)
      0: begin idx[0]=0; idx[1]=1; end
      1: begin idx[0]=2; idx[1]=3; end
      2: begin idx[0]=4; idx[1]=5; end
    default: begin end
    endcase
  end

endmodule
