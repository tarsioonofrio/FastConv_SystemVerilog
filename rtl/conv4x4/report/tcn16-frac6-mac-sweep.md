# TCN16 frac6: ASIC sweep de MACs

Campanha completa para as variantes colunas TCN16 com `NBITS=20`, `frac=6` e
dataset `sim-032-3-3-normal-trunc-frac6-nbits20`. As execucoes usaram o commit
de RTL `1c82fbcbc7fe54651c333d2a2fbdc2cc7214d979`, Genus 21.12 e Xcelium 23.03
na Paxos.

| MACs | Area total (um2) | Slack nominal (ps) | Ciclos `p_start`-`p_end` | Dinamica (mW) | Leakage (mW) | Total (mW) | Fluxo |
| ---: | ---------------: | -----------------: | ----------------------: | ------------: | -----------: | ---------: | :---- |
| 6  | 116722.500 | 224 | 7691 | 9.37790 | 0.510002 | 9.88790 | Sintese, gate-level SDF e power passaram |
| 12 | 125894.191 | 241 | 5963 | 11.80518 | 0.534814 | 12.34000 | Sintese, gate-level SDF e power passaram |
| 18 | 141885.177 | 238 | 5387 | 13.56092 | 0.586376 | 14.14730 | Sintese, gate-level SDF e power passaram |

Area total vem do `Conv_area.rpt` no corner `0.81 V / 125 C`; slack vem do
timing report nominal `0.90 V / 25 C`. O relatorio de power separa leakage,
internal e switching; nesta tabela, dinamica = internal + switching e total =
dinamica + leakage. Os ciclos sao medidos na janela aceita entre `p_start` e
`p_end`, nao incluem os ciclos de setup do testbench.

As simulacoes anotadas reportaram 8100 escritas validas e passaram. Os logs
tambem registram 432 beats de entrada e 1116 palavras de saida recortados pela
borda do workload, conforme o contrato do testbench.

## Evidencias por variante

Os logs e relatorios completos estao em `../synthesis/` sob o nome de cada
arquivo RTL:

- `conv-tcn16-i60-h15-t12-o16-m06-stream12-prefetch24-rowconst6-trunc-frac6-column/`
- `conv-tcn16-i60-h21-t24-o16-m12-stream12-prefetch24-rowconst6-trunc-frac6-column/`
- `conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-rowconst6-trunc-frac6-column/`

Em cada pasta, `campaign.log` registra os estagios; `logical/genus.log` e
`logical/results/reports/` guardam sintese e timing; `sim/xrun.log`,
`sim/sdf_log.log`, `sim/execution_time.txt` e `sim/dut.shm/` guardam a
simulacao anotada; `power/power_evaluation.txt` contem a decomposicao de
potencia. Os netlists e SDFs permanecem em `logical/results/gate_level/`.

As campanhas m12 e m18 tiveram falhas iniciais de sintese por problemas de
execucao/ambiente; os retries passaram e os marcadores finais `SYNTH_PASS`,
`GATE_SIM_PASS` e `POWER_PASS` estao presentes. Nao foram usados os artefatos
de tentativas falhas como resultados finais.
