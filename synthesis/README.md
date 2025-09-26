# Fluxo de Síntese

A pasta `source/` concentra os arquivos-base que são replicados nos experimentos de síntese:

- `run_logical_synthesis.tcl`: script principal do Cadence Genus. Ele carrega os cenários MMMC (`scripts/mmmc_tsmc_28_bv.tcl`), configura o esforço de síntese, lê os arquivos HDL (`${HDL_FILES}`), executa `syn_generic/syn_map/syn_opt` e gera relatórios de área, clock gating, temporização e potência, além dos netlists e arquivos SDF.
- `run_power.tcl`: script dedicado à análise de potência. Ele reabre o netlist (`${DB_FILE}`), configura o cenário de 0,90 V/25 °C, aplica as restrições (`scripts/constraints.sdc`) e escreve `power_evaluation.txt` com o consumo médio.
- `scripts/constraints.sdc`: restrições temporais aplicadas durante a síntese e análise de potência.
- `scripts/mmmc_tsmc_28_bv.tcl`: definição dos modos/cantos utilizados nos fluxos MMMC.

Cada subpasta adicional (por exemplo, `ifn9-06m`) representa um projeto sintetizado e segue a mesma organização:

- `list-define.txt` e `list-file.txt`: listas auxiliares com macros de compilação e arquivos HDL.
- `logical/`: contém o script ajustado `run_logical_synthesis.tcl`, um wrapper `run_logical_synthesis.sh` e a pasta `results/` com `reports/` e `gate_level/` produzidos pelo Genus.
- `power/`: reúne `run_power.tcl`, o shell script correspondente e os relatórios de potência (`power_evaluation.txt`).
- `sim/`: materiais para simulação pós-síntese (argumentos para o simulador, comando SDF e logs).

Para sintetizar um novo sistema, copie `source/` como base, ajuste os arquivos de lista e scripts e mantenha a estrutura `logical/`, `power/` e `sim/` para armazenar os resultados.
