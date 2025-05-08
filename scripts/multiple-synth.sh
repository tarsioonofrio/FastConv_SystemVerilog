SCRIPT=$(pwd)

for dir in "$@"; do
  echo "Processando o diretório: $dir"
  cd "$dir/sintese" || { echo "Não foi possível entrar em $dir/sintese"; continue; }

  if [ ! -f run_logical_synthesis.tcl ]; then
    echo "Arquivo run_logical_synthesis.tcl não encontrado em $dir, pulando."
    cd "$SCRIPT"
    continue
  fi

  cd sintese
  rm genus.*
  genus -f run_logical_synthesis.tcl
  # Voltar para o diretório original (opcional)
  cd "$SCRIPT"
done
