//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 4;
  parameter int SMULT = 16;
endpackage


module MuxMult
  (
    input  logic[$clog2(16-1):0] idx_in, // current state
    output logic[$clog2(16*4-1):0] idx_out[0:4-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; end
      1: begin idx_out[0]=4; idx_out[1]=5; idx_out[2]=6; idx_out[3]=7; end
      2: begin idx_out[0]=8; idx_out[1]=9; idx_out[2]=10; idx_out[3]=11; end
      3: begin idx_out[0]=12; idx_out[1]=13; idx_out[2]=14; idx_out[3]=15; end
      4: begin idx_out[0]=16; idx_out[1]=17; idx_out[2]=18; idx_out[3]=19; end
      5: begin idx_out[0]=20; idx_out[1]=21; idx_out[2]=22; idx_out[3]=23; end
      6: begin idx_out[0]=24; idx_out[1]=25; idx_out[2]=26; idx_out[3]=27; end
      7: begin idx_out[0]=28; idx_out[1]=29; idx_out[2]=30; idx_out[3]=31; end
      8: begin idx_out[0]=32; idx_out[1]=33; idx_out[2]=34; idx_out[3]=35; end
      9: begin idx_out[0]=36; idx_out[1]=37; idx_out[2]=38; idx_out[3]=39; end
      10: begin idx_out[0]=40; idx_out[1]=41; idx_out[2]=42; idx_out[3]=43; end
      11: begin idx_out[0]=44; idx_out[1]=45; idx_out[2]=46; idx_out[3]=47; end
      12: begin idx_out[0]=48; idx_out[1]=49; idx_out[2]=50; idx_out[3]=51; end
      13: begin idx_out[0]=52; idx_out[1]=53; idx_out[2]=54; idx_out[3]=55; end
      14: begin idx_out[0]=56; idx_out[1]=57; idx_out[2]=58; idx_out[3]=59; end
      15: begin idx_out[0]=60; idx_out[1]=61; idx_out[2]=62; idx_out[3]=63; end
    endcase
  end

endmodule
