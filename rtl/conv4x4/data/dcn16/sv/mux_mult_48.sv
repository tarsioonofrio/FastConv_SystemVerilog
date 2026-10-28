//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 48;
  parameter int STATE_MULT = 3;
endpackage


module MuxMult
  (
    input  logic[$clog2(3-1):0] idx_in, // current state
    output logic[$clog2(3*48-1):0] idx_out[0:48-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; idx_out[8]=8; idx_out[9]=9; idx_out[10]=10; idx_out[11]=11; idx_out[12]=12; idx_out[13]=13; idx_out[14]=14; idx_out[15]=15; idx_out[16]=16; idx_out[17]=17; idx_out[18]=18; idx_out[19]=19; idx_out[20]=20; idx_out[21]=21; idx_out[22]=22; idx_out[23]=23; idx_out[24]=24; idx_out[25]=25; idx_out[26]=26; idx_out[27]=27; idx_out[28]=28; idx_out[29]=29; idx_out[30]=30; idx_out[31]=31; idx_out[32]=32; idx_out[33]=33; idx_out[34]=34; idx_out[35]=35; idx_out[36]=36; idx_out[37]=37; idx_out[38]=38; idx_out[39]=39; idx_out[40]=40; idx_out[41]=41; idx_out[42]=42; idx_out[43]=43; idx_out[44]=44; idx_out[45]=45; idx_out[46]=46; idx_out[47]=47; end
      1: begin idx_out[0]=48; idx_out[1]=49; idx_out[2]=50; idx_out[3]=51; idx_out[4]=52; idx_out[5]=53; idx_out[6]=54; idx_out[7]=55; idx_out[8]=56; idx_out[9]=57; idx_out[10]=58; idx_out[11]=59; idx_out[12]=60; idx_out[13]=61; idx_out[14]=62; idx_out[15]=63; idx_out[16]=64; idx_out[17]=65; idx_out[18]=66; idx_out[19]=67; idx_out[20]=68; idx_out[21]=69; idx_out[22]=70; idx_out[23]=71; idx_out[24]=72; idx_out[25]=73; idx_out[26]=74; idx_out[27]=75; idx_out[28]=76; idx_out[29]=77; idx_out[30]=78; idx_out[31]=79; idx_out[32]=80; idx_out[33]=81; idx_out[34]=82; idx_out[35]=83; idx_out[36]=84; idx_out[37]=85; idx_out[38]=86; idx_out[39]=87; idx_out[40]=88; idx_out[41]=89; idx_out[42]=90; idx_out[43]=91; idx_out[44]=92; idx_out[45]=93; idx_out[46]=94; idx_out[47]=95; end
      2: begin idx_out[0]=96; idx_out[1]=97; idx_out[2]=98; idx_out[3]=99; idx_out[4]=100; idx_out[5]=101; idx_out[6]=102; idx_out[7]=103; idx_out[8]=104; idx_out[9]=105; idx_out[10]=106; idx_out[11]=107; idx_out[12]=108; idx_out[13]=109; idx_out[14]=110; idx_out[15]=111; idx_out[16]=112; idx_out[17]=113; idx_out[18]=114; idx_out[19]=115; idx_out[20]=116; idx_out[21]=117; idx_out[22]=118; idx_out[23]=119; idx_out[24]=120; idx_out[25]=121; idx_out[26]=122; idx_out[27]=123; idx_out[28]=124; idx_out[29]=125; idx_out[30]=126; idx_out[31]=127; idx_out[32]=128; idx_out[33]=129; idx_out[34]=130; idx_out[35]=131; idx_out[36]=132; idx_out[37]=133; idx_out[38]=134; idx_out[39]=135; idx_out[40]=136; idx_out[41]=137; idx_out[42]=138; idx_out[43]=139; idx_out[44]=140; idx_out[45]=141; idx_out[46]=142; idx_out[47]=143; end
    endcase
  end

endmodule
