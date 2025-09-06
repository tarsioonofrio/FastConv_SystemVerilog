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
      0: begin idx[0]=0; idx[1]=1; idx[2]=2; idx[3]=3; idx[4]=4; end
      1: begin idx[0]=5; idx[1]=6; idx[2]=7; idx[3]=8; idx[4]=9; end
      2: begin idx[0]=10; idx[1]=11; idx[2]=12; idx[3]=13; idx[4]=14; end
      3: begin idx[0]=15; idx[1]=16; idx[2]=17; idx[3]=18; idx[4]=19; end
      4: begin idx[0]=20; idx[1]=21; idx[2]=22; idx[3]=23; idx[4]=24; end
    default: begin end
    endcase
  end

endmodule
