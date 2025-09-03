shopt -s nullglob
for SVDIR in ../fast-convolution-rtl/test/*/sv/; do
    VAR=$(basename "$(dirname "$SVDIR")")  # extrai o nome entre test/ e /sv/
    echo "*** $VAR"
    DST="./rtl/mux-mult/$VAR/"
    mkdir -p "$DST"
    rsync -av "$SVDIR" "$DST"
done
shopt -u nullglob
