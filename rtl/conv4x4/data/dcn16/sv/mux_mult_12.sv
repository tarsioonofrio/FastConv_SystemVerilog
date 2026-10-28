//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 12;
  parameter int STATE_MULT = 12;
endpackage


module MuxMult
  (
    input  logic[$clog2(12-1):0] idx_in, // current state
    output logic[$clog2(12*12-1):0] idx_out[0:12-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; idx_out[8]=8; idx_out[9]=9; idx_out[10]=10; idx_out[11]=11; end
      1: begin idx_out[0]=12; idx_out[1]=13; idx_out[2]=14; idx_out[3]=15; idx_out[4]=16; idx_out[5]=17; idx_out[6]=18; idx_out[7]=19; idx_out[8]=20; idx_out[9]=21; idx_out[10]=22; idx_out[11]=23; end
      2: begin idx_out[0]=24; idx_out[1]=25; idx_out[2]=26; idx_out[3]=27; idx_out[4]=28; idx_out[5]=29; idx_out[6]=30; idx_out[7]=31; idx_out[8]=32; idx_out[9]=33; idx_out[10]=34; idx_out[11]=35; end
      3: begin idx_out[0]=36; idx_out[1]=37; idx_out[2]=38; idx_out[3]=39; idx_out[4]=40; idx_out[5]=41; idx_out[6]=42; idx_out[7]=43; idx_out[8]=44; idx_out[9]=45; idx_out[10]=46; idx_out[11]=47; end
      4: begin idx_out[0]=48; idx_out[1]=49; idx_out[2]=50; idx_out[3]=51; idx_out[4]=52; idx_out[5]=53; idx_out[6]=54; idx_out[7]=55; idx_out[8]=56; idx_out[9]=57; idx_out[10]=58; idx_out[11]=59; end
      5: begin idx_out[0]=60; idx_out[1]=61; idx_out[2]=62; idx_out[3]=63; idx_out[4]=64; idx_out[5]=65; idx_out[6]=66; idx_out[7]=67; idx_out[8]=68; idx_out[9]=69; idx_out[10]=70; idx_out[11]=71; end
      6: begin idx_out[0]=72; idx_out[1]=73; idx_out[2]=74; idx_out[3]=75; idx_out[4]=76; idx_out[5]=77; idx_out[6]=78; idx_out[7]=79; idx_out[8]=80; idx_out[9]=81; idx_out[10]=82; idx_out[11]=83; end
      7: begin idx_out[0]=84; idx_out[1]=85; idx_out[2]=86; idx_out[3]=87; idx_out[4]=88; idx_out[5]=89; idx_out[6]=90; idx_out[7]=91; idx_out[8]=92; idx_out[9]=93; idx_out[10]=94; idx_out[11]=95; end
      8: begin idx_out[0]=96; idx_out[1]=97; idx_out[2]=98; idx_out[3]=99; idx_out[4]=100; idx_out[5]=101; idx_out[6]=102; idx_out[7]=103; idx_out[8]=104; idx_out[9]=105; idx_out[10]=106; idx_out[11]=107; end
      9: begin idx_out[0]=108; idx_out[1]=109; idx_out[2]=110; idx_out[3]=111; idx_out[4]=112; idx_out[5]=113; idx_out[6]=114; idx_out[7]=115; idx_out[8]=116; idx_out[9]=117; idx_out[10]=118; idx_out[11]=119; end
      10: begin idx_out[0]=120; idx_out[1]=121; idx_out[2]=122; idx_out[3]=123; idx_out[4]=124; idx_out[5]=125; idx_out[6]=126; idx_out[7]=127; idx_out[8]=128; idx_out[9]=129; idx_out[10]=130; idx_out[11]=131; end
      11: begin idx_out[0]=132; idx_out[1]=133; idx_out[2]=134; idx_out[3]=135; idx_out[4]=136; idx_out[5]=137; idx_out[6]=138; idx_out[7]=139; idx_out[8]=140; idx_out[9]=141; idx_out[10]=142; idx_out[11]=143; end
    endcase
  end

endmodule
