# WPN16 N=32: pipeline interno do DSP a 317 MHz

Este experimento parte da variante WPN16 de 16 bits com barreiras nas duas
transformadas e testa registradores internos no caminho de multiplicação
DSP48E2. A opção `PIPE_DSP_MULTIPLIER=1` é experimental; o valor padrão
continua desativado. O fluxo compara a implementação Explore padrão com uma
tentativa de replicação física dos enables de alto fanout, ambas partindo do
mesmo checkpoint pós-place.

## Validação funcional RTL

A variante com pipeline de multiplicador passou o testbench Verilator do fluxo
stream-column com o workload truncado de 16 bits:

```text
inverse_tiles=576
terminal_inverse_events=0
cycles_to_end=9994
cycles=9996
weight_read_beats=27
useful_weight_beats=27
valid_writes=8100
input_clipped_beats=432
output_clipped_words=1116
golden mismatches=0
```

A diferença de latência deve ser lida em relação à configuração em que
`PIPE_DSP_MULTIPLIER=0`; ambas as execuções registradas terminaram em 9.994
ciclos até `p_end` e 9.996 ciclos totais. Portanto, a ativação desta opção não
alterou a latência observada nesse workload.

## Implementação pós-route

Vivado 2023.2, XCZU7EV (`xczu7ev-ffvc1156-2-e`), OOC, 32 réplicas, `NBITS=16`,
317 MHz (período de 3,154574 ns). A síntese e o placement foram compartilhados;
as duas implementações pós-place foram roteadas separadamente com Explore.

| Métrica | Explore padrão | Replicação forçada |
| --- | ---: | ---: |
| WNS pós-route | **+0,124 ns (PASS)** | **+0,123 ns (PASS)** |
| Timing a 317 MHz | Fechado | Fechado |
| DSP48E2 | 256 | 256 |

A tentativa de replicação de nets `r_transform_partial` não melhorou o timing:
os resultados diferem apenas 1 ps, dentro do ruído esperado entre as rotas e
sem benefício prático. Assim, não há razão para preferir a variante forçada.

Na implementação Explore padrão, a utilização final foi de 182.241 LUTs
(79,10%), 99.940 FFs (21,69%) e 256 DSP48E2 (14,81%). A contagem de DSPs é
consistente com oito por core em 32 réplicas.

## Registradores internos dos DSPs e caminho crítico

No checkpoint roteado da implementação padrão, a configuração inferida dos
256 DSP48E2 foi:

```text
MREG=1: 256/256
PREG=1: 156/256
PREG=0: 100/256
```

Portanto, o pipeline foi inferido parcialmente: todos os blocos usam o
registrador de multiplicação, mas 100 resultados não usam `PREG`. Os relatórios
DRC incluem 512 avisos `DPIP-2` (registradores de entrada A/B desativados) e
100 avisos `DPOP-3` (registrador de saída P desativado). Não houve erros de
DRC; não se deve descrever a inferência de `PREG` como completa.

O pior caminho da implementação padrão começa na saída registrada de um
DSP48E2 e termina em `r_output_write_reg[11][15]/D`, passando pela lógica
combinacional da inversa e da acumulação de saída. O atraso total reportado é
2,981 ns: 1,299 ns de célula/lógica e 1,682 ns de roteamento, com nove níveis
lógicos (quatro CARRY8 e lógica LUT). O slack positivo de 0,124 ns mostra que
esse caminho fecha a 317 MHz, embora seja a parte crítica remanescente.

Isso explica por que haver um registrador antes e outro depois do DSP não
elimina todo o atraso: os registradores internos limitam a multiplicação, mas
a soma da inversa e o acumulador ainda ficam entre a saída registrada do DSP e
o próximo registrador `r_output_write`.

## Escopo e ressalvas

- Este resultado é de implementação pós-route OOC; não é timing de placa nem
  inclui uma estimativa completa do clock tree em contexto de top-level.
- Vivado reporta timing fechado no constraint OOC de 317 MHz. Os relatórios
  também registram `HD.CLK_SRC` ausente e falta de `HD.PARTPIN_LOCS` para os
  ports de fronteira; por isso, o resultado vale como evidência de timing
  interno OOC, não como caracterização de interface externa.
- A campanha não executou simulação funcional pós-route replicada, SAIF ou
  análise de potência. Não há resultado de power, energia ou eficiência para
  esta configuração multicore.
- O experimento de replicação forçada é apenas um ramo diagnóstico. Como não
  trouxe ganho de timing, o ramo Explore padrão é o resultado recomendado.

## Proveniência

- RTL e fluxo: commit `9ea006cddb3717be5c70aaf9618b0f36edcede33`.
- Fonte do core: `conv-wpn16-pipe-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8-trunc-column.sv`.
- Parâmetros: 32 cores, `NBITS=16`, `PIPE_WEIGHT_TRANSFORM=1`,
  `PIPE_DSP_MULTIPLIER=1`.
- Vivado: 2023.2; parte: `xczu7ev-ffvc1156-2-e`.
- Execução longa feita em `tmux` na Paxos.
- Relatórios completos preservados na Paxos em
  `/sim/tarsio/reports-wpn16-dsp-pipe-ab-9ea006cd/`; o checkout persistente
  antigo não foi usado como fonte dos resultados.
