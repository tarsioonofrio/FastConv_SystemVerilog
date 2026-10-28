//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 8;
  parameter int STATE_MULT = 18;
endpackage


module MuxMult
  (
    input  logic[$clog2(18-1):0] idx_in, // current state
    output logic[$clog2(18*8-1):0] idx_out[0:8-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; end
      1: begin idx_out[0]=8; idx_out[1]=9; idx_out[2]=10; idx_out[3]=11; idx_out[4]=12; idx_out[5]=13; idx_out[6]=14; idx_out[7]=15; end
      2: begin idx_out[0]=16; idx_out[1]=17; idx_out[2]=18; idx_out[3]=19; idx_out[4]=20; idx_out[5]=21; idx_out[6]=22; idx_out[7]=23; end
      3: begin idx_out[0]=24; idx_out[1]=25; idx_out[2]=26; idx_out[3]=27; idx_out[4]=28; idx_out[5]=29; idx_out[6]=30; idx_out[7]=31; end
      4: begin idx_out[0]=32; idx_out[1]=33; idx_out[2]=34; idx_out[3]=35; idx_out[4]=36; idx_out[5]=37; idx_out[6]=38; idx_out[7]=39; end
      5: begin idx_out[0]=40; idx_out[1]=41; idx_out[2]=42; idx_out[3]=43; idx_out[4]=44; idx_out[5]=45; idx_out[6]=46; idx_out[7]=47; end
      6: begin idx_out[0]=48; idx_out[1]=49; idx_out[2]=50; idx_out[3]=51; idx_out[4]=52; idx_out[5]=53; idx_out[6]=54; idx_out[7]=55; end
      7: begin idx_out[0]=56; idx_out[1]=57; idx_out[2]=58; idx_out[3]=59; idx_out[4]=60; idx_out[5]=61; idx_out[6]=62; idx_out[7]=63; end
      8: begin idx_out[0]=64; idx_out[1]=65; idx_out[2]=66; idx_out[3]=67; idx_out[4]=68; idx_out[5]=69; idx_out[6]=70; idx_out[7]=71; end
      9: begin idx_out[0]=72; idx_out[1]=73; idx_out[2]=74; idx_out[3]=75; idx_out[4]=76; idx_out[5]=77; idx_out[6]=78; idx_out[7]=79; end
      10: begin idx_out[0]=80; idx_out[1]=81; idx_out[2]=82; idx_out[3]=83; idx_out[4]=84; idx_out[5]=85; idx_out[6]=86; idx_out[7]=87; end
      11: begin idx_out[0]=88; idx_out[1]=89; idx_out[2]=90; idx_out[3]=91; idx_out[4]=92; idx_out[5]=93; idx_out[6]=94; idx_out[7]=95; end
      12: begin idx_out[0]=96; idx_out[1]=97; idx_out[2]=98; idx_out[3]=99; idx_out[4]=100; idx_out[5]=101; idx_out[6]=102; idx_out[7]=103; end
      13: begin idx_out[0]=104; idx_out[1]=105; idx_out[2]=106; idx_out[3]=107; idx_out[4]=108; idx_out[5]=109; idx_out[6]=110; idx_out[7]=111; end
      14: begin idx_out[0]=112; idx_out[1]=113; idx_out[2]=114; idx_out[3]=115; idx_out[4]=116; idx_out[5]=117; idx_out[6]=118; idx_out[7]=119; end
      15: begin idx_out[0]=120; idx_out[1]=121; idx_out[2]=122; idx_out[3]=123; idx_out[4]=124; idx_out[5]=125; idx_out[6]=126; idx_out[7]=127; end
      16: begin idx_out[0]=128; idx_out[1]=129; idx_out[2]=130; idx_out[3]=131; idx_out[4]=132; idx_out[5]=133; idx_out[6]=134; idx_out[7]=135; end
      17: begin idx_out[0]=136; idx_out[1]=137; idx_out[2]=138; idx_out[3]=139; idx_out[4]=140; idx_out[5]=141; idx_out[6]=142; idx_out[7]=143; end
    endcase
  end

endmodule
