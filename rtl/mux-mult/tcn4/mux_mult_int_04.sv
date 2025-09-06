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
      0: begin idx[0]=0; idx[1]=1; idx[2]=2; idx[3]=3; end
      1: begin idx[0]=4; idx[1]=5; idx[2]=6; idx[3]=7; end
      2: begin idx[0]=8; idx[1]=9; idx[2]=10; idx[3]=11; end
      3: begin idx[0]=12; idx[1]=13; idx[2]=14; idx[3]=15; end
    default: begin end
    endcase
  end

endmodule
