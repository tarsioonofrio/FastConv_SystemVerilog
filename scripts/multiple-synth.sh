for dir in "$@"; do
  echo "Processando o diretório: $dir"
  cd "$dir" || { echo "Não foi possível entrar em $dir"; continue; }

  cd sintese
  rm genus.*
  genus -f run_logical_synthesis.tcl
  # Voltar para o diretório original (opcional)
  cd - > /dev/null
done
