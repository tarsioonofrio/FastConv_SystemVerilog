//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 32;
  parameter int STATE_MULT = 2;
endpackage


module MuxMult
  (
    input  logic[$clog2(2-1):0] idx_in, // current state
    output logic[$clog2(2*32-1):0] idx_out[0:32-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; idx_out[8]=8; idx_out[9]=9; idx_out[10]=10; idx_out[11]=11; idx_out[12]=12; idx_out[13]=13; idx_out[14]=14; idx_out[15]=15; idx_out[16]=16; idx_out[17]=17; idx_out[18]=18; idx_out[19]=19; idx_out[20]=20; idx_out[21]=21; idx_out[22]=22; idx_out[23]=23; idx_out[24]=24; idx_out[25]=25; idx_out[26]=26; idx_out[27]=27; idx_out[28]=28; idx_out[29]=29; idx_out[30]=30; idx_out[31]=31; end
      1: begin idx_out[0]=32; idx_out[1]=33; idx_out[2]=34; idx_out[3]=35; idx_out[4]=36; idx_out[5]=37; idx_out[6]=38; idx_out[7]=39; idx_out[8]=40; idx_out[9]=41; idx_out[10]=42; idx_out[11]=43; idx_out[12]=44; idx_out[13]=45; idx_out[14]=46; idx_out[15]=47; idx_out[16]=48; idx_out[17]=49; idx_out[18]=50; idx_out[19]=51; idx_out[20]=52; idx_out[21]=53; idx_out[22]=54; idx_out[23]=55; idx_out[24]=56; idx_out[25]=57; idx_out[26]=58; idx_out[27]=59; idx_out[28]=60; idx_out[29]=61; idx_out[30]=62; idx_out[31]=63; end
    endcase
  end

endmodule
