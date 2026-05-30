#include "optim.h"

void matrix_mul_shift_noloop_c2(int *m_out, const int *m_in){
	m_out[0] =  + (m_in[0] << 2) - m_in[2] - (m_in[2] << 2) + m_in[4];
	m_out[1] =  - (m_in[1] << 2) - (m_in[2] << 2) + m_in[3] + m_in[4];
	m_out[2] =  + (m_in[1] << 2) - (m_in[2] << 2) - m_in[3] + m_in[4];
	m_out[3] =  - (m_in[1] << 1) - m_in[2] + (m_in[3] << 1) + m_in[4];
	m_out[4] =  + (m_in[1] << 1) - m_in[2] - (m_in[3] << 1) + m_in[4];
	m_out[5] =  + (m_in[1] << 2) - m_in[3] - (m_in[3] << 2) + m_in[5];
	m_out[6] =  + (m_in[6] << 2) - m_in[8] - (m_in[8] << 2) + m_in[10];
	m_out[7] =  - (m_in[7] << 2) - (m_in[8] << 2) + m_in[9] + m_in[10];
	m_out[8] =  + (m_in[7] << 2) - (m_in[8] << 2) - m_in[9] + m_in[10];
	m_out[9] =  - (m_in[7] << 1) - m_in[8] + (m_in[9] << 1) + m_in[10];
	m_out[10] =  + (m_in[7] << 1) - m_in[8] - (m_in[9] << 1) + m_in[10];
	m_out[11] =  + (m_in[7] << 2) - m_in[9] - (m_in[9] << 2) + m_in[11];
	m_out[12] =  + (m_in[12] << 2) - m_in[14] - (m_in[14] << 2) + m_in[16];
	m_out[13] =  - (m_in[13] << 2) - (m_in[14] << 2) + m_in[15] + m_in[16];
	m_out[14] =  + (m_in[13] << 2) - (m_in[14] << 2) - m_in[15] + m_in[16];
	m_out[15] =  - (m_in[13] << 1) - m_in[14] + (m_in[15] << 1) + m_in[16];
	m_out[16] =  + (m_in[13] << 1) - m_in[14] - (m_in[15] << 1) + m_in[16];
	m_out[17] =  + (m_in[13] << 2) - m_in[15] - (m_in[15] << 2) + m_in[17];
	m_out[18] =  + (m_in[18] << 2) - m_in[20] - (m_in[20] << 2) + m_in[22];
	m_out[19] =  - (m_in[19] << 2) - (m_in[20] << 2) + m_in[21] + m_in[22];
	m_out[20] =  + (m_in[19] << 2) - (m_in[20] << 2) - m_in[21] + m_in[22];
	m_out[21] =  - (m_in[19] << 1) - m_in[20] + (m_in[21] << 1) + m_in[22];
	m_out[22] =  + (m_in[19] << 1) - m_in[20] - (m_in[21] << 1) + m_in[22];
	m_out[23] =  + (m_in[19] << 2) - m_in[21] - (m_in[21] << 2) + m_in[23];
	m_out[24] =  + (m_in[24] << 2) - m_in[26] - (m_in[26] << 2) + m_in[28];
	m_out[25] =  - (m_in[25] << 2) - (m_in[26] << 2) + m_in[27] + m_in[28];
	m_out[26] =  + (m_in[25] << 2) - (m_in[26] << 2) - m_in[27] + m_in[28];
	m_out[27] =  - (m_in[25] << 1) - m_in[26] + (m_in[27] << 1) + m_in[28];
	m_out[28] =  + (m_in[25] << 1) - m_in[26] - (m_in[27] << 1) + m_in[28];
	m_out[29] =  + (m_in[25] << 2) - m_in[27] - (m_in[27] << 2) + m_in[29];
	m_out[30] =  + (m_in[30] << 2) - m_in[32] - (m_in[32] << 2) + m_in[34];
	m_out[31] =  - (m_in[31] << 2) - (m_in[32] << 2) + m_in[33] + m_in[34];
	m_out[32] =  + (m_in[31] << 2) - (m_in[32] << 2) - m_in[33] + m_in[34];
	m_out[33] =  - (m_in[31] << 1) - m_in[32] + (m_in[33] << 1) + m_in[34];
	m_out[34] =  + (m_in[31] << 1) - m_in[32] - (m_in[33] << 1) + m_in[34];
	m_out[35] =  + (m_in[31] << 2) - m_in[33] - (m_in[33] << 2) + m_in[35];
}

