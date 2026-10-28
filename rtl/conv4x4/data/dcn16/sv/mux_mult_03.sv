//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 3;
  parameter int STATE_MULT = 48;
endpackage


module MuxMult
  (
    input  logic[$clog2(48-1):0] idx_in, // current state
    output logic[$clog2(48*3-1):0] idx_out[0:3-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; end
      1: begin idx_out[0]=3; idx_out[1]=4; idx_out[2]=5; end
      2: begin idx_out[0]=6; idx_out[1]=7; idx_out[2]=8; end
      3: begin idx_out[0]=9; idx_out[1]=10; idx_out[2]=11; end
      4: begin idx_out[0]=12; idx_out[1]=13; idx_out[2]=14; end
      5: begin idx_out[0]=15; idx_out[1]=16; idx_out[2]=17; end
      6: begin idx_out[0]=18; idx_out[1]=19; idx_out[2]=20; end
      7: begin idx_out[0]=21; idx_out[1]=22; idx_out[2]=23; end
      8: begin idx_out[0]=24; idx_out[1]=25; idx_out[2]=26; end
      9: begin idx_out[0]=27; idx_out[1]=28; idx_out[2]=29; end
      10: begin idx_out[0]=30; idx_out[1]=31; idx_out[2]=32; end
      11: begin idx_out[0]=33; idx_out[1]=34; idx_out[2]=35; end
      12: begin idx_out[0]=36; idx_out[1]=37; idx_out[2]=38; end
      13: begin idx_out[0]=39; idx_out[1]=40; idx_out[2]=41; end
      14: begin idx_out[0]=42; idx_out[1]=43; idx_out[2]=44; end
      15: begin idx_out[0]=45; idx_out[1]=46; idx_out[2]=47; end
      16: begin idx_out[0]=48; idx_out[1]=49; idx_out[2]=50; end
      17: begin idx_out[0]=51; idx_out[1]=52; idx_out[2]=53; end
      18: begin idx_out[0]=54; idx_out[1]=55; idx_out[2]=56; end
      19: begin idx_out[0]=57; idx_out[1]=58; idx_out[2]=59; end
      20: begin idx_out[0]=60; idx_out[1]=61; idx_out[2]=62; end
      21: begin idx_out[0]=63; idx_out[1]=64; idx_out[2]=65; end
      22: begin idx_out[0]=66; idx_out[1]=67; idx_out[2]=68; end
      23: begin idx_out[0]=69; idx_out[1]=70; idx_out[2]=71; end
      24: begin idx_out[0]=72; idx_out[1]=73; idx_out[2]=74; end
      25: begin idx_out[0]=75; idx_out[1]=76; idx_out[2]=77; end
      26: begin idx_out[0]=78; idx_out[1]=79; idx_out[2]=80; end
      27: begin idx_out[0]=81; idx_out[1]=82; idx_out[2]=83; end
      28: begin idx_out[0]=84; idx_out[1]=85; idx_out[2]=86; end
      29: begin idx_out[0]=87; idx_out[1]=88; idx_out[2]=89; end
      30: begin idx_out[0]=90; idx_out[1]=91; idx_out[2]=92; end
      31: begin idx_out[0]=93; idx_out[1]=94; idx_out[2]=95; end
      32: begin idx_out[0]=96; idx_out[1]=97; idx_out[2]=98; end
      33: begin idx_out[0]=99; idx_out[1]=100; idx_out[2]=101; end
      34: begin idx_out[0]=102; idx_out[1]=103; idx_out[2]=104; end
      35: begin idx_out[0]=105; idx_out[1]=106; idx_out[2]=107; end
      36: begin idx_out[0]=108; idx_out[1]=109; idx_out[2]=110; end
      37: begin idx_out[0]=111; idx_out[1]=112; idx_out[2]=113; end
      38: begin idx_out[0]=114; idx_out[1]=115; idx_out[2]=116; end
      39: begin idx_out[0]=117; idx_out[1]=118; idx_out[2]=119; end
      40: begin idx_out[0]=120; idx_out[1]=121; idx_out[2]=122; end
      41: begin idx_out[0]=123; idx_out[1]=124; idx_out[2]=125; end
      42: begin idx_out[0]=126; idx_out[1]=127; idx_out[2]=128; end
      43: begin idx_out[0]=129; idx_out[1]=130; idx_out[2]=131; end
      44: begin idx_out[0]=132; idx_out[1]=133; idx_out[2]=134; end
      45: begin idx_out[0]=135; idx_out[1]=136; idx_out[2]=137; end
      46: begin idx_out[0]=138; idx_out[1]=139; idx_out[2]=140; end
      47: begin idx_out[0]=141; idx_out[1]=142; idx_out[2]=143; end
    endcase
  end

endmodule
