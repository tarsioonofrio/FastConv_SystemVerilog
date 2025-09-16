//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 18;
  parameter int SMULT = 2;
endpackage


module MuxMult
  (
    input  logic[$clog2(18-1):0] idx_in, // current state
    output logic[$clog2(18*18-1):0] idx_out[0:18-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; idx_out[8]=8; idx_out[9]=9; idx_out[10]=10; idx_out[11]=11; idx_out[12]=12; idx_out[13]=13; idx_out[14]=14; idx_out[15]=15; idx_out[16]=16; idx_out[17]=17; end
      1: begin idx_out[0]=18; idx_out[1]=19; idx_out[2]=20; idx_out[3]=21; idx_out[4]=22; idx_out[5]=23; idx_out[6]=24; idx_out[7]=25; idx_out[8]=26; idx_out[9]=27; idx_out[10]=28; idx_out[11]=29; idx_out[12]=30; idx_out[13]=31; idx_out[14]=32; idx_out[15]=33; idx_out[16]=34; idx_out[17]=35; end
    endcase
  end

endmodule
