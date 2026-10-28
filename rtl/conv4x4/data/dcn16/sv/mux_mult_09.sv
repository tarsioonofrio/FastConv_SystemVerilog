//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 9;
  parameter int STATE_MULT = 16;
endpackage


module MuxMult
  (
    input  logic[$clog2(16-1):0] idx_in, // current state
    output logic[$clog2(16*9-1):0] idx_out[0:9-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; idx_out[8]=8; end
      1: begin idx_out[0]=9; idx_out[1]=10; idx_out[2]=11; idx_out[3]=12; idx_out[4]=13; idx_out[5]=14; idx_out[6]=15; idx_out[7]=16; idx_out[8]=17; end
      2: begin idx_out[0]=18; idx_out[1]=19; idx_out[2]=20; idx_out[3]=21; idx_out[4]=22; idx_out[5]=23; idx_out[6]=24; idx_out[7]=25; idx_out[8]=26; end
      3: begin idx_out[0]=27; idx_out[1]=28; idx_out[2]=29; idx_out[3]=30; idx_out[4]=31; idx_out[5]=32; idx_out[6]=33; idx_out[7]=34; idx_out[8]=35; end
      4: begin idx_out[0]=36; idx_out[1]=37; idx_out[2]=38; idx_out[3]=39; idx_out[4]=40; idx_out[5]=41; idx_out[6]=42; idx_out[7]=43; idx_out[8]=44; end
      5: begin idx_out[0]=45; idx_out[1]=46; idx_out[2]=47; idx_out[3]=48; idx_out[4]=49; idx_out[5]=50; idx_out[6]=51; idx_out[7]=52; idx_out[8]=53; end
      6: begin idx_out[0]=54; idx_out[1]=55; idx_out[2]=56; idx_out[3]=57; idx_out[4]=58; idx_out[5]=59; idx_out[6]=60; idx_out[7]=61; idx_out[8]=62; end
      7: begin idx_out[0]=63; idx_out[1]=64; idx_out[2]=65; idx_out[3]=66; idx_out[4]=67; idx_out[5]=68; idx_out[6]=69; idx_out[7]=70; idx_out[8]=71; end
      8: begin idx_out[0]=72; idx_out[1]=73; idx_out[2]=74; idx_out[3]=75; idx_out[4]=76; idx_out[5]=77; idx_out[6]=78; idx_out[7]=79; idx_out[8]=80; end
      9: begin idx_out[0]=81; idx_out[1]=82; idx_out[2]=83; idx_out[3]=84; idx_out[4]=85; idx_out[5]=86; idx_out[6]=87; idx_out[7]=88; idx_out[8]=89; end
      10: begin idx_out[0]=90; idx_out[1]=91; idx_out[2]=92; idx_out[3]=93; idx_out[4]=94; idx_out[5]=95; idx_out[6]=96; idx_out[7]=97; idx_out[8]=98; end
      11: begin idx_out[0]=99; idx_out[1]=100; idx_out[2]=101; idx_out[3]=102; idx_out[4]=103; idx_out[5]=104; idx_out[6]=105; idx_out[7]=106; idx_out[8]=107; end
      12: begin idx_out[0]=108; idx_out[1]=109; idx_out[2]=110; idx_out[3]=111; idx_out[4]=112; idx_out[5]=113; idx_out[6]=114; idx_out[7]=115; idx_out[8]=116; end
      13: begin idx_out[0]=117; idx_out[1]=118; idx_out[2]=119; idx_out[3]=120; idx_out[4]=121; idx_out[5]=122; idx_out[6]=123; idx_out[7]=124; idx_out[8]=125; end
      14: begin idx_out[0]=126; idx_out[1]=127; idx_out[2]=128; idx_out[3]=129; idx_out[4]=130; idx_out[5]=131; idx_out[6]=132; idx_out[7]=133; idx_out[8]=134; end
      15: begin idx_out[0]=135; idx_out[1]=136; idx_out[2]=137; idx_out[3]=138; idx_out[4]=139; idx_out[5]=140; idx_out[6]=141; idx_out[7]=142; idx_out[8]=143; end
    endcase
  end

endmodule
