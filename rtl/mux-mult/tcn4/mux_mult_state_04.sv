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
      MULT0: begin idx[0]=0; idx[1]=1; idx[2]=2; idx[3]=3; end
      MULT1: begin idx[0]=4; idx[1]=5; idx[2]=6; idx[3]=7; end
      MULT2: begin idx[0]=8; idx[1]=9; idx[2]=10; idx[3]=11; end
      MULT3: begin idx[0]=12; idx[1]=13; idx[2]=14; idx[3]=15; end
    default: begin end
    endcase
  end

endmodule
