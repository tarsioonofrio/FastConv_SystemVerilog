//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 18;
  parameter int STATE_MULT = 8;
endpackage


module MuxMult
  (
    input  logic[$clog2(8-1):0] idx_in, // current state
    output logic[$clog2(8*18-1):0] idx_out[0:18-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; idx_out[8]=8; idx_out[9]=9; idx_out[10]=10; idx_out[11]=11; idx_out[12]=12; idx_out[13]=13; idx_out[14]=14; idx_out[15]=15; idx_out[16]=16; idx_out[17]=17; end
      1: begin idx_out[0]=18; idx_out[1]=19; idx_out[2]=20; idx_out[3]=21; idx_out[4]=22; idx_out[5]=23; idx_out[6]=24; idx_out[7]=25; idx_out[8]=26; idx_out[9]=27; idx_out[10]=28; idx_out[11]=29; idx_out[12]=30; idx_out[13]=31; idx_out[14]=32; idx_out[15]=33; idx_out[16]=34; idx_out[17]=35; end
      2: begin idx_out[0]=36; idx_out[1]=37; idx_out[2]=38; idx_out[3]=39; idx_out[4]=40; idx_out[5]=41; idx_out[6]=42; idx_out[7]=43; idx_out[8]=44; idx_out[9]=45; idx_out[10]=46; idx_out[11]=47; idx_out[12]=48; idx_out[13]=49; idx_out[14]=50; idx_out[15]=51; idx_out[16]=52; idx_out[17]=53; end
      3: begin idx_out[0]=54; idx_out[1]=55; idx_out[2]=56; idx_out[3]=57; idx_out[4]=58; idx_out[5]=59; idx_out[6]=60; idx_out[7]=61; idx_out[8]=62; idx_out[9]=63; idx_out[10]=64; idx_out[11]=65; idx_out[12]=66; idx_out[13]=67; idx_out[14]=68; idx_out[15]=69; idx_out[16]=70; idx_out[17]=71; end
      4: begin idx_out[0]=72; idx_out[1]=73; idx_out[2]=74; idx_out[3]=75; idx_out[4]=76; idx_out[5]=77; idx_out[6]=78; idx_out[7]=79; idx_out[8]=80; idx_out[9]=81; idx_out[10]=82; idx_out[11]=83; idx_out[12]=84; idx_out[13]=85; idx_out[14]=86; idx_out[15]=87; idx_out[16]=88; idx_out[17]=89; end
      5: begin idx_out[0]=90; idx_out[1]=91; idx_out[2]=92; idx_out[3]=93; idx_out[4]=94; idx_out[5]=95; idx_out[6]=96; idx_out[7]=97; idx_out[8]=98; idx_out[9]=99; idx_out[10]=100; idx_out[11]=101; idx_out[12]=102; idx_out[13]=103; idx_out[14]=104; idx_out[15]=105; idx_out[16]=106; idx_out[17]=107; end
      6: begin idx_out[0]=108; idx_out[1]=109; idx_out[2]=110; idx_out[3]=111; idx_out[4]=112; idx_out[5]=113; idx_out[6]=114; idx_out[7]=115; idx_out[8]=116; idx_out[9]=117; idx_out[10]=118; idx_out[11]=119; idx_out[12]=120; idx_out[13]=121; idx_out[14]=122; idx_out[15]=123; idx_out[16]=124; idx_out[17]=125; end
      7: begin idx_out[0]=126; idx_out[1]=127; idx_out[2]=128; idx_out[3]=129; idx_out[4]=130; idx_out[5]=131; idx_out[6]=132; idx_out[7]=133; idx_out[8]=134; idx_out[9]=135; idx_out[10]=136; idx_out[11]=137; idx_out[12]=138; idx_out[13]=139; idx_out[14]=140; idx_out[15]=141; idx_out[16]=142; idx_out[17]=143; end
    endcase
  end

endmodule
