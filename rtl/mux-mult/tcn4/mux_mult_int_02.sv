//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

module MuxMult
  import packConv::*;
(
  input  state_type current_st,  // current state
  output logic[5:0] idx[0:NMULT-1]    // index array output
);

  always_comb begin
    unique case (current_st)
      0: begin idx[0]=0; idx[1]=1; end
      1: begin idx[0]=2; idx[1]=3; end
      2: begin idx[0]=4; idx[1]=5; end
      3: begin idx[0]=6; idx[1]=7; end
      4: begin idx[0]=8; idx[1]=9; end
      5: begin idx[0]=10; idx[1]=11; end
      6: begin idx[0]=12; idx[1]=13; end
      7: begin idx[0]=14; idx[1]=15; end
    default: begin end
    endcase
  end

endmodule
