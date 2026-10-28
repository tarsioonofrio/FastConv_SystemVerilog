//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 6;
  parameter int STATE_MULT = 24;
endpackage


module MuxMult
  (
    input  logic[$clog2(24-1):0] idx_in, // current state
    output logic[$clog2(24*6-1):0] idx_out[0:6-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; end
      1: begin idx_out[0]=6; idx_out[1]=7; idx_out[2]=8; idx_out[3]=9; idx_out[4]=10; idx_out[5]=11; end
      2: begin idx_out[0]=12; idx_out[1]=13; idx_out[2]=14; idx_out[3]=15; idx_out[4]=16; idx_out[5]=17; end
      3: begin idx_out[0]=18; idx_out[1]=19; idx_out[2]=20; idx_out[3]=21; idx_out[4]=22; idx_out[5]=23; end
      4: begin idx_out[0]=24; idx_out[1]=25; idx_out[2]=26; idx_out[3]=27; idx_out[4]=28; idx_out[5]=29; end
      5: begin idx_out[0]=30; idx_out[1]=31; idx_out[2]=32; idx_out[3]=33; idx_out[4]=34; idx_out[5]=35; end
      6: begin idx_out[0]=36; idx_out[1]=37; idx_out[2]=38; idx_out[3]=39; idx_out[4]=40; idx_out[5]=41; end
      7: begin idx_out[0]=42; idx_out[1]=43; idx_out[2]=44; idx_out[3]=45; idx_out[4]=46; idx_out[5]=47; end
      8: begin idx_out[0]=48; idx_out[1]=49; idx_out[2]=50; idx_out[3]=51; idx_out[4]=52; idx_out[5]=53; end
      9: begin idx_out[0]=54; idx_out[1]=55; idx_out[2]=56; idx_out[3]=57; idx_out[4]=58; idx_out[5]=59; end
      10: begin idx_out[0]=60; idx_out[1]=61; idx_out[2]=62; idx_out[3]=63; idx_out[4]=64; idx_out[5]=65; end
      11: begin idx_out[0]=66; idx_out[1]=67; idx_out[2]=68; idx_out[3]=69; idx_out[4]=70; idx_out[5]=71; end
      12: begin idx_out[0]=72; idx_out[1]=73; idx_out[2]=74; idx_out[3]=75; idx_out[4]=76; idx_out[5]=77; end
      13: begin idx_out[0]=78; idx_out[1]=79; idx_out[2]=80; idx_out[3]=81; idx_out[4]=82; idx_out[5]=83; end
      14: begin idx_out[0]=84; idx_out[1]=85; idx_out[2]=86; idx_out[3]=87; idx_out[4]=88; idx_out[5]=89; end
      15: begin idx_out[0]=90; idx_out[1]=91; idx_out[2]=92; idx_out[3]=93; idx_out[4]=94; idx_out[5]=95; end
      16: begin idx_out[0]=96; idx_out[1]=97; idx_out[2]=98; idx_out[3]=99; idx_out[4]=100; idx_out[5]=101; end
      17: begin idx_out[0]=102; idx_out[1]=103; idx_out[2]=104; idx_out[3]=105; idx_out[4]=106; idx_out[5]=107; end
      18: begin idx_out[0]=108; idx_out[1]=109; idx_out[2]=110; idx_out[3]=111; idx_out[4]=112; idx_out[5]=113; end
      19: begin idx_out[0]=114; idx_out[1]=115; idx_out[2]=116; idx_out[3]=117; idx_out[4]=118; idx_out[5]=119; end
      20: begin idx_out[0]=120; idx_out[1]=121; idx_out[2]=122; idx_out[3]=123; idx_out[4]=124; idx_out[5]=125; end
      21: begin idx_out[0]=126; idx_out[1]=127; idx_out[2]=128; idx_out[3]=129; idx_out[4]=130; idx_out[5]=131; end
      22: begin idx_out[0]=132; idx_out[1]=133; idx_out[2]=134; idx_out[3]=135; idx_out[4]=136; idx_out[5]=137; end
      23: begin idx_out[0]=138; idx_out[1]=139; idx_out[2]=140; idx_out[3]=141; idx_out[4]=142; idx_out[5]=143; end
    endcase
  end

endmodule
