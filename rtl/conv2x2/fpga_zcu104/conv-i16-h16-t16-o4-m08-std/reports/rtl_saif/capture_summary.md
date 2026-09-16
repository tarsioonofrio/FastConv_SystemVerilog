# Captura RTL-SAIF completa

| Campo | Valor |
| --- | --- |
| Gerador | Verilator com `tb_power` |
| Dataset | `rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv` |
| Seed | `1` |
| Jobs | `1` |
| Duração SAIF | `249995000 ps` (`249.995 us`) |
| Latência observada | `23648` ciclos |
| Tile ends | `2025` |
| Tile II | `11` ciclos |
| VCD | não gerado |

A captura inclui o job completo: `p_end` ocorre no fim da janela e os sinais de
escrita da memória de saída permanecem ativos durante a operação. A duração é
expressa em ps porque o contexto Verilator usa precisão de `1 ps`; o limite do
driver foi corrigido de `250000` unidades para `250000000 ps`.

O SAIF é uma fonte de atividade RTL/behavioral para o design pós-route. A
importação direta no checkpoint ainda está pendente; portanto nenhuma potência
baseada nesta captura deve ser publicada como resultado final até que o
relatório Vivado de mapeamento seja regenerado. O fluxo complementar extrai
atividade dos 101 bits de ports e controles em
`primary_activity.json`/`../../scripts/primary_activity.tcl` para aplicação
explícita com `set_switching_activity`.

Os relatórios gerados a partir da captura anterior de aproximadamente `245 ns`
foram preservados em `../stale_saif_245ns/` apenas como histórico e não entram
no resumo corrente.
