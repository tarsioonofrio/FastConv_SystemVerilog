//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 24;
  parameter int STATE_MULT = 6;
endpackage


module MuxMult
  (
    input  logic[$clog2(6-1):0] idx_in, // current state
    output logic[$clog2(6*24-1):0] idx_out[0:24-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; idx_out[8]=8; idx_out[9]=9; idx_out[10]=10; idx_out[11]=11; idx_out[12]=12; idx_out[13]=13; idx_out[14]=14; idx_out[15]=15; idx_out[16]=16; idx_out[17]=17; idx_out[18]=18; idx_out[19]=19; idx_out[20]=20; idx_out[21]=21; idx_out[22]=22; idx_out[23]=23; end
      1: begin idx_out[0]=24; idx_out[1]=25; idx_out[2]=26; idx_out[3]=27; idx_out[4]=28; idx_out[5]=29; idx_out[6]=30; idx_out[7]=31; idx_out[8]=32; idx_out[9]=33; idx_out[10]=34; idx_out[11]=35; idx_out[12]=36; idx_out[13]=37; idx_out[14]=38; idx_out[15]=39; idx_out[16]=40; idx_out[17]=41; idx_out[18]=42; idx_out[19]=43; idx_out[20]=44; idx_out[21]=45; idx_out[22]=46; idx_out[23]=47; end
      2: begin idx_out[0]=48; idx_out[1]=49; idx_out[2]=50; idx_out[3]=51; idx_out[4]=52; idx_out[5]=53; idx_out[6]=54; idx_out[7]=55; idx_out[8]=56; idx_out[9]=57; idx_out[10]=58; idx_out[11]=59; idx_out[12]=60; idx_out[13]=61; idx_out[14]=62; idx_out[15]=63; idx_out[16]=64; idx_out[17]=65; idx_out[18]=66; idx_out[19]=67; idx_out[20]=68; idx_out[21]=69; idx_out[22]=70; idx_out[23]=71; end
      3: begin idx_out[0]=72; idx_out[1]=73; idx_out[2]=74; idx_out[3]=75; idx_out[4]=76; idx_out[5]=77; idx_out[6]=78; idx_out[7]=79; idx_out[8]=80; idx_out[9]=81; idx_out[10]=82; idx_out[11]=83; idx_out[12]=84; idx_out[13]=85; idx_out[14]=86; idx_out[15]=87; idx_out[16]=88; idx_out[17]=89; idx_out[18]=90; idx_out[19]=91; idx_out[20]=92; idx_out[21]=93; idx_out[22]=94; idx_out[23]=95; end
      4: begin idx_out[0]=96; idx_out[1]=97; idx_out[2]=98; idx_out[3]=99; idx_out[4]=100; idx_out[5]=101; idx_out[6]=102; idx_out[7]=103; idx_out[8]=104; idx_out[9]=105; idx_out[10]=106; idx_out[11]=107; idx_out[12]=108; idx_out[13]=109; idx_out[14]=110; idx_out[15]=111; idx_out[16]=112; idx_out[17]=113; idx_out[18]=114; idx_out[19]=115; idx_out[20]=116; idx_out[21]=117; idx_out[22]=118; idx_out[23]=119; end
      5: begin idx_out[0]=120; idx_out[1]=121; idx_out[2]=122; idx_out[3]=123; idx_out[4]=124; idx_out[5]=125; idx_out[6]=126; idx_out[7]=127; idx_out[8]=128; idx_out[9]=129; idx_out[10]=130; idx_out[11]=131; idx_out[12]=132; idx_out[13]=133; idx_out[14]=134; idx_out[15]=135; idx_out[16]=136; idx_out[17]=137; idx_out[18]=138; idx_out[19]=139; idx_out[20]=140; idx_out[21]=141; idx_out[22]=142; idx_out[23]=143; end
    endcase
  end

endmodule
