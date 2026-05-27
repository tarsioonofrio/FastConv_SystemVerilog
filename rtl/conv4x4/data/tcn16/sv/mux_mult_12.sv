//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 12;
  parameter int SMULT = 3;
endpackage


module MuxMult
  (
    input  logic[$clog2(3-1):0] idx_in, // current state
    output logic[$clog2(3*12-1):0] idx_out[0:12-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; idx_out[8]=8; idx_out[9]=9; idx_out[10]=10; idx_out[11]=11; end
      1: begin idx_out[0]=12; idx_out[1]=13; idx_out[2]=14; idx_out[3]=15; idx_out[4]=16; idx_out[5]=17; idx_out[6]=18; idx_out[7]=19; idx_out[8]=20; idx_out[9]=21; idx_out[10]=22; idx_out[11]=23; end
      2: begin idx_out[0]=24; idx_out[1]=25; idx_out[2]=26; idx_out[3]=27; idx_out[4]=28; idx_out[5]=29; idx_out[6]=30; idx_out[7]=31; idx_out[8]=32; idx_out[9]=33; idx_out[10]=34; idx_out[11]=35; end
    endcase
  end

endmodule
