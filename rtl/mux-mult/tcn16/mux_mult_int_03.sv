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
      0: begin idx[0]=0; idx[1]=1; idx[2]=2; end
      1: begin idx[0]=3; idx[1]=4; idx[2]=5; end
      2: begin idx[0]=6; idx[1]=7; idx[2]=8; end
      3: begin idx[0]=9; idx[1]=10; idx[2]=11; end
      4: begin idx[0]=12; idx[1]=13; idx[2]=14; end
      5: begin idx[0]=15; idx[1]=16; idx[2]=17; end
      6: begin idx[0]=18; idx[1]=19; idx[2]=20; end
      7: begin idx[0]=21; idx[1]=22; idx[2]=23; end
      8: begin idx[0]=24; idx[1]=25; idx[2]=26; end
      9: begin idx[0]=27; idx[1]=28; idx[2]=29; end
      10: begin idx[0]=30; idx[1]=31; idx[2]=32; end
      11: begin idx[0]=33; idx[1]=34; idx[2]=35; end
    default: begin end
    endcase
  end

endmodule
