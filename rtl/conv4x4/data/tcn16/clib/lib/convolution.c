//
// Created by tarsio on 19/06/2024.
//

#include <stdlib.h>
#include <init.h>
#include "convolution.h"
#include "util.h"

#ifdef __riscv
    #include <riscv-csr.h>
#endif

#if OPTIM == D1 || OPTIM == D2_KRON
    #include "optim.h"
#endif

#if OPTIM == D2_NEST
    #include "optim.h"
#endif


void inhibit_all(){
    #ifdef __riscv
        csr_write_mcountinhibit(-1);
    #endif
}

void inhibit_none(){
    #ifdef __riscv
        csr_write_mcountinhibit(0);
    #endif
}

void simple_convolution(
        const int *weight, const int *feature, int *output, int f_row, int f_col, int w_row, int w_col, int out_col) {
    int fr, fc, wr, wc;

    inhibit_none();

    for (fr = 0; fr < f_row - w_row + 1; fr++) {
        for (fc = 0; fc < f_col - w_col + 1; fc++) {
            for (wr = 0; wr < w_row; wr++) {
                for (wc = 0; wc < w_col; wc++) {
                    output[fr * out_col + fc] = output[fr * out_col + fc] +
                                                feature[(fr + wr) * f_col + (fc + wc)] * weight[wr * w_col + wc];
                }
            }
        }
    }
    inhibit_all();
}

void matrix_mul(int *out, const int *in1, const int *in2, int row1, int col2_row1, int col2) {
    int r, c, k;
    for (r = 0; r < row1; r++) {
        for (c = 0; c < col2; c++) {
            for (k = 0; k < col2_row1; k++) {
                out[r * col2 + c] += in1[r * col2_row1 + k] * in2[k * col2 + c];
            }
        }
    }
}

void matrix_transpose(int *out, const int *in, int row, int col) {
    int r, c;
    for (r = 0; r < row; r++) {
        for (c = 0; c < col; c++) {
            out[c * row + r] = in[r * col + c];
        }
    }
}

void hadamart_product(int *out, const int *in1, const int *in2, int row) {
    int r;
    for (r = 0; r < row; r++) {
        out[r] = in1[r] * in2[r];
    }
}


void init_array(int *array, int size) {
    int i;
    for (i = 0; i < size; i++) {
        array[i] = 0;
    };
}

void right_shift_array(int *array, int shift, int size) {
    int i;

    inhibit_none();
    for (i = 0; i < size; i++) {
        array[i] = array[i] >> shift;
    };
    inhibit_all();
}



void
fast_conv(int *ms, const int *ma, const int *mgg, const int *mc, const int *md, int a_size, int c_size, int m_size) {

    int *mss = (int *) malloc((m_size) * sizeof(int));
    int *mdd = (int *) malloc((m_size) * sizeof(int));

    // mallocs are inhibited, becase it increasy the number of multiplcations
    inhibit_none();

    init_array(mss, m_size);
    init_array(mdd, m_size);
    init_array(ms, a_size);


    #if OPTIM == 0
        // D=ct*d
        matrix_mul(mdd, mc, md, m_size, c_size, 1);
        // S=D.G
        hadamart_product(mss, mdd, mgg, m_size);
        // s=S*a
        matrix_mul(ms, ma, mss, a_size, m_size, 1);
    #elif OPTIM == D1 || OPTIM == D2_KRON
        // printf("******* OI *******\n");
        matrix_mul_shift_noloop_c(mdd, md);
        hadamart_product_noloop(mss, mdd, mgg);
        matrix_mul_shift_noloop_a(ms, mss);
    #endif

    inhibit_all();

    free(mss);
    free(mdd);
}


