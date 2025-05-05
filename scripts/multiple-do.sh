for dir in "$@"; do
  echo "Processando o diretório: $dir"
  cd "$dir" || { echo "Não foi possível entrar em $dir"; continue; }

    DATA=data/sim/file-032
    DATA=$DATA/data.sv vsim -c -do sim.do > $DATA/run.txt
    cp sim_summary.txt $DATA/
    DATA=data/sim/file-064
    DATA=$DATA/data.sv vsim -c -do sim.do > $DATA/run.txt
    cp sim_summary.txt $DATA/
    DATA=data/sim/file-128
    DATA=$DATA/data.sv vsim -c -do sim.do > $DATA/run.txt
    cp sim_summary.txt $DATA/
    DATA=data/sim/file-256
    DATA=$DATA/data.sv vsim -c -do sim.do > $DATA/run.txt
    cp sim_summary.txt $DATA/
    DATA=data/sim/file-512
    DATA=$DATA/data.sv vsim -c -do sim.do > $DATA/run.txt
    cp sim_summary.txt $DATA/
    # to restore base sim_summary.txt
    vsim -c -do sim.do

    # Voltar para o diretório original (opcional)
    cd - > /dev/null
done