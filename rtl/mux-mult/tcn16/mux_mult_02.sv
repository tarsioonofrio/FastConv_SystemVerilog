//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 2;
  parameter int STATE_MULT = 18;
endpackage


module MuxMult
  (
    input  logic[$clog2(18-1):0] idx_in, // current state
    output logic[$clog2(18*2-1):0] idx_out[0:2-1]  // index array output
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
    endcase
  end

endmodule
