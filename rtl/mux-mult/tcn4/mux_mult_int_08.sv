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
      0: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; end
      1: begin idx_out[0]=8; idx_out[1]=9; idx_out[2]=10; idx_out[3]=11; idx_out[4]=12; idx_out[5]=13; idx_out[6]=14; idx_out[7]=15; end
    default: begin end
    endcase
  end

endmodule
