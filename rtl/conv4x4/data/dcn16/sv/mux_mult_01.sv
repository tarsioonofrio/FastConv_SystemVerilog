//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 1;
  parameter int STATE_MULT = 144;
endpackage


module MuxMult
  (
    input  logic[$clog2(144-1):0] idx_in, // current state
    output logic[$clog2(144*1-1):0] idx_out[0:1-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; end
      1: begin idx_out[0]=1; end
      2: begin idx_out[0]=2; end
      3: begin idx_out[0]=3; end
      4: begin idx_out[0]=4; end
      5: begin idx_out[0]=5; end
      6: begin idx_out[0]=6; end
      7: begin idx_out[0]=7; end
      8: begin idx_out[0]=8; end
      9: begin idx_out[0]=9; end
      10: begin idx_out[0]=10; end
      11: begin idx_out[0]=11; end
      12: begin idx_out[0]=12; end
      13: begin idx_out[0]=13; end
      14: begin idx_out[0]=14; end
      15: begin idx_out[0]=15; end
      16: begin idx_out[0]=16; end
      17: begin idx_out[0]=17; end
      18: begin idx_out[0]=18; end
      19: begin idx_out[0]=19; end
      20: begin idx_out[0]=20; end
      21: begin idx_out[0]=21; end
      22: begin idx_out[0]=22; end
      23: begin idx_out[0]=23; end
      24: begin idx_out[0]=24; end
      25: begin idx_out[0]=25; end
      26: begin idx_out[0]=26; end
      27: begin idx_out[0]=27; end
      28: begin idx_out[0]=28; end
      29: begin idx_out[0]=29; end
      30: begin idx_out[0]=30; end
      31: begin idx_out[0]=31; end
      32: begin idx_out[0]=32; end
      33: begin idx_out[0]=33; end
      34: begin idx_out[0]=34; end
      35: begin idx_out[0]=35; end
      36: begin idx_out[0]=36; end
      37: begin idx_out[0]=37; end
      38: begin idx_out[0]=38; end
      39: begin idx_out[0]=39; end
      40: begin idx_out[0]=40; end
      41: begin idx_out[0]=41; end
      42: begin idx_out[0]=42; end
      43: begin idx_out[0]=43; end
      44: begin idx_out[0]=44; end
      45: begin idx_out[0]=45; end
      46: begin idx_out[0]=46; end
      47: begin idx_out[0]=47; end
      48: begin idx_out[0]=48; end
      49: begin idx_out[0]=49; end
      50: begin idx_out[0]=50; end
      51: begin idx_out[0]=51; end
      52: begin idx_out[0]=52; end
      53: begin idx_out[0]=53; end
      54: begin idx_out[0]=54; end
      55: begin idx_out[0]=55; end
      56: begin idx_out[0]=56; end
      57: begin idx_out[0]=57; end
      58: begin idx_out[0]=58; end
      59: begin idx_out[0]=59; end
      60: begin idx_out[0]=60; end
      61: begin idx_out[0]=61; end
      62: begin idx_out[0]=62; end
      63: begin idx_out[0]=63; end
      64: begin idx_out[0]=64; end
      65: begin idx_out[0]=65; end
      66: begin idx_out[0]=66; end
      67: begin idx_out[0]=67; end
      68: begin idx_out[0]=68; end
      69: begin idx_out[0]=69; end
      70: begin idx_out[0]=70; end
      71: begin idx_out[0]=71; end
      72: begin idx_out[0]=72; end
      73: begin idx_out[0]=73; end
      74: begin idx_out[0]=74; end
      75: begin idx_out[0]=75; end
      76: begin idx_out[0]=76; end
      77: begin idx_out[0]=77; end
      78: begin idx_out[0]=78; end
      79: begin idx_out[0]=79; end
      80: begin idx_out[0]=80; end
      81: begin idx_out[0]=81; end
      82: begin idx_out[0]=82; end
      83: begin idx_out[0]=83; end
      84: begin idx_out[0]=84; end
      85: begin idx_out[0]=85; end
      86: begin idx_out[0]=86; end
      87: begin idx_out[0]=87; end
      88: begin idx_out[0]=88; end
      89: begin idx_out[0]=89; end
      90: begin idx_out[0]=90; end
      91: begin idx_out[0]=91; end
      92: begin idx_out[0]=92; end
      93: begin idx_out[0]=93; end
      94: begin idx_out[0]=94; end
      95: begin idx_out[0]=95; end
      96: begin idx_out[0]=96; end
      97: begin idx_out[0]=97; end
      98: begin idx_out[0]=98; end
      99: begin idx_out[0]=99; end
      100: begin idx_out[0]=100; end
      101: begin idx_out[0]=101; end
      102: begin idx_out[0]=102; end
      103: begin idx_out[0]=103; end
      104: begin idx_out[0]=104; end
      105: begin idx_out[0]=105; end
      106: begin idx_out[0]=106; end
      107: begin idx_out[0]=107; end
      108: begin idx_out[0]=108; end
      109: begin idx_out[0]=109; end
      110: begin idx_out[0]=110; end
      111: begin idx_out[0]=111; end
      112: begin idx_out[0]=112; end
      113: begin idx_out[0]=113; end
      114: begin idx_out[0]=114; end
      115: begin idx_out[0]=115; end
      116: begin idx_out[0]=116; end
      117: begin idx_out[0]=117; end
      118: begin idx_out[0]=118; end
      119: begin idx_out[0]=119; end
      120: begin idx_out[0]=120; end
      121: begin idx_out[0]=121; end
      122: begin idx_out[0]=122; end
      123: begin idx_out[0]=123; end
      124: begin idx_out[0]=124; end
      125: begin idx_out[0]=125; end
      126: begin idx_out[0]=126; end
      127: begin idx_out[0]=127; end
      128: begin idx_out[0]=128; end
      129: begin idx_out[0]=129; end
      130: begin idx_out[0]=130; end
      131: begin idx_out[0]=131; end
      132: begin idx_out[0]=132; end
      133: begin idx_out[0]=133; end
      134: begin idx_out[0]=134; end
      135: begin idx_out[0]=135; end
      136: begin idx_out[0]=136; end
      137: begin idx_out[0]=137; end
      138: begin idx_out[0]=138; end
      139: begin idx_out[0]=139; end
      140: begin idx_out[0]=140; end
      141: begin idx_out[0]=141; end
      142: begin idx_out[0]=142; end
      143: begin idx_out[0]=143; end
    endcase
  end

endmodule
