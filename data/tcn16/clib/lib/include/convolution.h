//
// Created by tarsio on 19/06/2024.
//

#ifndef C_CONVOLUTION_H
#define C_CONVOLUTION_H

#define KRON 0
#define NEST 1

#define D1 1
#define D2_KRON 2
#define D2_NEST 3

typedef struct {
    const int *mgg;
    const int *ma;
    const int *mc;
    const int *ma1;
    const int *ma2;
    const int *mc1;
    const int *mc2;
    int a1_size;
    int a2_size;
    int c1_size;
    int c2_size;
    int m1_size;
    int m2_size;
} type_struct_conv;

void simple_convolution(const int *weight, const int *feature, int *output, int f_row, int f_col, int w_row, int w_col,
                        int out_col);

void matrix_mul(int *out, const int *in1, const int *in2, int row1, int col2_row1, int col2);

void matrix_transpose(int *out, const int *in, int row, int col);

void hadamart_product(int *out, const int *in1, const int *in2, int row);

void init_array(int *array, int size);

void right_shift_array(int *array, int shift, int size);

void
fast_conv_nest(int *ms, const int *ma1t, const int *mc1t, const int *mgg, const int *ma2, const int *mc2, const int *md,
               int a1_size, int a2_size, int c1_size, int c2_size, int m1_size, int m2_size);

void
fast_conv(int *ms, const int *ma, const int *mgg, const int *mc, const int *md, int a_size, int c_size, int m_size);

void
filter1d(int *feature_out, const int *feature_in, int index, const int *mc, const int *ma, const int *mgg, int a_size,
         int c_size, int m_size, int fin_size, int fout_size);

void filter2d(int *feature_out, const int *feature_in, int fin_size, int fout_size, int type_conv,
              type_struct_conv *params);

void inhibit_all();

void inhibit_none();


#endif //C_CONVOLUTION_H
