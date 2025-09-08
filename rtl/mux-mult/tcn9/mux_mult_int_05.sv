//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 5;
  parameter int SMULT = 5;
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
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; end
      MULT1: begin idx_out[0]=5; idx_out[1]=6; idx_out[2]=7; idx_out[3]=8; idx_out[4]=9; end
      MULT2: begin idx_out[0]=10; idx_out[1]=11; idx_out[2]=12; idx_out[3]=13; idx_out[4]=14; end
      MULT3: begin idx_out[0]=15; idx_out[1]=16; idx_out[2]=17; idx_out[3]=18; idx_out[4]=19; end
      MULT4: begin idx_out[0]=20; idx_out[1]=21; idx_out[2]=22; idx_out[3]=23; idx_out[4]=24; end
    endcase
  end

endmodule
