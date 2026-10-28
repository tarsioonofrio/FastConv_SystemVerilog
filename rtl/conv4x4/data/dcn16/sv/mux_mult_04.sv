//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 4;
  parameter int STATE_MULT = 36;
endpackage


module MuxMult
  (
    input  logic[$clog2(36-1):0] idx_in, // current state
    output logic[$clog2(36*4-1):0] idx_out[0:4-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; end
      1: begin idx_out[0]=4; idx_out[1]=5; idx_out[2]=6; idx_out[3]=7; end
      2: begin idx_out[0]=8; idx_out[1]=9; idx_out[2]=10; idx_out[3]=11; end
      3: begin idx_out[0]=12; idx_out[1]=13; idx_out[2]=14; idx_out[3]=15; end
      4: begin idx_out[0]=16; idx_out[1]=17; idx_out[2]=18; idx_out[3]=19; end
      5: begin idx_out[0]=20; idx_out[1]=21; idx_out[2]=22; idx_out[3]=23; end
      6: begin idx_out[0]=24; idx_out[1]=25; idx_out[2]=26; idx_out[3]=27; end
      7: begin idx_out[0]=28; idx_out[1]=29; idx_out[2]=30; idx_out[3]=31; end
      8: begin idx_out[0]=32; idx_out[1]=33; idx_out[2]=34; idx_out[3]=35; end
      9: begin idx_out[0]=36; idx_out[1]=37; idx_out[2]=38; idx_out[3]=39; end
      10: begin idx_out[0]=40; idx_out[1]=41; idx_out[2]=42; idx_out[3]=43; end
      11: begin idx_out[0]=44; idx_out[1]=45; idx_out[2]=46; idx_out[3]=47; end
      12: begin idx_out[0]=48; idx_out[1]=49; idx_out[2]=50; idx_out[3]=51; end
      13: begin idx_out[0]=52; idx_out[1]=53; idx_out[2]=54; idx_out[3]=55; end
      14: begin idx_out[0]=56; idx_out[1]=57; idx_out[2]=58; idx_out[3]=59; end
      15: begin idx_out[0]=60; idx_out[1]=61; idx_out[2]=62; idx_out[3]=63; end
      16: begin idx_out[0]=64; idx_out[1]=65; idx_out[2]=66; idx_out[3]=67; end
      17: begin idx_out[0]=68; idx_out[1]=69; idx_out[2]=70; idx_out[3]=71; end
      18: begin idx_out[0]=72; idx_out[1]=73; idx_out[2]=74; idx_out[3]=75; end
      19: begin idx_out[0]=76; idx_out[1]=77; idx_out[2]=78; idx_out[3]=79; end
      20: begin idx_out[0]=80; idx_out[1]=81; idx_out[2]=82; idx_out[3]=83; end
      21: begin idx_out[0]=84; idx_out[1]=85; idx_out[2]=86; idx_out[3]=87; end
      22: begin idx_out[0]=88; idx_out[1]=89; idx_out[2]=90; idx_out[3]=91; end
      23: begin idx_out[0]=92; idx_out[1]=93; idx_out[2]=94; idx_out[3]=95; end
      24: begin idx_out[0]=96; idx_out[1]=97; idx_out[2]=98; idx_out[3]=99; end
      25: begin idx_out[0]=100; idx_out[1]=101; idx_out[2]=102; idx_out[3]=103; end
      26: begin idx_out[0]=104; idx_out[1]=105; idx_out[2]=106; idx_out[3]=107; end
      27: begin idx_out[0]=108; idx_out[1]=109; idx_out[2]=110; idx_out[3]=111; end
      28: begin idx_out[0]=112; idx_out[1]=113; idx_out[2]=114; idx_out[3]=115; end
      29: begin idx_out[0]=116; idx_out[1]=117; idx_out[2]=118; idx_out[3]=119; end
      30: begin idx_out[0]=120; idx_out[1]=121; idx_out[2]=122; idx_out[3]=123; end
      31: begin idx_out[0]=124; idx_out[1]=125; idx_out[2]=126; idx_out[3]=127; end
      32: begin idx_out[0]=128; idx_out[1]=129; idx_out[2]=130; idx_out[3]=131; end
      33: begin idx_out[0]=132; idx_out[1]=133; idx_out[2]=134; idx_out[3]=135; end
      34: begin idx_out[0]=136; idx_out[1]=137; idx_out[2]=138; idx_out[3]=139; end
      35: begin idx_out[0]=140; idx_out[1]=141; idx_out[2]=142; idx_out[3]=143; end
    endcase
  end

endmodule
