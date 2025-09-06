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
      0: begin idx[0]=0; idx[1]=1; idx[2]=2; idx[3]=3; idx[4]=4; idx[5]=5; idx[6]=6; idx[7]=7; end
      1: begin idx[0]=8; idx[1]=9; idx[2]=10; idx[3]=11; idx[4]=12; idx[5]=13; idx[6]=14; idx[7]=15; end
    default: begin end
    endcase
  end

endmodule
