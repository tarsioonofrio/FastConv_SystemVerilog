//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NMULT = 64;
  parameter int SMULT = 1;
endpackage


module MuxMult
  (
    input  logic[$clog2(1-1):0] idx_in, // current state
    output logic[$clog2(1*64-1):0] idx_out[0:64-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; idx_out[8]=8; idx_out[9]=9; idx_out[10]=10; idx_out[11]=11; idx_out[12]=12; idx_out[13]=13; idx_out[14]=14; idx_out[15]=15; idx_out[16]=16; idx_out[17]=17; idx_out[18]=18; idx_out[19]=19; idx_out[20]=20; idx_out[21]=21; idx_out[22]=22; idx_out[23]=23; idx_out[24]=24; idx_out[25]=25; idx_out[26]=26; idx_out[27]=27; idx_out[28]=28; idx_out[29]=29; idx_out[30]=30; idx_out[31]=31; idx_out[32]=32; idx_out[33]=33; idx_out[34]=34; idx_out[35]=35; idx_out[36]=36; idx_out[37]=37; idx_out[38]=38; idx_out[39]=39; idx_out[40]=40; idx_out[41]=41; idx_out[42]=42; idx_out[43]=43; idx_out[44]=44; idx_out[45]=45; idx_out[46]=46; idx_out[47]=47; idx_out[48]=48; idx_out[49]=49; idx_out[50]=50; idx_out[51]=51; idx_out[52]=52; idx_out[53]=53; idx_out[54]=54; idx_out[55]=55; idx_out[56]=56; idx_out[57]=57; idx_out[58]=58; idx_out[59]=59; idx_out[60]=60; idx_out[61]=61; idx_out[62]=62; idx_out[63]=63; end
    endcase
  end

endmodule
