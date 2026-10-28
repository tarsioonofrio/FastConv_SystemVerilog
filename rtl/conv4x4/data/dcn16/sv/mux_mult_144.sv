//-------------------------------------------------------------------------
// Index multiplexer module for selecting register indices based on state
//-------------------------------------------------------------------------

package pack_mux_mult;
  parameter int NUM_MULT = 144;
  parameter int STATE_MULT = 1;
endpackage


module MuxMult
  (
    input  logic[$clog2(1-1):0] idx_in, // current state
    output logic[$clog2(1*144-1):0] idx_out[0:144-1]  // index array output
  );

  timeunit 1ns;
  timeprecision 1ps;

  always_comb begin
    unique case (idx_in)
      default: begin idx_out[0]=0; idx_out[1]=1; idx_out[2]=2; idx_out[3]=3; idx_out[4]=4; idx_out[5]=5; idx_out[6]=6; idx_out[7]=7; idx_out[8]=8; idx_out[9]=9; idx_out[10]=10; idx_out[11]=11; idx_out[12]=12; idx_out[13]=13; idx_out[14]=14; idx_out[15]=15; idx_out[16]=16; idx_out[17]=17; idx_out[18]=18; idx_out[19]=19; idx_out[20]=20; idx_out[21]=21; idx_out[22]=22; idx_out[23]=23; idx_out[24]=24; idx_out[25]=25; idx_out[26]=26; idx_out[27]=27; idx_out[28]=28; idx_out[29]=29; idx_out[30]=30; idx_out[31]=31; idx_out[32]=32; idx_out[33]=33; idx_out[34]=34; idx_out[35]=35; idx_out[36]=36; idx_out[37]=37; idx_out[38]=38; idx_out[39]=39; idx_out[40]=40; idx_out[41]=41; idx_out[42]=42; idx_out[43]=43; idx_out[44]=44; idx_out[45]=45; idx_out[46]=46; idx_out[47]=47; idx_out[48]=48; idx_out[49]=49; idx_out[50]=50; idx_out[51]=51; idx_out[52]=52; idx_out[53]=53; idx_out[54]=54; idx_out[55]=55; idx_out[56]=56; idx_out[57]=57; idx_out[58]=58; idx_out[59]=59; idx_out[60]=60; idx_out[61]=61; idx_out[62]=62; idx_out[63]=63; idx_out[64]=64; idx_out[65]=65; idx_out[66]=66; idx_out[67]=67; idx_out[68]=68; idx_out[69]=69; idx_out[70]=70; idx_out[71]=71; idx_out[72]=72; idx_out[73]=73; idx_out[74]=74; idx_out[75]=75; idx_out[76]=76; idx_out[77]=77; idx_out[78]=78; idx_out[79]=79; idx_out[80]=80; idx_out[81]=81; idx_out[82]=82; idx_out[83]=83; idx_out[84]=84; idx_out[85]=85; idx_out[86]=86; idx_out[87]=87; idx_out[88]=88; idx_out[89]=89; idx_out[90]=90; idx_out[91]=91; idx_out[92]=92; idx_out[93]=93; idx_out[94]=94; idx_out[95]=95; idx_out[96]=96; idx_out[97]=97; idx_out[98]=98; idx_out[99]=99; idx_out[100]=100; idx_out[101]=101; idx_out[102]=102; idx_out[103]=103; idx_out[104]=104; idx_out[105]=105; idx_out[106]=106; idx_out[107]=107; idx_out[108]=108; idx_out[109]=109; idx_out[110]=110; idx_out[111]=111; idx_out[112]=112; idx_out[113]=113; idx_out[114]=114; idx_out[115]=115; idx_out[116]=116; idx_out[117]=117; idx_out[118]=118; idx_out[119]=119; idx_out[120]=120; idx_out[121]=121; idx_out[122]=122; idx_out[123]=123; idx_out[124]=124; idx_out[125]=125; idx_out[126]=126; idx_out[127]=127; idx_out[128]=128; idx_out[129]=129; idx_out[130]=130; idx_out[131]=131; idx_out[132]=132; idx_out[133]=133; idx_out[134]=134; idx_out[135]=135; idx_out[136]=136; idx_out[137]=137; idx_out[138]=138; idx_out[139]=139; idx_out[140]=140; idx_out[141]=141; idx_out[142]=142; idx_out[143]=143; end
    endcase
  end

endmodule
