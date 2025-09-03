shopt -s nullglob
for svdir in ../fast-convolution-rtl/test/*/sv/; do
  var=${svdir#test/}; var=${var%/sv/}   # extrai o nome entre test/ e /sv/
  dst="./rtl/mux-mult/$var/"
  mkdir -p "$dst"
  rsync -av "$svdir" "$dst"
done
shopt -u nullglob