void matrix_mul_shift_noloop_c1t(int *m_out, const int *m_in){
	m_out[0] =  + (m_in[0] << 2) - m_in[12] - (m_in[12] << 2) + m_in[24];
	m_out[1] =  + (m_in[1] << 2) - m_in[13] - (m_in[13] << 2) + m_in[25];
	m_out[2] =  + (m_in[2] << 2) - m_in[14] - (m_in[14] << 2) + m_in[26];
	m_out[3] =  + (m_in[3] << 2) - m_in[15] - (m_in[15] << 2) + m_in[27];
	m_out[4] =  + (m_in[4] << 2) - m_in[16] - (m_in[16] << 2) + m_in[28];
	m_out[5] =  + (m_in[5] << 2) - m_in[17] - (m_in[17] << 2) + m_in[29];
	m_out[6] =  - (m_in[6] << 2) - (m_in[12] << 2) + m_in[18] + m_in[24];
	m_out[7] =  - (m_in[7] << 2) - (m_in[13] << 2) + m_in[19] + m_in[25];
	m_out[8] =  - (m_in[8] << 2) - (m_in[14] << 2) + m_in[20] + m_in[26];
	m_out[9] =  - (m_in[9] << 2) - (m_in[15] << 2) + m_in[21] + m_in[27];
	m_out[10] =  - (m_in[10] << 2) - (m_in[16] << 2) + m_in[22] + m_in[28];
	m_out[11] =  - (m_in[11] << 2) - (m_in[17] << 2) + m_in[23] + m_in[29];
	m_out[12] =  + (m_in[6] << 2) - (m_in[12] << 2) - m_in[18] + m_in[24];
	m_out[13] =  + (m_in[7] << 2) - (m_in[13] << 2) - m_in[19] + m_in[25];
	m_out[14] =  + (m_in[8] << 2) - (m_in[14] << 2) - m_in[20] + m_in[26];
	m_out[15] =  + (m_in[9] << 2) - (m_in[15] << 2) - m_in[21] + m_in[27];
	m_out[16] =  + (m_in[10] << 2) - (m_in[16] << 2) - m_in[22] + m_in[28];
	m_out[17] =  + (m_in[11] << 2) - (m_in[17] << 2) - m_in[23] + m_in[29];
	m_out[18] =  - (m_in[6] << 1) - m_in[12] + (m_in[18] << 1) + m_in[24];
	m_out[19] =  - (m_in[7] << 1) - m_in[13] + (m_in[19] << 1) + m_in[25];
	m_out[20] =  - (m_in[8] << 1) - m_in[14] + (m_in[20] << 1) + m_in[26];
	m_out[21] =  - (m_in[9] << 1) - m_in[15] + (m_in[21] << 1) + m_in[27];
	m_out[22] =  - (m_in[10] << 1) - m_in[16] + (m_in[22] << 1) + m_in[28];
	m_out[23] =  - (m_in[11] << 1) - m_in[17] + (m_in[23] << 1) + m_in[29];
	m_out[24] =  + (m_in[6] << 1) - m_in[12] - (m_in[18] << 1) + m_in[24];
	m_out[25] =  + (m_in[7] << 1) - m_in[13] - (m_in[19] << 1) + m_in[25];
	m_out[26] =  + (m_in[8] << 1) - m_in[14] - (m_in[20] << 1) + m_in[26];
	m_out[27] =  + (m_in[9] << 1) - m_in[15] - (m_in[21] << 1) + m_in[27];
	m_out[28] =  + (m_in[10] << 1) - m_in[16] - (m_in[22] << 1) + m_in[28];
	m_out[29] =  + (m_in[11] << 1) - m_in[17] - (m_in[23] << 1) + m_in[29];
	m_out[30] =  + (m_in[6] << 2) - m_in[18] - (m_in[18] << 2) + m_in[30];
	m_out[31] =  + (m_in[7] << 2) - m_in[19] - (m_in[19] << 2) + m_in[31];
	m_out[32] =  + (m_in[8] << 2) - m_in[20] - (m_in[20] << 2) + m_in[32];
	m_out[33] =  + (m_in[9] << 2) - m_in[21] - (m_in[21] << 2) + m_in[33];
	m_out[34] =  + (m_in[10] << 2) - m_in[22] - (m_in[22] << 2) + m_in[34];
	m_out[35] =  + (m_in[11] << 2) - m_in[23] - (m_in[23] << 2) + m_in[35];
}

