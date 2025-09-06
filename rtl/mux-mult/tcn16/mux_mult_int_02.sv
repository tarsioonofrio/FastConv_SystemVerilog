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
      0: begin idx[0]=0; idx[1]=1; end
      1: begin idx[0]=2; idx[1]=3; end
      2: begin idx[0]=4; idx[1]=5; end
      3: begin idx[0]=6; idx[1]=7; end
      4: begin idx[0]=8; idx[1]=9; end
      5: begin idx[0]=10; idx[1]=11; end
      6: begin idx[0]=12; idx[1]=13; end
      7: begin idx[0]=14; idx[1]=15; end
      8: begin idx[0]=16; idx[1]=17; end
      9: begin idx[0]=18; idx[1]=19; end
      10: begin idx[0]=20; idx[1]=21; end
      11: begin idx[0]=22; idx[1]=23; end
      12: begin idx[0]=24; idx[1]=25; end
      13: begin idx[0]=26; idx[1]=27; end
      14: begin idx[0]=28; idx[1]=29; end
      15: begin idx[0]=30; idx[1]=31; end
      16: begin idx[0]=32; idx[1]=33; end
      17: begin idx[0]=34; idx[1]=35; end
    default: begin end
    endcase
  end

endmodule
