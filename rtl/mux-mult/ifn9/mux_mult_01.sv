//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 1;
  parameter int SMULT = 36;
endpackage


module MuxMult
  (
    input  logic[$clog2(1-1):0] idx_in, // current state
    output logic[$clog2(1*1-1):0] idx_out[0:1-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; end
      1: begin idx_out[0]=1; end
      2: begin idx_out[0]=2; end
      3: begin idx_out[0]=3; end
      4: begin idx_out[0]=4; end
      5: begin idx_out[0]=5; end
      6: begin idx_out[0]=6; end
      7: begin idx_out[0]=7; end
      8: begin idx_out[0]=8; end
      9: begin idx_out[0]=9; end
      10: begin idx_out[0]=10; end
      11: begin idx_out[0]=11; end
      12: begin idx_out[0]=12; end
      13: begin idx_out[0]=13; end
      14: begin idx_out[0]=14; end
      15: begin idx_out[0]=15; end
      16: begin idx_out[0]=16; end
      17: begin idx_out[0]=17; end
      18: begin idx_out[0]=18; end
      19: begin idx_out[0]=19; end
      20: begin idx_out[0]=20; end
      21: begin idx_out[0]=21; end
      22: begin idx_out[0]=22; end
      23: begin idx_out[0]=23; end
      24: begin idx_out[0]=24; end
      25: begin idx_out[0]=25; end
      26: begin idx_out[0]=26; end
      27: begin idx_out[0]=27; end
      28: begin idx_out[0]=28; end
      29: begin idx_out[0]=29; end
      30: begin idx_out[0]=30; end
      31: begin idx_out[0]=31; end
      32: begin idx_out[0]=32; end
      33: begin idx_out[0]=33; end
      34: begin idx_out[0]=34; end
      35: begin idx_out[0]=35; end
    endcase
  end

endmodule
