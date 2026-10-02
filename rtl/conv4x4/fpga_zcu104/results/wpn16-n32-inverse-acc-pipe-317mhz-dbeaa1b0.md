# WPN16 N=32: pipeline entre inversa e acumulacao a 317 MHz

Esta campanha habilita `PIPE_INVERSE_ACCUMULATE=1` na variante WPN16 de 16
bits que ja separa os eixos das transformadas e registra o caminho do DSP.
O novo banco captura o resultado parcial da `InverseRow`, o indice da linha e
o valid antes da `InverseRowAccumulate`. A configuracao sintetizada usa
32 replicas no XCZU7EV e foi implementada em modo Out-of-Context.

## Validacao funcional RTL

A configuracao com os tres pipelines habilitados passou no testbench
Verilator de `stream-column`, usando o workload truncado canonico de 16 bits:

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

Essa e uma verificacao RTL funcional; nao e uma simulacao Xcelium das 32
replicas nem uma simulacao pos-route.

## Implementacao pos-route

Vivado 2023.2, parte `xczu7ev-ffvc1156-2-e`, 32 cores, `NBITS=16`, clock
constrangido a 317 MHz. O Vivado concluiu synthesis, Explore placement,
`phys_opt_design -directive Explore` e `route_design -directive Explore`.
`route_design` terminou com sucesso, sem nets parcialmente roteadas ou
overlaps, e o processo batch retornou codigo 0.

| Recurso/margem | Pos-route | Disponivel | Uso |
| --- | ---: | ---: | ---: |
| LUT | 184.069 | 230.400 | 79,89% |
| FF | 100.535 | 460.800 | 21,82% |
| DSP48E2 | 256 | 1.728 | 14,81% |
| BRAM tiles | 0 | 312 | 0% |
| WNS @ 316,957 MHz | **+0,071 ns (PASS)** | — | — |
| TNS / endpoints failing | 0 ns / 0 | — | — |
| WHS / THS | +0,027 ns / 0 ns | — | — |

O clock aparece no relatorio com periodo arredondado de 3,155 ns e frequencia
de 316,957 MHz; o XDC usa o ponto nominal de 317 MHz (3,154574 ns).

Os 256 DSP48E2 correspondem a 8 por replica. Todos os DSPs inferiram `MREG=1`;
249/256 inferiram `PREG=1` e sete ficaram com `PREG=0`. Portanto, o pipeline
interno do DSP continua parcialmente inferido na configuracao final.

## Caminho critico observado

O pior caminho pos-route esta na replica 20, de
`r_transform_partial_reg[14][1]/C` para
`r_transform_feature_reg_reg[6][13]/D`. O atraso do caminho de dados e
3,067 ns: 0,812 ns de celula/logica (26,48%) e 2,255 ns de roteamento (73,52%),
com oito niveis logicos (`3 x CARRY8`, LUTs e MUXF7).

Esse caminho passa pela etapa combinacional da transformada entre seus bancos
registrados; o banco entre os eixos permanece visivel nos endpoints do
relatorio. O caminho mais longo, portanto, nao e mais o trecho
`InverseRow -> InverseRowAccumulate` que recebeu a nova barreira. A etapa
seguinte de otimizacao, caso se queira margem maior, deve investigar a
transformada e seu roteamento/fanout, nao acrescentar outra barreira no
acumulador sem nova evidencia.

Em comparacao com a campanha dual-transform sem o novo banco de inversa,
registrada com WNS +0,043 ns, este run mediu +0,071 ns, diferenca observada de
28 ps. O caminho critico migrou para a transformada. Como sao implementacoes
fisicas independentes e a diferenca e pequena, nao se deve interpretar os
28 ps isoladamente como ganho garantido sem uma campanha de repetibilidade.

## Limites da conclusao

- O resultado comprova fechamento de timing interno OOC a 317 MHz nesta
  implementacao; nao estabelece Fmax nem timing de placa.
- `report_timing_summary` encontrou zero endpoints internos sem constraint,
  mas lista 5.186 ports sem input delay e 2.944 ports sem output delay. O clock
  OOC tambem nao tem `HD.CLK_SRC`, e os ports nao tem `HD.PARTPIN_LOCS`; timing
  de fronteira nao deve ser interpretado como timing de interface/package.
- Nao foi executada simulacao funcional pos-route/Xcelium nem campanha de
  SAIF/power nesta rodada. Assim, nao ha estimativa de potencia, energia,
  GOPS/W ou pJ/op para esta variante multicore.
- O DCP roteado foi mantido apenas na Paxos; os arquivos versionados sao
  relatorios textuais, nao binarios de implementacao.

## Proveniencia

- Commit RTL usado: `dbeaa1b07dd321a33d32026850546c8598a420db`.
- Worktree temporario na Paxos:
  `/sim/tarsio/fastconv-wpn16-inverse-acc-dbeaa1b0` (HEAD exato do commit).
- Checkout persistente na Paxos preservado em `d719dfc852dfb783c6d330104c6e8980f48ec662`.
- Saida completa remota:
  `/sim/tarsio/reports-wpn16-inverse-acc-pipe-dbeaa1b0/`.
- Artefatos textuais locais correspondentes estao em
  `reports/wpn16-inverse-acc-pipe-dbeaa1b0/`.
- Hash SHA-256 do DCP roteado:
  `dbe43ee307af821431eaa4354b78d14b6a8f20df48e11e91f01ac5b14bed532b`.
- Execucao longa feita em `tmux`; Vivado 2023.2 retornou codigo 0.
