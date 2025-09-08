for SVDIR in ../fast-convolution-rtl/test/*/sv/; do
    VAR=$(basename "$(dirname "$SVDIR")")
    VAR=${VAR//1d-/}
    VAR=${VAR//2d-/}
    # Copy mux_mult
    MUX="./rtl/mux-mult/$VAR/"
    mkdir -p "$MUX"
    cp "$SVDIR"/mux_mult* "$MUX"

    # Copy mult matrices
    MAT="./rtl/mult-matrices/$VAR/"
    mkdir -p "$MAT"
    cp "$SVDIR"/mult_matrices.sv "$MAT"

    # Copy param
    PARAM="./rtl/etc/$VAR/"
    mkdir -p "$PARAM"
    cp "$SVDIR"/param.sv "$PARAM"

    # Copy data
    # PARAM="./rtl/etc/$VAR/"
    # mkdir -p "$PARAM"
    # cp "$SVDIR"/param.sv "$PARAM"

done
