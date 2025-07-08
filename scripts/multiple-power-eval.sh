SCRIPT=$(pwd)

for dir in "$(realpath "$1")"/*; do
  echo "****************************************************************************"
  echo "Processando o diretório: $dir"
  echo "****************************************************************************"
  cd "$dir" || { echo "Não foi possível entrar em $dir"; continue; }

  if [ ! -f run_logical_synthesis.tcl ]; then
    echo "Arquivo run_logical_synthesis.tcl não encontrado em $dir, pulando."
    continue
  fi

  cd ./sintese/
  module load genus > /dev/null 2>&1
  genus -f run_logical_synthesis.tcl
  
  cd ../simSDF/
  module purge
  module load xcelium > /dev/null 2>&1
  xrun -f file_list.f -run -exit
  
  cd ../sintese/
  module purge  > /dev/null 2>&1
  module load ddi
  genus -f run_power.tcl
  # Voltar para o diretório original (opcional)
  # cd "$SCRIPT"
done
