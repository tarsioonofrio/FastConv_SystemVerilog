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
      default: begin idx[0]=0; idx[1]=1; idx[2]=2; idx[3]=3; idx[4]=4; idx[5]=5; end
      MULT1: begin idx[0]=6; idx[1]=7; idx[2]=8; idx[3]=9; idx[4]=10; idx[5]=11; end
      MULT2: begin idx[0]=12; idx[1]=13; idx[2]=14; idx[3]=15; idx[4]=16; idx[5]=17; end
      MULT3: begin idx[0]=18; idx[1]=19; idx[2]=20; idx[3]=21; idx[4]=22; idx[5]=23; end
      MULT4: begin idx[0]=24; idx[1]=25; idx[2]=26; idx[3]=27; idx[4]=28; idx[5]=29; end
      MULT5: begin idx[0]=30; idx[1]=31; idx[2]=32; idx[3]=33; idx[4]=34; idx[5]=35; end
    endcase
  end

endmodule
