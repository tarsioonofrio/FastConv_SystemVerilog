module Transform
  import pack_typedef::*;
  (
    input  type_input pin,
    output type_weight pout
  );
  timeunit 1ns;
  timeprecision 1ps;

  type_matrix_c partial;

  // Instance of matrix multiplier "C"
  MatrixC0 matrix_c0(
    .P(pin),
    .soma(partial)
  );
  MatrixC1 matrix_c1(
    .P(partial),
    .soma(pout)
  );
endmodule



module Inverse
  import pack_typedef::*;
  (
    input  type_weight pin,
    output type_output pout
 );
  timeunit 1ns;
  timeprecision 1ps;

  type_matrix_a partial;

  MatrixA1 matrix_a1 (
    .P(pin),
    .soma(partial)
  );
  MatrixA0 matrix_a0 (
    .P(partial),
    .soma(pout)
  );
endmodule


module MatrixC0
  import pack_typedef::*;
  (
    input  type_input P,
    output type_matrix_c soma
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic_vector sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24, sp25, sp26, sp27, sp28, sp29, sp30, sp31, sp32, sp33, sp34, sp35, sp36, sp37, sp38, sp39, sp40, sp41, sp42, sp43, sp44, sp45, sp46, sp47;
  logic_vector sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24, sn25, sn26, sn27, sn28, sn29, sn30, sn31, sn32, sn33, sn34, sn35, sn36, sn37, sn38, sn39, sn40, sn41, sn42, sn43, sn44, sn45, sn46, sn47;

  assign sp0 = P[0];
  CSA_2 csa_p1(P[2], P[4], sp1);
  CSA_2 csa_p2(P[1], P[3], sp2);
  CSA_2 csa_p3(P[2], P[4], sp3);
  CSA_2 csa_p4(P[3], P[4], sp4);
  assign sp5 = P[1];
  CSA_2 csa_p6(P[2], P[3], sp6);
  assign sp7 = P[5];
  assign sp8 = P[6];
  CSA_2 csa_p9(P[8], P[10], sp9);
  CSA_2 csa_p10(P[7], P[9], sp10);
  CSA_2 csa_p11(P[8], P[10], sp11);
  CSA_2 csa_p12(P[9], P[10], sp12);
  assign sp13 = P[7];
  CSA_2 csa_p14(P[8], P[9], sp14);
  assign sp15 = P[11];
  assign sp16 = P[12];
  CSA_2 csa_p17(P[14], P[16], sp17);
  CSA_2 csa_p18(P[13], P[15], sp18);
  CSA_2 csa_p19(P[14], P[16], sp19);
  CSA_2 csa_p20(P[15], P[16], sp20);
  assign sp21 = P[13];
  CSA_2 csa_p22(P[14], P[15], sp22);
  assign sp23 = P[17];
  assign sp24 = P[18];
  CSA_2 csa_p25(P[20], P[22], sp25);
  CSA_2 csa_p26(P[19], P[21], sp26);
  CSA_2 csa_p27(P[20], P[22], sp27);
  CSA_2 csa_p28(P[21], P[22], sp28);
  assign sp29 = P[19];
  CSA_2 csa_p30(P[20], P[21], sp30);
  assign sp31 = P[23];
  assign sp32 = P[24];
  CSA_2 csa_p33(P[26], P[28], sp33);
  CSA_2 csa_p34(P[25], P[27], sp34);
  CSA_2 csa_p35(P[26], P[28], sp35);
  CSA_2 csa_p36(P[27], P[28], sp36);
  assign sp37 = P[25];
  CSA_2 csa_p38(P[26], P[27], sp38);
  assign sp39 = P[29];
  assign sp40 = P[30];
  CSA_2 csa_p41(P[32], P[34], sp41);
  CSA_2 csa_p42(P[31], P[33], sp42);
  CSA_2 csa_p43(P[32], P[34], sp43);
  CSA_2 csa_p44(P[33], P[34], sp44);
  assign sp45 = P[31];
  CSA_2 csa_p46(P[32], P[33], sp46);
  assign sp47 = P[35];
  assign sn0 = P[4];
  CSA_2 csa_n1(P[1], P[3], sn1);
  CSA_2 csa_n3(P[1], P[3], sn3);
  CSA_2 csa_n4(P[1], P[2], sn4);
  assign sn5 = P[3];
  CSA_2 csa_n6(P[1], P[4], sn6);
  assign sn7 = P[1];
  assign sn8 = P[10];
  CSA_2 csa_n9(P[7], P[9], sn9);
  CSA_2 csa_n11(P[7], P[9], sn11);
  CSA_2 csa_n12(P[7], P[8], sn12);
  assign sn13 = P[9];
  CSA_2 csa_n14(P[7], P[10], sn14);
  assign sn15 = P[7];
  assign sn16 = P[16];
  CSA_2 csa_n17(P[13], P[15], sn17);
  CSA_2 csa_n19(P[13], P[15], sn19);
  CSA_2 csa_n20(P[13], P[14], sn20);
  assign sn21 = P[15];
  CSA_2 csa_n22(P[13], P[16], sn22);
  assign sn23 = P[13];
  assign sn24 = P[22];
  CSA_2 csa_n25(P[19], P[21], sn25);
  CSA_2 csa_n27(P[19], P[21], sn27);
  CSA_2 csa_n28(P[19], P[20], sn28);
  assign sn29 = P[21];
  CSA_2 csa_n30(P[19], P[22], sn30);
  assign sn31 = P[19];
  assign sn32 = P[28];
  CSA_2 csa_n33(P[25], P[27], sn33);
  CSA_2 csa_n35(P[25], P[27], sn35);
  CSA_2 csa_n36(P[25], P[26], sn36);
  assign sn37 = P[27];
  CSA_2 csa_n38(P[25], P[28], sn38);
  assign sn39 = P[25];
  assign sn40 = P[34];
  CSA_2 csa_n41(P[31], P[33], sn41);
  CSA_2 csa_n43(P[31], P[33], sn43);
  CSA_2 csa_n44(P[31], P[32], sn44);
  assign sn45 = P[33];
  CSA_2 csa_n46(P[31], P[34], sn46);
  assign sn47 = P[31];
  assign soma[0] = sp0 - sn0;
  assign soma[1] = sp1 - sn1;
  assign soma[2] = sp2;
  assign soma[3] = sp3 - sn3;
  assign soma[4] = sp4 - sn4;
  assign soma[5] = sp5 - sn5;
  assign soma[6] = sp6 - sn6;
  assign soma[7] = sp7 - sn7;
  assign soma[8] = sp8 - sn8;
  assign soma[9] = sp9 - sn9;
  assign soma[10] = sp10;
  assign soma[11] = sp11 - sn11;
  assign soma[12] = sp12 - sn12;
  assign soma[13] = sp13 - sn13;
  assign soma[14] = sp14 - sn14;
  assign soma[15] = sp15 - sn15;
  assign soma[16] = sp16 - sn16;
  assign soma[17] = sp17 - sn17;
  assign soma[18] = sp18;
  assign soma[19] = sp19 - sn19;
  assign soma[20] = sp20 - sn20;
  assign soma[21] = sp21 - sn21;
  assign soma[22] = sp22 - sn22;
  assign soma[23] = sp23 - sn23;
  assign soma[24] = sp24 - sn24;
  assign soma[25] = sp25 - sn25;
  assign soma[26] = sp26;
  assign soma[27] = sp27 - sn27;
  assign soma[28] = sp28 - sn28;
  assign soma[29] = sp29 - sn29;
  assign soma[30] = sp30 - sn30;
  assign soma[31] = sp31 - sn31;
  assign soma[32] = sp32 - sn32;
  assign soma[33] = sp33 - sn33;
  assign soma[34] = sp34;
  assign soma[35] = sp35 - sn35;
  assign soma[36] = sp36 - sn36;
  assign soma[37] = sp37 - sn37;
  assign soma[38] = sp38 - sn38;
  assign soma[39] = sp39 - sn39;
  assign soma[40] = sp40 - sn40;
  assign soma[41] = sp41 - sn41;
  assign soma[42] = sp42;
  assign soma[43] = sp43 - sn43;
  assign soma[44] = sp44 - sn44;
  assign soma[45] = sp45 - sn45;
  assign soma[46] = sp46 - sn46;
  assign soma[47] = sp47 - sn47;
endmodule


module MatrixC1
  import pack_typedef::*;
  (
    input  type_matrix_c P,
    output type_weight soma
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic_vector sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24, sp25, sp26, sp27, sp28, sp29, sp30, sp31, sp32, sp33, sp34, sp35, sp36, sp37, sp38, sp39, sp40, sp41, sp42, sp43, sp44, sp45, sp46, sp47, sp48, sp49, sp50, sp51, sp52, sp53, sp54, sp55, sp56, sp57, sp58, sp59, sp60, sp61, sp62, sp63;
  logic_vector sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24, sn25, sn26, sn27, sn28, sn29, sn30, sn31, sn32, sn33, sn34, sn35, sn36, sn37, sn38, sn39, sn40, sn41, sn42, sn43, sn44, sn45, sn46, sn47, sn48, sn49, sn50, sn51, sn52, sn53, sn54, sn55, sn56, sn57, sn58, sn59, sn60, sn61, sn62, sn63;

  assign sp0 = P[0];
  assign sp1 = P[1];
  assign sp2 = P[2];
  assign sp3 = P[3];
  assign sp4 = P[4];
  assign sp5 = P[5];
  assign sp6 = P[6];
  assign sp7 = P[7];
  CSA_2 csa_p8(P[16], P[32], sp8);
  CSA_2 csa_p9(P[17], P[33], sp9);
  CSA_2 csa_p10(P[18], P[34], sp10);
  CSA_2 csa_p11(P[19], P[35], sp11);
  CSA_2 csa_p12(P[20], P[36], sp12);
  CSA_2 csa_p13(P[21], P[37], sp13);
  CSA_2 csa_p14(P[22], P[38], sp14);
  CSA_2 csa_p15(P[23], P[39], sp15);
  CSA_2 csa_p16(P[8], P[24], sp16);
  CSA_2 csa_p17(P[9], P[25], sp17);
  CSA_2 csa_p18(P[10], P[26], sp18);
  CSA_2 csa_p19(P[11], P[27], sp19);
  CSA_2 csa_p20(P[12], P[28], sp20);
  CSA_2 csa_p21(P[13], P[29], sp21);
  CSA_2 csa_p22(P[14], P[30], sp22);
  CSA_2 csa_p23(P[15], P[31], sp23);
  CSA_2 csa_p24(P[16], P[32], sp24);
  CSA_2 csa_p25(P[17], P[33], sp25);
  CSA_2 csa_p26(P[18], P[34], sp26);
  CSA_2 csa_p27(P[19], P[35], sp27);
  CSA_2 csa_p28(P[20], P[36], sp28);
  CSA_2 csa_p29(P[21], P[37], sp29);
  CSA_2 csa_p30(P[22], P[38], sp30);
  CSA_2 csa_p31(P[23], P[39], sp31);
  CSA_2 csa_p32(P[24], P[32], sp32);
  CSA_2 csa_p33(P[25], P[33], sp33);
  CSA_2 csa_p34(P[26], P[34], sp34);
  CSA_2 csa_p35(P[27], P[35], sp35);
  CSA_2 csa_p36(P[28], P[36], sp36);
  CSA_2 csa_p37(P[29], P[37], sp37);
  CSA_2 csa_p38(P[30], P[38], sp38);
  CSA_2 csa_p39(P[31], P[39], sp39);
  assign sp40 = P[8];
  assign sp41 = P[9];
  assign sp42 = P[10];
  assign sp43 = P[11];
  assign sp44 = P[12];
  assign sp45 = P[13];
  assign sp46 = P[14];
  assign sp47 = P[15];
  CSA_2 csa_p48(P[16], P[24], sp48);
  CSA_2 csa_p49(P[17], P[25], sp49);
  CSA_2 csa_p50(P[18], P[26], sp50);
  CSA_2 csa_p51(P[19], P[27], sp51);
  CSA_2 csa_p52(P[20], P[28], sp52);
  CSA_2 csa_p53(P[21], P[29], sp53);
  CSA_2 csa_p54(P[22], P[30], sp54);
  CSA_2 csa_p55(P[23], P[31], sp55);
  assign sp56 = P[40];
  assign sp57 = P[41];
  assign sp58 = P[42];
  assign sp59 = P[43];
  assign sp60 = P[44];
  assign sp61 = P[45];
  assign sp62 = P[46];
  assign sp63 = P[47];
  assign sn0 = P[32];
  assign sn1 = P[33];
  assign sn2 = P[34];
  assign sn3 = P[35];
  assign sn4 = P[36];
  assign sn5 = P[37];
  assign sn6 = P[38];
  assign sn7 = P[39];
  CSA_2 csa_n8(P[8], P[24], sn8);
  CSA_2 csa_n9(P[9], P[25], sn9);
  CSA_2 csa_n10(P[10], P[26], sn10);
  CSA_2 csa_n11(P[11], P[27], sn11);
  CSA_2 csa_n12(P[12], P[28], sn12);
  CSA_2 csa_n13(P[13], P[29], sn13);
  CSA_2 csa_n14(P[14], P[30], sn14);
  CSA_2 csa_n15(P[15], P[31], sn15);
  CSA_2 csa_n24(P[8], P[24], sn24);
  CSA_2 csa_n25(P[9], P[25], sn25);
  CSA_2 csa_n26(P[10], P[26], sn26);
  CSA_2 csa_n27(P[11], P[27], sn27);
  CSA_2 csa_n28(P[12], P[28], sn28);
  CSA_2 csa_n29(P[13], P[29], sn29);
  CSA_2 csa_n30(P[14], P[30], sn30);
  CSA_2 csa_n31(P[15], P[31], sn31);
  CSA_2 csa_n32(P[8], P[16], sn32);
  CSA_2 csa_n33(P[9], P[17], sn33);
  CSA_2 csa_n34(P[10], P[18], sn34);
  CSA_2 csa_n35(P[11], P[19], sn35);
  CSA_2 csa_n36(P[12], P[20], sn36);
  CSA_2 csa_n37(P[13], P[21], sn37);
  CSA_2 csa_n38(P[14], P[22], sn38);
  CSA_2 csa_n39(P[15], P[23], sn39);
  assign sn40 = P[24];
  assign sn41 = P[25];
  assign sn42 = P[26];
  assign sn43 = P[27];
  assign sn44 = P[28];
  assign sn45 = P[29];
  assign sn46 = P[30];
  assign sn47 = P[31];
  CSA_2 csa_n48(P[8], P[32], sn48);
  CSA_2 csa_n49(P[9], P[33], sn49);
  CSA_2 csa_n50(P[10], P[34], sn50);
  CSA_2 csa_n51(P[11], P[35], sn51);
  CSA_2 csa_n52(P[12], P[36], sn52);
  CSA_2 csa_n53(P[13], P[37], sn53);
  CSA_2 csa_n54(P[14], P[38], sn54);
  CSA_2 csa_n55(P[15], P[39], sn55);
  assign sn56 = P[8];
  assign sn57 = P[9];
  assign sn58 = P[10];
  assign sn59 = P[11];
  assign sn60 = P[12];
  assign sn61 = P[13];
  assign sn62 = P[14];
  assign sn63 = P[15];
  assign soma[0] = sp0 - sn0;
  assign soma[1] = sp1 - sn1;
  assign soma[2] = sp2 - sn2;
  assign soma[3] = sp3 - sn3;
  assign soma[4] = sp4 - sn4;
  assign soma[5] = sp5 - sn5;
  assign soma[6] = sp6 - sn6;
  assign soma[7] = sp7 - sn7;
  assign soma[8] = sp8 - sn8;
  assign soma[9] = sp9 - sn9;
  assign soma[10] = sp10 - sn10;
  assign soma[11] = sp11 - sn11;
  assign soma[12] = sp12 - sn12;
  assign soma[13] = sp13 - sn13;
  assign soma[14] = sp14 - sn14;
  assign soma[15] = sp15 - sn15;
  assign soma[16] = sp16;
  assign soma[17] = sp17;
  assign soma[18] = sp18;
  assign soma[19] = sp19;
  assign soma[20] = sp20;
  assign soma[21] = sp21;
  assign soma[22] = sp22;
  assign soma[23] = sp23;
  assign soma[24] = sp24 - sn24;
  assign soma[25] = sp25 - sn25;
  assign soma[26] = sp26 - sn26;
  assign soma[27] = sp27 - sn27;
  assign soma[28] = sp28 - sn28;
  assign soma[29] = sp29 - sn29;
  assign soma[30] = sp30 - sn30;
  assign soma[31] = sp31 - sn31;
  assign soma[32] = sp32 - sn32;
  assign soma[33] = sp33 - sn33;
  assign soma[34] = sp34 - sn34;
  assign soma[35] = sp35 - sn35;
  assign soma[36] = sp36 - sn36;
  assign soma[37] = sp37 - sn37;
  assign soma[38] = sp38 - sn38;
  assign soma[39] = sp39 - sn39;
  assign soma[40] = sp40 - sn40;
  assign soma[41] = sp41 - sn41;
  assign soma[42] = sp42 - sn42;
  assign soma[43] = sp43 - sn43;
  assign soma[44] = sp44 - sn44;
  assign soma[45] = sp45 - sn45;
  assign soma[46] = sp46 - sn46;
  assign soma[47] = sp47 - sn47;
  assign soma[48] = sp48 - sn48;
  assign soma[49] = sp49 - sn49;
  assign soma[50] = sp50 - sn50;
  assign soma[51] = sp51 - sn51;
  assign soma[52] = sp52 - sn52;
  assign soma[53] = sp53 - sn53;
  assign soma[54] = sp54 - sn54;
  assign soma[55] = sp55 - sn55;
  assign soma[56] = sp56 - sn56;
  assign soma[57] = sp57 - sn57;
  assign soma[58] = sp58 - sn58;
  assign soma[59] = sp59 - sn59;
  assign soma[60] = sp60 - sn60;
  assign soma[61] = sp61 - sn61;
  assign soma[62] = sp62 - sn62;
  assign soma[63] = sp63 - sn63;
endmodule


module MatrixA1
  import pack_typedef::*;
  (
    input  type_weight P,
    output type_matrix_a soma
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic_vector sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15, sp16, sp17, sp18, sp19, sp20, sp21, sp22, sp23, sp24, sp25, sp26, sp27, sp28, sp29, sp30, sp31;
  logic_vector sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15, sn16, sn17, sn18, sn19, sn20, sn21, sn22, sn23, sn24, sn25, sn26, sn27, sn28, sn29, sn30, sn31;

  CSA_5 csa_p0(P[0], P[1], P[2], P[4], P[5], sp0);
  CSA_4 csa_p1(P[2], P[3], P[5], P[6], sp1);
  CSA_2 csa_p2(P[1], P[2], sp2);
  CSA_3 csa_p3(P[2], P[3], P[7], sp3);
  CSA_5 csa_p4(P[8], P[9], P[10], P[12], P[13], sp4);
  CSA_4 csa_p5(P[10], P[11], P[13], P[14], sp5);
  CSA_2 csa_p6(P[9], P[10], sp6);
  CSA_3 csa_p7(P[10], P[11], P[15], sp7);
  CSA_5 csa_p8(P[16], P[17], P[18], P[20], P[21], sp8);
  CSA_4 csa_p9(P[18], P[19], P[21], P[22], sp9);
  CSA_2 csa_p10(P[17], P[18], sp10);
  CSA_3 csa_p11(P[18], P[19], P[23], sp11);
  CSA_5 csa_p12(P[24], P[25], P[26], P[28], P[29], sp12);
  CSA_4 csa_p13(P[26], P[27], P[29], P[30], sp13);
  CSA_2 csa_p14(P[25], P[26], sp14);
  CSA_3 csa_p15(P[26], P[27], P[31], sp15);
  CSA_5 csa_p16(P[32], P[33], P[34], P[36], P[37], sp16);
  CSA_4 csa_p17(P[34], P[35], P[37], P[38], sp17);
  CSA_2 csa_p18(P[33], P[34], sp18);
  CSA_3 csa_p19(P[34], P[35], P[39], sp19);
  CSA_5 csa_p20(P[40], P[41], P[42], P[44], P[45], sp20);
  CSA_4 csa_p21(P[42], P[43], P[45], P[46], sp21);
  CSA_2 csa_p22(P[41], P[42], sp22);
  CSA_3 csa_p23(P[42], P[43], P[47], sp23);
  CSA_5 csa_p24(P[48], P[49], P[50], P[52], P[53], sp24);
  CSA_4 csa_p25(P[50], P[51], P[53], P[54], sp25);
  CSA_2 csa_p26(P[49], P[50], sp26);
  CSA_3 csa_p27(P[50], P[51], P[55], sp27);
  CSA_5 csa_p28(P[56], P[57], P[58], P[60], P[61], sp28);
  CSA_4 csa_p29(P[58], P[59], P[61], P[62], sp29);
  CSA_2 csa_p30(P[57], P[58], sp30);
  CSA_3 csa_p31(P[58], P[59], P[63], sp31);
  CSA_2 csa_n2(P[4], P[5], sn2);
  CSA_2 csa_n3(P[5], P[6], sn3);
  CSA_2 csa_n6(P[12], P[13], sn6);
  CSA_2 csa_n7(P[13], P[14], sn7);
  CSA_2 csa_n10(P[20], P[21], sn10);
  CSA_2 csa_n11(P[21], P[22], sn11);
  CSA_2 csa_n14(P[28], P[29], sn14);
  CSA_2 csa_n15(P[29], P[30], sn15);
  CSA_2 csa_n18(P[36], P[37], sn18);
  CSA_2 csa_n19(P[37], P[38], sn19);
  CSA_2 csa_n22(P[44], P[45], sn22);
  CSA_2 csa_n23(P[45], P[46], sn23);
  CSA_2 csa_n26(P[52], P[53], sn26);
  CSA_2 csa_n27(P[53], P[54], sn27);
  CSA_2 csa_n30(P[60], P[61], sn30);
  CSA_2 csa_n31(P[61], P[62], sn31);
  assign soma[0] = sp0;
  assign soma[1] = sp1;
  assign soma[2] = sp2 - sn2;
  assign soma[3] = sp3 - sn3;
  assign soma[4] = sp4;
  assign soma[5] = sp5;
  assign soma[6] = sp6 - sn6;
  assign soma[7] = sp7 - sn7;
  assign soma[8] = sp8;
  assign soma[9] = sp9;
  assign soma[10] = sp10 - sn10;
  assign soma[11] = sp11 - sn11;
  assign soma[12] = sp12;
  assign soma[13] = sp13;
  assign soma[14] = sp14 - sn14;
  assign soma[15] = sp15 - sn15;
  assign soma[16] = sp16;
  assign soma[17] = sp17;
  assign soma[18] = sp18 - sn18;
  assign soma[19] = sp19 - sn19;
  assign soma[20] = sp20;
  assign soma[21] = sp21;
  assign soma[22] = sp22 - sn22;
  assign soma[23] = sp23 - sn23;
  assign soma[24] = sp24;
  assign soma[25] = sp25;
  assign soma[26] = sp26 - sn26;
  assign soma[27] = sp27 - sn27;
  assign soma[28] = sp28;
  assign soma[29] = sp29;
  assign soma[30] = sp30 - sn30;
  assign soma[31] = sp31 - sn31;
endmodule


module MatrixA0
  import pack_typedef::*;
  (
    input  type_matrix_a P,
    output type_output soma
  );
  timeunit 1ns;
  timeprecision 1ps;
  logic_vector sp0, sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sp11, sp12, sp13, sp14, sp15;
  logic_vector sn0, sn1, sn2, sn3, sn4, sn5, sn6, sn7, sn8, sn9, sn10, sn11, sn12, sn13, sn14, sn15;

  CSA_5 csa_p0(P[0], P[4], P[8], P[16], P[20], sp0);
  CSA_5 csa_p1(P[1], P[5], P[9], P[17], P[21], sp1);
  CSA_5 csa_p2(P[2], P[6], P[10], P[18], P[22], sp2);
  CSA_5 csa_p3(P[3], P[7], P[11], P[19], P[23], sp3);
  CSA_4 csa_p4(P[8], P[12], P[20], P[24], sp4);
  CSA_4 csa_p5(P[9], P[13], P[21], P[25], sp5);
  CSA_4 csa_p6(P[10], P[14], P[22], P[26], sp6);
  CSA_4 csa_p7(P[11], P[15], P[23], P[27], sp7);
  CSA_2 csa_p8(P[4], P[8], sp8);
  CSA_2 csa_p9(P[5], P[9], sp9);
  CSA_2 csa_p10(P[6], P[10], sp10);
  CSA_2 csa_p11(P[7], P[11], sp11);
  CSA_3 csa_p12(P[8], P[12], P[28], sp12);
  CSA_3 csa_p13(P[9], P[13], P[29], sp13);
  CSA_3 csa_p14(P[10], P[14], P[30], sp14);
  CSA_3 csa_p15(P[11], P[15], P[31], sp15);
  CSA_2 csa_n8(P[16], P[20], sn8);
  CSA_2 csa_n9(P[17], P[21], sn9);
  CSA_2 csa_n10(P[18], P[22], sn10);
  CSA_2 csa_n11(P[19], P[23], sn11);
  CSA_2 csa_n12(P[20], P[24], sn12);
  CSA_2 csa_n13(P[21], P[25], sn13);
  CSA_2 csa_n14(P[22], P[26], sn14);
  CSA_2 csa_n15(P[23], P[27], sn15);
  assign soma[0] = sp0;
  assign soma[1] = sp1;
  assign soma[2] = sp2;
  assign soma[3] = sp3;
  assign soma[4] = sp4;
  assign soma[5] = sp5;
  assign soma[6] = sp6;
  assign soma[7] = sp7;
  assign soma[8] = sp8 - sn8;
  assign soma[9] = sp9 - sn9;
  assign soma[10] = sp10 - sn10;
  assign soma[11] = sp11 - sn11;
  assign soma[12] = sp12 - sn12;
  assign soma[13] = sp13 - sn13;
  assign soma[14] = sp14 - sn14;
  assign soma[15] = sp15 - sn15;
endmodule
