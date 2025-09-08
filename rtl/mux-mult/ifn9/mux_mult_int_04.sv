//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 4;
  parameter int SMULT = 9;
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
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; end
      MULT1: begin idx_out[0]=4; idx_out[1]=5; idx_out[2]=6; idx_out[3]=7; end
      MULT2: begin idx_out[0]=8; idx_out[1]=9; idx_out[2]=10; idx_out[3]=11; end
      MULT3: begin idx_out[0]=12; idx_out[1]=13; idx_out[2]=14; idx_out[3]=15; end
      MULT4: begin idx_out[0]=16; idx_out[1]=17; idx_out[2]=18; idx_out[3]=19; end
      MULT5: begin idx_out[0]=20; idx_out[1]=21; idx_out[2]=22; idx_out[3]=23; end
      MULT6: begin idx_out[0]=24; idx_out[1]=25; idx_out[2]=26; idx_out[3]=27; end
      MULT7: begin idx_out[0]=28; idx_out[1]=29; idx_out[2]=30; idx_out[3]=31; end
      MULT8: begin idx_out[0]=32; idx_out[1]=33; idx_out[2]=34; idx_out[3]=35; end
    endcase
  end

endmodule
