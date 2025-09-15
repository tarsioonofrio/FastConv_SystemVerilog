for SVDIR in ../fast-convolution-rtl/test/*/sv/; do
    VAR=$(basename "$(dirname "$SVDIR")")
    VAR=${VAR//1d-/}
    VAR=${VAR//2d-/}
    # Copy mux_mult
    MUX="./rtl/mux-mult/$VAR/"
    mkdir -p "$MUX"
    cp "$SVDIR"/mux_mult* "$MUX"

    # Copy mult matrices
    if [[ "$SVDIR" == *"2d-"* ]]; then
        MAT="./rtl/mult-matrices/$VAR/"
        mkdir -p "$MAT"
        cp "$SVDIR"/mult_matrices.sv "$MAT"
    fi

    # Copy param
    PARAM="./rtl/pack-param/$VAR/"
    mkdir -p "$PARAM"
    cp "$SVDIR"/pack_param.sv "$PARAM"

    # Copy data
    # PARAM="./rtl/etc/$VAR/"
    # mkdir -p "$PARAM"
    # cp "$SVDIR"/param.sv "$PARAM"

done
