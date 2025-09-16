//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 3;
  parameter int SMULT = 12;
endpackage


module MuxMult
  (
    input  logic[$clog2(3):0] idx_in, // current state
    output logic[$clog2(3):0] idx_out[0:3 - 1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; end
      1: begin idx_out[0]=3; idx_out[1]=4; idx_out[2]=5; end
      2: begin idx_out[0]=6; idx_out[1]=7; idx_out[2]=8; end
      3: begin idx_out[0]=9; idx_out[1]=10; idx_out[2]=11; end
      4: begin idx_out[0]=12; idx_out[1]=13; idx_out[2]=14; end
      5: begin idx_out[0]=15; idx_out[1]=16; idx_out[2]=17; end
      6: begin idx_out[0]=18; idx_out[1]=19; idx_out[2]=20; end
      7: begin idx_out[0]=21; idx_out[1]=22; idx_out[2]=23; end
      8: begin idx_out[0]=24; idx_out[1]=25; idx_out[2]=26; end
      9: begin idx_out[0]=27; idx_out[1]=28; idx_out[2]=29; end
      10: begin idx_out[0]=30; idx_out[1]=31; idx_out[2]=32; end
      11: begin idx_out[0]=33; idx_out[1]=34; idx_out[2]=35; end
    endcase
  end

endmodule
