#!/usr/bin/env bats

# ——————————————————————————————————————————————
# Ajuste de ambiente: inclui o binário do ModelSim no PATH
# (altere para o seu diretório de instalação)
MODELSIM_HOME="/opt/intelFPGA/20.1/modelsim_ase/bin"
export PATH="${MODELSIM_HOME}/bin:${PATH}"
# ——————————————————————————————————————————————

# antes de tudo, garantimos que o vsim está no PATH
setup() {
  command -v vsim >/dev/null \
    || skip "ModelSim (vsim) não encontrado no PATH"
}

# testa cada subpasta que contenha sim.do
@test "Simulação em cada pasta" {
  failures=0

  for dir in */; do
    if [[ -f "$dir/sim.do" ]]; then
      run vsim -c -do "$dir/sim.do"
      if [[ "$status" -ne 0 ]]; then
        echo "❌ Falhou em ${dir%/}"
        failures=$((failures+1))
      else
        echo "✅ OK em ${dir%/}"
      fi
    fi
  done

  [ "$failures" -eq 0 ]
}
