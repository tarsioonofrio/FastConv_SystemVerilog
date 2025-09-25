//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 5;
  parameter int SMULT = 5;
endpackage


module MuxMult
  (
    input  logic[$clog2(5-1):0] idx_in, // current state
    output logic[$clog2(5*5-1):0] idx_out[0:5-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; end
      1: begin idx_out[0]=5; idx_out[1]=6; idx_out[2]=7; idx_out[3]=8; idx_out[4]=9; end
      2: begin idx_out[0]=10; idx_out[1]=11; idx_out[2]=12; idx_out[3]=13; idx_out[4]=14; end
      3: begin idx_out[0]=15; idx_out[1]=16; idx_out[2]=17; idx_out[3]=18; idx_out[4]=19; end
      4: begin idx_out[0]=20; idx_out[1]=21; idx_out[2]=22; idx_out[3]=23; idx_out[4]=24; end
    endcase
  end

endmodule