void
fast_conv_nest(int *ms, const int *ma1t, const int *mc1t, const int *mgg, const int *ma2, const int *mc2, const int *md,
               int a1_size, int a2_size, int c1_size, int c2_size, int m1_size, int m2_size) {

    int *md2 = (int *) malloc((c1_size * m1_size) * sizeof(int));
    int *mdd = (int *) malloc((m1_size * m1_size) * sizeof(int));
    int *mss = (int *) malloc((m1_size * m1_size) * sizeof(int));
    int *mss2 = (int *) malloc((a1_size * m1_size) * sizeof(int));
    // int *ma2 = (int *) malloc((a2_size * c2_size) * sizeof(int));
    // int *mc2 = (int *) malloc((c2_size * c2_size) * sizeof(int));

    // mallocs are inhibited, becase it increasy the number of multiplcations
    inhibit_none();

    init_array(md2, c1_size * m1_size);
    init_array(mdd, m1_size * m1_size);
    init_array(mss, m1_size * m1_size);
    init_array(mss2, a1_size * m1_size);
    init_array(ms, a1_size * a2_size);
    // init_array(ma2, a2_size * c2_size);
    // init_array(mc2, c2_size * c2_size);

    // matrix_transpose(mc2, mc2t, c1_size, c2_size);
    // matrix_transpose(ma2, ma2t, a2_size, c2_size);
    #if OPTIM == 0
        matrix_mul(md2, md, mc2, c1_size, c2_size, m2_size);
        matrix_mul(mdd, mc1t, md2, m1_size, c2_size, m2_size);
        hadamart_product(mss, mdd, mgg, m1_size * m2_size);
        matrix_mul(mss2, mss, ma2, m1_size, m2_size, a2_size);
        matrix_mul(ms, ma1t, mss2, a1_size, m2_size, a2_size);
    #elif OPTIM == D2_NEST
        matrix_mul_shift_noloop_c2(md2, md);
        print_array2d(md2, c1_size, m2_size, "d2");
        matrix_mul_shift_noloop_c1t(mdd, md2);
        print_array2d(mdd, m2_size, m2_size, "D");
        hadamart_product_noloop_nest(mss, mdd, mgg);
        print_array2d(mss, m2_size, m2_size, "S");
        matrix_mul_shift_noloop_a2(mss2, mss);
        print_array2d(mss2, a1_size, m2_size, "s2");
        matrix_mul_shift_noloop_a1t(ms, mss2);
        print_array2d(ms, a1_size, a1_size, "s");
    #endif

    inhibit_all();

    free(mdd);
    free(md2);
    free(mss);
    free(mss2);
}

void
filter1d(int *feature_out, const int *feature_in, int index, const int *mc, const int *ma, const int *mgg,
         int a_size, int c_size, int m_size, int fin_size, int fout_size) {
    int r, c, i;
    int *ms = (int *) malloc((a_size) * sizeof(int));
    int *md = (int *) malloc((c_size) * sizeof(int));

    inhibit_none();

    for (r = index; r < fout_size + index; r++) {
        for (c = 0; c <= fout_size; c = c + a_size) {
            for (i = 0; i < c_size; i++) {
                if (c + i < fin_size) {
                    md[i] = feature_in[r * fin_size + c + i];
                } else {
                    md[i] = 0;
                }
            }

            fast_conv(ms, ma, mgg, mc, md, a_size, c_size, m_size);
            for (i = 0; i < a_size; i++) {
                if (c + i < fout_size) {
                    feature_out[(r - index) * fout_size + c + i] += ms[i];
                }
            }
        }
    }

    inhibit_none();

    free(ms);
    free(md);
}


void filter2d(int *feature_out, const int *feature_in, int fin_size, int fout_size, int type_conv,
              type_struct_conv *params) {
    int r, c, rd, cd;
    int a1_size = params->a1_size;
    int a2_size = params->a2_size;
    int c1_size = params->c1_size;
    int c2_size = params->c2_size;
    int m1_size = params->m1_size;
    int m2_size = params->m2_size;
    int *ms = (int *) malloc((a1_size * a1_size) * sizeof(int));
    int *md = (int *) malloc((c1_size * c1_size) * sizeof(int));

    inhibit_none();

    for (r = 0; r < fout_size; r = r + a1_size) {
        for (c = 0; c <= fout_size; c = c + a2_size) {
            for (rd = 0; rd < c1_size; rd++) {
                for (cd = 0; cd < c2_size; cd++) {
                    if ((r + rd < fin_size) && (c + cd < fin_size)) {
                        md[rd * c1_size + cd] = feature_in[r * fin_size + rd * fin_size + c + cd];
                    } else {
                        md[rd * c1_size + cd] = 0;
                    }
                }
            }
            if (type_conv == KRON) {
                fast_conv(ms, params->ma, params->mgg, params->mc, md,
                          a1_size * a2_size, c1_size * c2_size, m2_size * m1_size);
            } else if (type_conv == NEST) {
                fast_conv_nest(ms, params->ma1, params->mc1, params->mgg, params->ma2,
                               params->mc2, md, a1_size, a2_size, c1_size, c2_size, m1_size, m2_size);
            }
            for (rd = 0; rd < a1_size; rd++) {
                for (cd = 0; cd < a2_size; cd++) {
                    if (c + rd < fout_size) {
                        feature_out[r * fout_size + rd * fout_size + c + cd] = ms[rd * a1_size + cd];
                    }
                }
            }
        }
    }

    inhibit_all();

    free(ms);
    free(md);
}
