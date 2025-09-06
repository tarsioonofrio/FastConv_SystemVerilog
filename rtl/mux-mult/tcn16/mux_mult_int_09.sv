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
      0: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; idx_out[8]=8; end
      1: begin idx_out[0]=9; idx_out[1]=10; idx_out[2]=11; idx_out[3]=12; idx_out[4]=13; idx_out[5]=14; idx_out[6]=15; idx_out[7]=16; idx_out[8]=17; end
      2: begin idx_out[0]=18; idx_out[1]=19; idx_out[2]=20; idx_out[3]=21; idx_out[4]=22; idx_out[5]=23; idx_out[6]=24; idx_out[7]=25; idx_out[8]=26; end
      3: begin idx_out[0]=27; idx_out[1]=28; idx_out[2]=29; idx_out[3]=30; idx_out[4]=31; idx_out[5]=32; idx_out[6]=33; idx_out[7]=34; idx_out[8]=35; end
    default: begin end
    endcase
  end

endmodule
