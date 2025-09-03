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
      MULT0: begin idx[0]=0; idx[1]=1; idx[2]=2; idx[3]=3; idx[4]=4; idx[5]=5; idx[6]=6; idx[7]=7; idx[8]=8; idx[9]=9; idx[10]=10; idx[11]=11; idx[12]=12; idx[13]=13; idx[14]=14; idx[15]=15; end
    default: begin end
    endcase
  end

endmodule