void hadamart_product_noloop_nest(int *out, const int *in1, const int *in2){
	out[0] = in1[0] * in2[0];
	out[1] = in1[1] * in2[1];
	out[2] = in1[2] * in2[2];
	out[3] = in1[3] * in2[3];
	out[4] = in1[4] * in2[4];
	out[5] = in1[5] * in2[5];
	out[6] = in1[6] * in2[6];
	out[7] = in1[7] * in2[7];
	out[8] = in1[8] * in2[8];
	out[9] = in1[9] * in2[9];
	out[10] = in1[10] * in2[10];
	out[11] = in1[11] * in2[11];
	out[12] = in1[12] * in2[12];
	out[13] = in1[13] * in2[13];
	out[14] = in1[14] * in2[14];
	out[15] = in1[15] * in2[15];
	out[16] = in1[16] * in2[16];
	out[17] = in1[17] * in2[17];
	out[18] = in1[18] * in2[18];
	out[19] = in1[19] * in2[19];
	out[20] = in1[20] * in2[20];
	out[21] = in1[21] * in2[21];
	out[22] = in1[22] * in2[22];
	out[23] = in1[23] * in2[23];
	out[24] = in1[24] * in2[24];
	out[25] = in1[25] * in2[25];
	out[26] = in1[26] * in2[26];
	out[27] = in1[27] * in2[27];
	out[28] = in1[28] * in2[28];
	out[29] = in1[29] * in2[29];
	out[30] = in1[30] * in2[30];
	out[31] = in1[31] * in2[31];
	out[32] = in1[32] * in2[32];
	out[33] = in1[33] * in2[33];
	out[34] = in1[34] * in2[34];
	out[35] = in1[35] * in2[35];
}

