

rm -rf dut.shm
rm -rf xcelium.d

module purge
module load xcelium > /dev/null 2>&1

# Raiz do repo para prefixar cada entrada do list_file.txt
GIT_ROOT=$(git rev-parse --show-toplevel)

# DATA_FILE="${GIT_ROOT}/data/ifn9/sim/sim-032/pack_data.sv"

# Testbench e pack conforme usado no histórico
TB=${GIT_ROOT}/rtl/conv-mux/testbench-synth-if.sv
GATE=../logical/results/gate_level/conv_logic_mapped.v

# Monta lista de arquivos (uma só linha, sem newline), prefixando GIT_ROOT
files=""
while IFS= read -r line; do
  files="$files$GIT_ROOT/$line "
done < ../list-file.txt

# Monta defines: prefixa -define em cada linha e junta em uma só linha
# defines=$(sed 's/^/-define /' list_def.txt | tr '\n' ' ' | sed 's/ $//')

# Chamada do xrun (mantendo args.txt como no histórico)
xrun -f args.txt $files $TB $GATE -f ../list-define.txt -define GATE_LEVEL -define XRUN -run -exit
