//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 3;
  parameter int SMULT = 12;
endpackage


module MuxMult
  import pack_mux_mult::*;
  (
    input  state_type current_st,  // current state
    output logic[5:0] idx[0:NMULT-1]    // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (current_st)
      default: begin idx[0]=0; idx[1]=1; idx[2]=2; end
      MULT1: begin idx[0]=3; idx[1]=4; idx[2]=5; end
      MULT2: begin idx[0]=6; idx[1]=7; idx[2]=8; end
      MULT3: begin idx[0]=9; idx[1]=10; idx[2]=11; end
      MULT4: begin idx[0]=12; idx[1]=13; idx[2]=14; end
      MULT5: begin idx[0]=15; idx[1]=16; idx[2]=17; end
      MULT6: begin idx[0]=18; idx[1]=19; idx[2]=20; end
      MULT7: begin idx[0]=21; idx[1]=22; idx[2]=23; end
      MULT8: begin idx[0]=24; idx[1]=25; idx[2]=26; end
      MULT9: begin idx[0]=27; idx[1]=28; idx[2]=29; end
      MULT10: begin idx[0]=30; idx[1]=31; idx[2]=32; end
      MULT11: begin idx[0]=33; idx[1]=34; idx[2]=35; end
    endcase
  end

endmodule
