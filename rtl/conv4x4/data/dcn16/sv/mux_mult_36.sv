//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 36;
  parameter int STATE_MULT = 4;
endpackage


module MuxMult
  (
    input  logic[$clog2(4-1):0] idx_in, // current state
    output logic[$clog2(4*36-1):0] idx_out[0:36-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; idx_out[8]=8; idx_out[9]=9; idx_out[10]=10; idx_out[11]=11; idx_out[12]=12; idx_out[13]=13; idx_out[14]=14; idx_out[15]=15; idx_out[16]=16; idx_out[17]=17; idx_out[18]=18; idx_out[19]=19; idx_out[20]=20; idx_out[21]=21; idx_out[22]=22; idx_out[23]=23; idx_out[24]=24; idx_out[25]=25; idx_out[26]=26; idx_out[27]=27; idx_out[28]=28; idx_out[29]=29; idx_out[30]=30; idx_out[31]=31; idx_out[32]=32; idx_out[33]=33; idx_out[34]=34; idx_out[35]=35; end
      1: begin idx_out[0]=36; idx_out[1]=37; idx_out[2]=38; idx_out[3]=39; idx_out[4]=40; idx_out[5]=41; idx_out[6]=42; idx_out[7]=43; idx_out[8]=44; idx_out[9]=45; idx_out[10]=46; idx_out[11]=47; idx_out[12]=48; idx_out[13]=49; idx_out[14]=50; idx_out[15]=51; idx_out[16]=52; idx_out[17]=53; idx_out[18]=54; idx_out[19]=55; idx_out[20]=56; idx_out[21]=57; idx_out[22]=58; idx_out[23]=59; idx_out[24]=60; idx_out[25]=61; idx_out[26]=62; idx_out[27]=63; idx_out[28]=64; idx_out[29]=65; idx_out[30]=66; idx_out[31]=67; idx_out[32]=68; idx_out[33]=69; idx_out[34]=70; idx_out[35]=71; end
      2: begin idx_out[0]=72; idx_out[1]=73; idx_out[2]=74; idx_out[3]=75; idx_out[4]=76; idx_out[5]=77; idx_out[6]=78; idx_out[7]=79; idx_out[8]=80; idx_out[9]=81; idx_out[10]=82; idx_out[11]=83; idx_out[12]=84; idx_out[13]=85; idx_out[14]=86; idx_out[15]=87; idx_out[16]=88; idx_out[17]=89; idx_out[18]=90; idx_out[19]=91; idx_out[20]=92; idx_out[21]=93; idx_out[22]=94; idx_out[23]=95; idx_out[24]=96; idx_out[25]=97; idx_out[26]=98; idx_out[27]=99; idx_out[28]=100; idx_out[29]=101; idx_out[30]=102; idx_out[31]=103; idx_out[32]=104; idx_out[33]=105; idx_out[34]=106; idx_out[35]=107; end
      3: begin idx_out[0]=108; idx_out[1]=109; idx_out[2]=110; idx_out[3]=111; idx_out[4]=112; idx_out[5]=113; idx_out[6]=114; idx_out[7]=115; idx_out[8]=116; idx_out[9]=117; idx_out[10]=118; idx_out[11]=119; idx_out[12]=120; idx_out[13]=121; idx_out[14]=122; idx_out[15]=123; idx_out[16]=124; idx_out[17]=125; idx_out[18]=126; idx_out[19]=127; idx_out[20]=128; idx_out[21]=129; idx_out[22]=130; idx_out[23]=131; idx_out[24]=132; idx_out[25]=133; idx_out[26]=134; idx_out[27]=135; idx_out[28]=136; idx_out[29]=137; idx_out[30]=138; idx_out[31]=139; idx_out[32]=140; idx_out[33]=141; idx_out[34]=142; idx_out[35]=143; end
    endcase
  end

endmodule
