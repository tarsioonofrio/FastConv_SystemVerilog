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
      0: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; end
      1: begin idx_out[0]=4; idx_out[1]=5; idx_out[2]=6; idx_out[3]=7; end
      2: begin idx_out[0]=8; idx_out[1]=9; idx_out[2]=10; idx_out[3]=11; end
      3: begin idx_out[0]=12; idx_out[1]=13; idx_out[2]=14; idx_out[3]=15; end
    default: begin end
    endcase
  end

endmodule
