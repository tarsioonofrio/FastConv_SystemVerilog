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
      default: begin idx[0]=0; idx[1]=1; end
      MULT1: begin idx[0]=2; idx[1]=3; end
      MULT2: begin idx[0]=4; idx[1]=5; end
      MULT3: begin idx[0]=6; idx[1]=7; end
      MULT4: begin idx[0]=8; idx[1]=9; end
      MULT5: begin idx[0]=10; idx[1]=11; end
      MULT6: begin idx[0]=12; idx[1]=13; end
      MULT7: begin idx[0]=14; idx[1]=15; end
      MULT8: begin idx[0]=16; idx[1]=17; end
      MULT9: begin idx[0]=18; idx[1]=19; end
      MULT10: begin idx[0]=20; idx[1]=21; end
      MULT11: begin idx[0]=22; idx[1]=23; end
      MULT12: begin idx[0]=24; idx[1]=25; end
      MULT13: begin idx[0]=26; idx[1]=27; end
      MULT14: begin idx[0]=28; idx[1]=29; end
      MULT15: begin idx[0]=30; idx[1]=31; end
      MULT16: begin idx[0]=32; idx[1]=33; end
      MULT17: begin idx[0]=34; idx[1]=35; end
    endcase
  end

endmodule
