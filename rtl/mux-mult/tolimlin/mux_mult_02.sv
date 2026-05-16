//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 2;
  parameter int STATE_MULT = 32;
endpackage


module MuxMult
  (
    input  logic[$clog2(32-1):0] idx_in, // current state
    output logic[$clog2(32*2-1):0] idx_out[0:2-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; end
      1: begin idx_out[0]=2; idx_out[1]=3; end
      2: begin idx_out[0]=4; idx_out[1]=5; end
      3: begin idx_out[0]=6; idx_out[1]=7; end
      4: begin idx_out[0]=8; idx_out[1]=9; end
      5: begin idx_out[0]=10; idx_out[1]=11; end
      6: begin idx_out[0]=12; idx_out[1]=13; end
      7: begin idx_out[0]=14; idx_out[1]=15; end
      8: begin idx_out[0]=16; idx_out[1]=17; end
      9: begin idx_out[0]=18; idx_out[1]=19; end
      10: begin idx_out[0]=20; idx_out[1]=21; end
      11: begin idx_out[0]=22; idx_out[1]=23; end
      12: begin idx_out[0]=24; idx_out[1]=25; end
      13: begin idx_out[0]=26; idx_out[1]=27; end
      14: begin idx_out[0]=28; idx_out[1]=29; end
      15: begin idx_out[0]=30; idx_out[1]=31; end
      16: begin idx_out[0]=32; idx_out[1]=33; end
      17: begin idx_out[0]=34; idx_out[1]=35; end
      18: begin idx_out[0]=36; idx_out[1]=37; end
      19: begin idx_out[0]=38; idx_out[1]=39; end
      20: begin idx_out[0]=40; idx_out[1]=41; end
      21: begin idx_out[0]=42; idx_out[1]=43; end
      22: begin idx_out[0]=44; idx_out[1]=45; end
      23: begin idx_out[0]=46; idx_out[1]=47; end
      24: begin idx_out[0]=48; idx_out[1]=49; end
      25: begin idx_out[0]=50; idx_out[1]=51; end
      26: begin idx_out[0]=52; idx_out[1]=53; end
      27: begin idx_out[0]=54; idx_out[1]=55; end
      28: begin idx_out[0]=56; idx_out[1]=57; end
      29: begin idx_out[0]=58; idx_out[1]=59; end
      30: begin idx_out[0]=60; idx_out[1]=61; end
      31: begin idx_out[0]=62; idx_out[1]=63; end
    endcase
  end

endmodule
