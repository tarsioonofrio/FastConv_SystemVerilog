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
      0: begin idx_out[0]=0; idx_out[1]=1; end
      1: begin idx_out[0]=2; idx_out[1]=3; end
      2: begin idx_out[0]=4; idx_out[1]=5; end
      3: begin idx_out[0]=6; idx_out[1]=7; end
      4: begin idx_out[0]=8; idx_out[1]=9; end
      5: begin idx_out[0]=10; idx_out[1]=11; end
      6: begin idx_out[0]=12; idx_out[1]=13; end
      7: begin idx_out[0]=14; idx_out[1]=15; end
    default: begin end
    endcase
  end

endmodule
