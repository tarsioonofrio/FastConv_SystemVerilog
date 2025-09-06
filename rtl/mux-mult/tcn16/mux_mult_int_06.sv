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
    unique case (idx_in)
      0: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; end
      1: begin idx_out[0]=6; idx_out[1]=7; idx_out[2]=8; idx_out[3]=9; idx_out[4]=10; idx_out[5]=11; end
      2: begin idx_out[0]=12; idx_out[1]=13; idx_out[2]=14; idx_out[3]=15; idx_out[4]=16; idx_out[5]=17; end
      3: begin idx_out[0]=18; idx_out[1]=19; idx_out[2]=20; idx_out[3]=21; idx_out[4]=22; idx_out[5]=23; end
      4: begin idx_out[0]=24; idx_out[1]=25; idx_out[2]=26; idx_out[3]=27; idx_out[4]=28; idx_out[5]=29; end
      5: begin idx_out[0]=30; idx_out[1]=31; idx_out[2]=32; idx_out[3]=33; idx_out[4]=34; idx_out[5]=35; end
    default: begin end
    endcase
  end

endmodule
