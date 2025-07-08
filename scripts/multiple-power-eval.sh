SCRIPT=$(pwd)

for dir in "$(realpath "$1")"/*; do
  echo "****************************************************************************"
  echo "Processando o diretório: $dir/sintese"
  echo "****************************************************************************"
  cd "$dir/sintese" || { echo "Não foi possível entrar em $dir/sintese"; continue; }

  if [ ! -f run_logical_synthesis.tcl ]; then
    echo "Arquivo run_logical_synthesis.tcl não encontrado em $dir, pulando."
    cd "$SCRIPT"
    continue
  fi

  module load genus > /dev/null 2>&1
  genus -f run_logical_synthesis.tcl

  module purge
  module load xcelium > /dev/null 2>&1
  xrun -f file_list.f -run -exit

  module purge  > /dev/null 2>&1
  module load ddi
  genus -f run_power.tcl
  cd "$SCRIPT"
  # Voltar para o diretório original (opcional)
  # cd "$SCRIPT"
done
