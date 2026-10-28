//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 16;
  parameter int STATE_MULT = 9;
endpackage


module MuxMult
  (
    input  logic[$clog2(9-1):0] idx_in, // current state
    output logic[$clog2(9*16-1):0] idx_out[0:16-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; idx_out[8]=8; idx_out[9]=9; idx_out[10]=10; idx_out[11]=11; idx_out[12]=12; idx_out[13]=13; idx_out[14]=14; idx_out[15]=15; end
      1: begin idx_out[0]=16; idx_out[1]=17; idx_out[2]=18; idx_out[3]=19; idx_out[4]=20; idx_out[5]=21; idx_out[6]=22; idx_out[7]=23; idx_out[8]=24; idx_out[9]=25; idx_out[10]=26; idx_out[11]=27; idx_out[12]=28; idx_out[13]=29; idx_out[14]=30; idx_out[15]=31; end
      2: begin idx_out[0]=32; idx_out[1]=33; idx_out[2]=34; idx_out[3]=35; idx_out[4]=36; idx_out[5]=37; idx_out[6]=38; idx_out[7]=39; idx_out[8]=40; idx_out[9]=41; idx_out[10]=42; idx_out[11]=43; idx_out[12]=44; idx_out[13]=45; idx_out[14]=46; idx_out[15]=47; end
      3: begin idx_out[0]=48; idx_out[1]=49; idx_out[2]=50; idx_out[3]=51; idx_out[4]=52; idx_out[5]=53; idx_out[6]=54; idx_out[7]=55; idx_out[8]=56; idx_out[9]=57; idx_out[10]=58; idx_out[11]=59; idx_out[12]=60; idx_out[13]=61; idx_out[14]=62; idx_out[15]=63; end
      4: begin idx_out[0]=64; idx_out[1]=65; idx_out[2]=66; idx_out[3]=67; idx_out[4]=68; idx_out[5]=69; idx_out[6]=70; idx_out[7]=71; idx_out[8]=72; idx_out[9]=73; idx_out[10]=74; idx_out[11]=75; idx_out[12]=76; idx_out[13]=77; idx_out[14]=78; idx_out[15]=79; end
      5: begin idx_out[0]=80; idx_out[1]=81; idx_out[2]=82; idx_out[3]=83; idx_out[4]=84; idx_out[5]=85; idx_out[6]=86; idx_out[7]=87; idx_out[8]=88; idx_out[9]=89; idx_out[10]=90; idx_out[11]=91; idx_out[12]=92; idx_out[13]=93; idx_out[14]=94; idx_out[15]=95; end
      6: begin idx_out[0]=96; idx_out[1]=97; idx_out[2]=98; idx_out[3]=99; idx_out[4]=100; idx_out[5]=101; idx_out[6]=102; idx_out[7]=103; idx_out[8]=104; idx_out[9]=105; idx_out[10]=106; idx_out[11]=107; idx_out[12]=108; idx_out[13]=109; idx_out[14]=110; idx_out[15]=111; end
      7: begin idx_out[0]=112; idx_out[1]=113; idx_out[2]=114; idx_out[3]=115; idx_out[4]=116; idx_out[5]=117; idx_out[6]=118; idx_out[7]=119; idx_out[8]=120; idx_out[9]=121; idx_out[10]=122; idx_out[11]=123; idx_out[12]=124; idx_out[13]=125; idx_out[14]=126; idx_out[15]=127; end
      8: begin idx_out[0]=128; idx_out[1]=129; idx_out[2]=130; idx_out[3]=131; idx_out[4]=132; idx_out[5]=133; idx_out[6]=134; idx_out[7]=135; idx_out[8]=136; idx_out[9]=137; idx_out[10]=138; idx_out[11]=139; idx_out[12]=140; idx_out[13]=141; idx_out[14]=142; idx_out[15]=143; end
    endcase
  end

endmodule
