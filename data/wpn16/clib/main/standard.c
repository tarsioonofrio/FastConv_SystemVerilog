#include "convolution.h"
#include "util.h"
#include "sim.h"


#ifdef __riscv
    #include "riscv-csr.h"
#endif

int main() {
    inhibit_all();

    int feat_out[FOUT_SIZE * FOUT_SIZE] = {0};

    simple_convolution(weight, feat_in, feat_out, FIN_SIZE, FIN_SIZE, W_SIZE,
                       W_SIZE, FOUT_SIZE);

    print_array2d(feat_out, FOUT_SIZE, FOUT_SIZE, "fout: ");
    compare_array1d(gold, feat_out, FOUT_SIZE * FOUT_SIZE, "Errors in S != gold");
    return 0;
}
