//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 2;
  parameter int SMULT = 18;
endpackage


module MuxMult
  import pack_mux_mult::*;
  (
    input  logic[6:0] idx_in, // current state
    output logic[6:0] idx_out[0:NMULT-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; end
      MULT1: begin idx_out[0]=2; idx_out[1]=3; end
      MULT2: begin idx_out[0]=4; idx_out[1]=5; end
      MULT3: begin idx_out[0]=6; idx_out[1]=7; end
      MULT4: begin idx_out[0]=8; idx_out[1]=9; end
      MULT5: begin idx_out[0]=10; idx_out[1]=11; end
      MULT6: begin idx_out[0]=12; idx_out[1]=13; end
      MULT7: begin idx_out[0]=14; idx_out[1]=15; end
      MULT8: begin idx_out[0]=16; idx_out[1]=17; end
      MULT9: begin idx_out[0]=18; idx_out[1]=19; end
      MULT10: begin idx_out[0]=20; idx_out[1]=21; end
      MULT11: begin idx_out[0]=22; idx_out[1]=23; end
      MULT12: begin idx_out[0]=24; idx_out[1]=25; end
      MULT13: begin idx_out[0]=26; idx_out[1]=27; end
      MULT14: begin idx_out[0]=28; idx_out[1]=29; end
      MULT15: begin idx_out[0]=30; idx_out[1]=31; end
      MULT16: begin idx_out[0]=32; idx_out[1]=33; end
      MULT17: begin idx_out[0]=34; idx_out[1]=35; end
    endcase
  end

endmodule
