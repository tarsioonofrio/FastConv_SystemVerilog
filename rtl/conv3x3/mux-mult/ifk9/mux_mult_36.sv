//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 36;
  parameter int STATE_MULT = 1;
endpackage


module MuxMult
  (
    input  logic[$clog2(1-1):0] idx_in, // current state
    output logic[$clog2(1*36-1):0] idx_out[0:36-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; idx_out[8]=8; idx_out[9]=9; idx_out[10]=10; idx_out[11]=11; idx_out[12]=12; idx_out[13]=13; idx_out[14]=14; idx_out[15]=15; idx_out[16]=16; idx_out[17]=17; idx_out[18]=18; idx_out[19]=19; idx_out[20]=20; idx_out[21]=21; idx_out[22]=22; idx_out[23]=23; idx_out[24]=24; idx_out[25]=25; idx_out[26]=26; idx_out[27]=27; idx_out[28]=28; idx_out[29]=29; idx_out[30]=30; idx_out[31]=31; idx_out[32]=32; idx_out[33]=33; idx_out[34]=34; idx_out[35]=35; end
    endcase
  end

endmodule
