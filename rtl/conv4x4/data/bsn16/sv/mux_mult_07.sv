//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 7;
  parameter int STATE_MULT = 7;
endpackage


module MuxMult
  (
    input  logic[$clog2(7-1):0] idx_in, // current state
    output logic[$clog2(7*7-1):0] idx_out[0:7-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; end
      1: begin idx_out[0]=7; idx_out[1]=8; idx_out[2]=9; idx_out[3]=10; idx_out[4]=11; idx_out[5]=12; idx_out[6]=13; end
      2: begin idx_out[0]=14; idx_out[1]=15; idx_out[2]=16; idx_out[3]=17; idx_out[4]=18; idx_out[5]=19; idx_out[6]=20; end
      3: begin idx_out[0]=21; idx_out[1]=22; idx_out[2]=23; idx_out[3]=24; idx_out[4]=25; idx_out[5]=26; idx_out[6]=27; end
      4: begin idx_out[0]=28; idx_out[1]=29; idx_out[2]=30; idx_out[3]=31; idx_out[4]=32; idx_out[5]=33; idx_out[6]=34; end
      5: begin idx_out[0]=35; idx_out[1]=36; idx_out[2]=37; idx_out[3]=38; idx_out[4]=39; idx_out[5]=40; idx_out[6]=41; end
      6: begin idx_out[0]=42; idx_out[1]=43; idx_out[2]=44; idx_out[3]=45; idx_out[4]=46; idx_out[5]=47; idx_out[6]=48; end
    endcase
  end

endmodule
