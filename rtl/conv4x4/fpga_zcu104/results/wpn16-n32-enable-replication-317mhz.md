# WPN16 N=32: réplica de enables de alto fanout

Ensaio A/B pós-place para a versão `wpn16_pipe_both_nbits16`, com 32 cores e
`NBITS=16`. O objetivo foi testar se a replicação física do enable
`r_transform_partial` melhora o timing. As duas rotas partiram do mesmo
checkpoint pós-place, mantendo placement e RTL constantes.

## Resultado

Vivado 2023.2, XCZU7EV (`xczu7ev-ffvc1156-2-e`), implementação OOC, target de
317 MHz (período de 3,154574 ns; o relatório arredonda para 3,155 ns):

| Métrica pós-route | Explore padrão | Replicação forçada | Diferença |
| --- | ---: | ---: | ---: |
| WNS | +0,043 ns | **+0,062 ns** | +0,019 ns |
| TNS | 0 ns | 0 ns | — |
| Endpoints com falha de setup | 0 | 0 | — |
| WHS | +0,040 ns | +0,041 ns | +0,001 ns |
| LUT | 180.060 (78,15%) | 180.060 (78,15%) | 0 |
| FF | 99.813 (21,66%) | 100.124 (21,73%) | +311 (+0,07 p.p.) |
| DSP48E2 | 256 (14,81%) | 256 (14,81%) | 0 |
| BRAM | 0 | 0 | 0 |

As duas rotas atendem às restrições de timing de 317 MHz. O ganho de 19 ps é
positivo, mas pequeno: não representa margem robusta para variações de
implementação ou para um contexto integrado diferente.

## Caminho crítico

Na rota padrão, o pior caminho era controle/enable dentro da réplica 27:

```text
FSM_onehot_st_conv_current_reg[5]/C
  -> r_transform_partial_reg[10][12]/CE
```

O caminho tinha zero níveis lógicos, fanout roteado 684 e 3,007 ns de atraso,
dos quais 2,928 ns (97,37%) eram de roteamento.

Com a replicação, o pior caminho mudou para o datapath DSP/MAC da réplica 19:

```text
r_transform_feature_reg_reg[3][15]/C
  -> DSP48E2 MAC
  -> r_output_write[13][15].../D
```

São 6 níveis lógicos internos ao DSP, com 3,076 ns de atraso: 1,593 ns de
lógica e 1,483 ns de roteamento. Portanto, a replicação removeu o enable de
alto fanout como limitante, mas expôs a operação DSP/MAC como próximo gargalo.

O Vivado aplicou a otimização a 32 nets-alvo, uma por core; os logs mostram
aproximadamente 8–10 réplicas de driver por net e 311 células adicionadas na
categoria Fanout. A LUT permaneceu igual; o aumento de 311 FF corresponde às
células de driver replicadas.

## Escopo e limitações

- Este é um resultado de timing pós-route OOC; não é timing de placa/pacote.
- O ensaio altera apenas a otimização física. Não houve nova simulação golden
  replicada, análise de power, energia ou throughput nesta campanha.
- Os DRC reports registram 856 warnings em cada rota, sem erros; predominam
  avisos de recomendações de registro/pipeline dos DSPs (`DPIP-2`, `DPOP-3`,
  `DPOP-4`).
- O contexto OOC ainda não tem delays de entrada/saída para os ports de
  fronteira e não define `HD.CLK_SRC`. Os relatórios registram zero endpoints
  internos unconstrained, mas esses resultados não caracterizam a interface
  externa nem o clock tree de um top-level completo.
- Não se deve concluir que a alteração de 19 ps torna a arquitetura
  substancialmente mais rápida. Para buscar margem adicional, o caminho
  remanescente sugere avaliar pipeline/uso dos registradores internos do DSP,
  com nova verificação funcional e de latência.

## Proveniência

- RTL base: commit `94eb5f854f9ff06781317e3ef894b3e19f93c489` (dual-barrier
  WPN16, descrito no relatório de [N=32 a 317 MHz](wpn16-n32-pipeboth-317mhz-94eb5f85.md)).
- Scripts A/B: commits `7bf9f21b807b11120e9169cd63c44e2c190c0407` e
  `bf8d1fcceb3bd528fe1e30904352c5398ba1201d`.
- Checkpoint pós-place comum às duas rotas:
  `SHA-256 507e6a90ecc2cdba299c36b44aba37490b66379a6038c4d2d6b689b840bc1202`.
- Worktree remoto limpo e preso ao commit dos scripts; o checkout persistente
  antigo da Paxos não foi alterado.
- Relatórios Vivado e logs preservados em
  [`reports/wpn16-enable-repl-ab-7bf9f21b/`](../reports/wpn16-enable-repl-ab-7bf9f21b/).
  O primeiro log mantém também a tentativa inicial rejeitada pelo Vivado
  (combinação inválida de `-directive` e `-force_replication_on_nets`); o
  resultado válido da rota forçada está em `resume_vivado_attempt2.log` e nos
  relatórios `forced_replication/`.

Os relatórios versionados são texto. O checkpoint DCP e outros artefatos
binários não foram incluídos no Git.