void matrix_mul_shift_noloop_a2(int *m_out, const int *m_in){
	m_out[0] =  + m_in[0] + m_in[1] + m_in[2] + m_in[3] + m_in[4];
	m_out[1] =  + m_in[1] - m_in[2] + (m_in[3] << 1) - (m_in[4] << 1);
	m_out[2] =  + m_in[1] + m_in[2] + (m_in[3] << 2) + (m_in[4] << 2);
	m_out[3] =  + m_in[1] - m_in[2] + (m_in[3] << 3) - (m_in[4] << 3) + m_in[5];
	m_out[4] =  + m_in[6] + m_in[7] + m_in[8] + m_in[9] + m_in[10];
	m_out[5] =  + m_in[7] - m_in[8] + (m_in[9] << 1) - (m_in[10] << 1);
	m_out[6] =  + m_in[7] + m_in[8] + (m_in[9] << 2) + (m_in[10] << 2);
	m_out[7] =  + m_in[7] - m_in[8] + (m_in[9] << 3) - (m_in[10] << 3) + m_in[11];
	m_out[8] =  + m_in[12] + m_in[13] + m_in[14] + m_in[15] + m_in[16];
	m_out[9] =  + m_in[13] - m_in[14] + (m_in[15] << 1) - (m_in[16] << 1);
	m_out[10] =  + m_in[13] + m_in[14] + (m_in[15] << 2) + (m_in[16] << 2);
	m_out[11] =  + m_in[13] - m_in[14] + (m_in[15] << 3) - (m_in[16] << 3) + m_in[17];
	m_out[12] =  + m_in[18] + m_in[19] + m_in[20] + m_in[21] + m_in[22];
	m_out[13] =  + m_in[19] - m_in[20] + (m_in[21] << 1) - (m_in[22] << 1);
	m_out[14] =  + m_in[19] + m_in[20] + (m_in[21] << 2) + (m_in[22] << 2);
	m_out[15] =  + m_in[19] - m_in[20] + (m_in[21] << 3) - (m_in[22] << 3) + m_in[23];
	m_out[16] =  + m_in[24] + m_in[25] + m_in[26] + m_in[27] + m_in[28];
	m_out[17] =  + m_in[25] - m_in[26] + (m_in[27] << 1) - (m_in[28] << 1);
	m_out[18] =  + m_in[25] + m_in[26] + (m_in[27] << 2) + (m_in[28] << 2);
	m_out[19] =  + m_in[25] - m_in[26] + (m_in[27] << 3) - (m_in[28] << 3) + m_in[29];
	m_out[20] =  + m_in[30] + m_in[31] + m_in[32] + m_in[33] + m_in[34];
	m_out[21] =  + m_in[31] - m_in[32] + (m_in[33] << 1) - (m_in[34] << 1);
	m_out[22] =  + m_in[31] + m_in[32] + (m_in[33] << 2) + (m_in[34] << 2);
	m_out[23] =  + m_in[31] - m_in[32] + (m_in[33] << 3) - (m_in[34] << 3) + m_in[35];
}

void matrix_mul_shift_noloop_a1t(int *m_out, const int *m_in){
	m_out[0] =  + m_in[0] + m_in[4] + m_in[8] + m_in[12] + m_in[16];
	m_out[1] =  + m_in[1] + m_in[5] + m_in[9] + m_in[13] + m_in[17];
	m_out[2] =  + m_in[2] + m_in[6] + m_in[10] + m_in[14] + m_in[18];
	m_out[3] =  + m_in[3] + m_in[7] + m_in[11] + m_in[15] + m_in[19];
	m_out[4] =  + m_in[4] - m_in[8] + (m_in[12] << 1) - (m_in[16] << 1);
	m_out[5] =  + m_in[5] - m_in[9] + (m_in[13] << 1) - (m_in[17] << 1);
	m_out[6] =  + m_in[6] - m_in[10] + (m_in[14] << 1) - (m_in[18] << 1);
	m_out[7] =  + m_in[7] - m_in[11] + (m_in[15] << 1) - (m_in[19] << 1);
	m_out[8] =  + m_in[4] + m_in[8] + (m_in[12] << 2) + (m_in[16] << 2);
	m_out[9] =  + m_in[5] + m_in[9] + (m_in[13] << 2) + (m_in[17] << 2);
	m_out[10] =  + m_in[6] + m_in[10] + (m_in[14] << 2) + (m_in[18] << 2);
	m_out[11] =  + m_in[7] + m_in[11] + (m_in[15] << 2) + (m_in[19] << 2);
	m_out[12] =  + m_in[4] - m_in[8] + (m_in[12] << 3) - (m_in[16] << 3) + m_in[20];
	m_out[13] =  + m_in[5] - m_in[9] + (m_in[13] << 3) - (m_in[17] << 3) + m_in[21];
	m_out[14] =  + m_in[6] - m_in[10] + (m_in[14] << 3) - (m_in[18] << 3) + m_in[22];
	m_out[15] =  + m_in[7] - m_in[11] + (m_in[15] << 3) - (m_in[19] << 3) + m_in[23];
}

