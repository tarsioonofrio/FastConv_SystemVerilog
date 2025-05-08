SCRIPT=$(pwd)

for dir in "$@"; do
  echo "Processando o diretório: $dir"
  python time-arch.py -f $dir
done
