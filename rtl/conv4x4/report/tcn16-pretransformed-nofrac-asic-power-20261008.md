# TCN16 pretransformed sem frac — fluxo ASIC (2026-10-08)

## Resultado

Fluxo completo concluído para M06, M12 e M18: síntese Genus, simulação
gate-level com SDF no Xcelium e relatório de potência Joules. As três simulações
passaram no golden, com 8.100 escritas válidas e zero divergências. Os valores
abaixo são os resultados finais deste fluxo.

| MACs | Células | Área de célula (µm²) | Slack nominal | Ciclos do job | Dynamic (mW) | Leakage (mW) | Total (mW) |
| ---: | ------: | -------------------: | ------------: | ------------: | -----------: | -----------: | ---------: |
| 6 | 19.732 | 25.572,330 | 236 ps | 7.718 | 7,53347 | 0,10804 | 7,64151 |
| 12 | 24.780 | 31.606,470 | 236 ps | 5.990 | 9,88039 | 0,13555 | 10,01590 |
| 18 | 30.485 | 37.530,990 | 239 ps | 5.414 | 11,30337 | 0,16461 | 11,46800 |

`Dynamic = internal + switching`; `Total = dynamic + leakage`, conforme os
subtotais Joules. A simulação usou período de 2 ns (500 MHz), workload TCN16
sem frac com NBITS=20 e QUANT_BITS=8, no corner de power typical (`0,90 V`,
`25 °C`). Não calculei GOPS/W ou energia/job aqui, porque o pedido foi o fluxo
de potência; essas métricas também exigem fixar a convenção de operações e
throughput para estas variantes.

## Diagnóstico da divergência inicial

A primeira rodada gate-level marcou 165 erros em cada variante, mas o RTL não
era a causa. O testbench gate-level classificava uma leitura como pesos usando
`p_input_addr >= RAW_WEIGHT_BASE`. No último canal de features, a leitura de
padding inferior pode atravessar esse limite e chegar à região de pesos
transformados anexada ao pacote. O testbench então devolvia pesos onde deveria
fornecer padding zero. O mesmo teste contava essas leituras como beats de peso.

Corrigi ambos os checks para classificar a transação pelo estado
`READ_WEIGHTS` preservado no netlist. No netlist, o bit superior de
`st_input_current` está desconectado; por isso a comparação usa
`st_input_current[2:0] == 3'd2`, coerente com a codificação documentada de
`READ_WEIGHTS`. Depois da correção, M06 também passou sem SDF, confirmando que
os mismatches originais eram do testbench, não dos atrasos SDF.

Os logs da rodada inicial e seus valores Joules permanecem em
`power/diagnostic/power_evaluation_unvalidated.txt` e
`sim/diagnostic/`; eles são evidência da falha do checker antigo e **não** devem
ser usados. A potência corrigida está no caminho canônico
`power/power_evaluation.txt` de cada configuração.

## Verificações e warnings

| MACs | Xcelium/SDF | Gate-level golden | Escritas | Ciclos aceitos `p_start`–`p_end` |
| ---: | :--- | :--- | ---: | ---: |
| 6 | 0 erros, 3.141 warnings | PASS | 8.100 | 7.718 |
| 12 | 0 erros, 3.497 warnings | PASS | 8.100 | 5.990 |
| 18 | 0 erros, 4.011 warnings | PASS | 8.100 | 5.414 |

Os warnings são `SDFNET`: o Xcelium encontrou timing checks no SDF que não
existem nos modelos das células correspondentes. Não houve erro de annotation,
o job completou e o golden passou. O relatório nominal de timing apresenta um
caminho de saída para `p_output_data_write[79]`, com slack positivo mostrado
na tabela; isso não é um relatório de place-and-route físico.

## Condições e proveniência

- RTL/dataset de origem: commit `2d0860b84fb0b9901afbf99432e2a11256e9b6fd`.
- Dataset: `rtl/conv4x4/data/tcn16/sim/sim-032-3-3-normal-trunc-nbits20/pack_data.sv`.
- SHA-256 do pacote: `3274fb64b676c1657db2c3bd9ed0a2b09295add8888ae546cc6d599d1c5da567`.
- Host: `paxos.inf.pucrs.br`; Genus `21.12-s068_1`; Xcelium `23.03-s003`.
- Tecnologia: TSMC28; clock SDC de `2,000 ns`; power typical em `0,90 V / 25 °C`.
- As execuções longas foram feitas em `tmux` numa cópia temporária em `/tmp`;
  o checkout persistente da Paxos não foi alterado.

## Configurações

- `conv-tcn16-i60-h15-t12-o16-m06-stream12-prefetch24-pretransformed-column`
- `conv-tcn16-i60-h21-t24-o16-m12-stream12-prefetch24-pretransformed-column`
- `conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-pretransformed-column`

Cada configuração contém os relatórios de síntese, netlist/SDF, log Xcelium,
tempo de execução e relatórios Joules. O SHM de dezenas de megabytes não foi
copiado para a árvore local; ele permanece na cópia temporária da Paxos.
