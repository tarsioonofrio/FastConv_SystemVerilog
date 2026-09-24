# P3: Xcelium post-route timing simulation — resultado do piloto

**Status: não validado; não usar como resultado de potência principal.**

O teste confirmou que Vivado 2023.2 consegue exportar a netlist/SDF pós-route,
que o Xcelium 23.03 consegue anotar o SDF e que o SAIF é importável no mesmo
DCP. Porém, a simulação anotada não passou na verificação funcional do golden.
O report de potência P3 foi gerado apenas como diagnóstico e não representa
um workload validado. P1 (RTL-SAIF/vectorless) continua sendo a estimativa
principal do piloto; P0 e P2 permanecem como baseline e cross-check.

## Identidade e reprodução

| Item | Valor |
| --- | --- |
| Host | `paxos.inf.pucrs.br` |
| Checkout isolado | `/tmp/fastconv-p3-3d40e051` |
| Commit | `3d40e05197df0bf260fbc70cdc689615abc2c8a2` |
| Ferramentas | Vivado 2023.2; Xcelium 23.03-s003 |
| Dispositivo | ZCU104 / `xczu7ev-ffvc1156-2-e` |
| Clock do benchmark | 317 MHz; XDC `3.154574 ns`; TB arredondado a `3.154 ns` |
| Workload canônico | 32×32, Cin=3, Cout=3, seed=1, quantização 8 bits |
| Checkout persistente | Não alterado; execução feita no clone temporário |

Os jobs longos de Vivado e Xcelium foram executados em sessões `tmux`. Durante
as execuções remotas, não alterei o checkout local. Nenhum VCD/FST foi gerado.

| Artefato | SHA-256 |
| --- | --- |
| DCP pós-route | `688d9abd0eeb27f7bd8a8b0d51e572d1977c69769443fc1cca2e0b1388c96f6e` |
| Netlist timesim | `f10256cdc1e6e77f71bcd971c31b089580d6b6b18c3a2d402317c97f926bad73` |
| SDF | `0ef243c182c9e8952d432a98372c86bf61da7b0eb310ac8c2bbfb7eb11fcdf51` |
| SAIF da primeira captura | `4b75242249cb13d9927aad69f3386d4a3f0d2c8447030def1364680264151f01` |
| `pack_data.sv` canônico | `3ced5c4527374898e1f8d65c275403e1366e2bb09f466542915656b263356da0` |

Os artefatos completos e logs continuam no clone temporário da Paxos, em
`rtl/conv2x2/fpga_zcu104/conv-i16-h16-t16-o4-m08-std/reports/p3_timesim/`.

## O que passou

- O DCP foi confirmado como implementação pós-route do XCZU7EV no ponto de
  317 MHz; WNS `+0.221 ns`.
- `compile_simlib` compilou `secureip` e `simprims_ver` para Xcelium 23.03; o
  smoke test de licença do `xrun` passou.
- `xmsdfc` compilou o SDF e o Xcelium anotou a instância `tb_power.dut`.
- Uma captura concluiu o job e observou `p_start`, `p_end`, atividade de
  entrada e escrita. O resumo do testbench registrou 2.025 tiles, tile II de
  11 ciclos e 8.100 escritas. A captura SAIF durou `74.589907 µs`, com
  `47.299` transições de clock; a latência medida no gate-level foi 23.649
  ciclos, um ciclo acima dos 23.648 ciclos RTL.
- Ao simular o mesmo netlist estrutural **sem SDF**, o golden passou: 8.100
  escritas e zero divergências. Isso isola o problema na execução temporal/
  anotação ou no modelo de temporização do testbench, não na lógica funcional
  do netlist sem delays.

## Por que P3 foi reprovado

1. A captura inicial `tb_power.sv` não reproduzia o mascaramento de amostras
   fora dos limites usado pelo testbench funcional. Uma cópia temporária de
   diagnóstico foi corrigida para usar o mesmo clamp e comparar as saídas com
   `const_feat_out`.
2. Com SDF, essa checagem encontrou **2.691 divergências** entre as 2.700
   saídas finais. O mesmo teste sem SDF encontrou zero.
3. A execução SDF original reportou 4.513 violações de hold. Acrescentar um
   C2Q de memória comportamental de 100 ps, 500 ps e 1 ns não recuperou o
   golden; as execuções ainda tiveram, respectivamente, 4.809, 924 e 1.297
   violações. Esses atrasos foram apenas testes de sensibilidade, não valores
   caracterizados de uma memória real, e não serão usados para selecionar um
   resultado.
4. A anotação cobriu 4.237 instâncias, 200.919 de 451.876 path delays
   (44,46%) e 20.044 de 24.392 timing checks (82,17%). O log também contém
   avisos `SDFNCAP` de interconexões unidirecionais e milhares de violações de
   hold. Portanto a anotação não é completa nem a execução é funcionalmente
   aceitável.

## Diagnóstico controlado: checks SDF e interface por `negedge`

Depois da captura inválida, foi criada uma cópia temporária do testbench que
amostra, na borda de descida, as respostas das memórias comportamentais e as
mantém estáveis para a captura do DUT na borda de subida. `p_start` também é
acionado/desacionado em `negedge`, e o reset é liberado em `negedge` depois do
GSR de 100 ns. A variante não adiciona atrasos C2Q arbitrários e não altera RTL,
dataset, DCP ou SDF. O fonte usado está preservado em
`tb_power_timing_safe.sv`; os logs integrais das execuções estão no clone
isolado da Paxos, nos três diretórios `timing_safe_*` sob `reports/p3_timesim/`.

| Execução | SDF | Timing checks | Ciclos | Escritas | Tiles | Divergências golden | Exit |
| --- | :---: | :---: | ---: | ---: | ---: | ---: | ---: |
| `timing_safe_nosdf` | não | — | 23.658 | 8.100 | 2.025 | 0 | 0 |
| `timing_safe_sdf_notimingchecks` | sim | `-notimingchecks` | 23.660 | 8.100 | 2.025 | 2.691 | 2 |
| `timing_safe_sdf_checks` | sim | habilitados | 23.660 | 8.100 | 2.025 | 2.691 | 2 |

O caso sem SDF passou no golden com o mesmo testbench. Com SDF, desabilitar os
checks não recuperou a saída, portanto os notifiers de setup/hold não são a
causa única: os atrasos anotados e/ou a interação restante entre a netlist e o
modelo de memória ainda mudam o comportamento observado. Com checks habilitados
restaram quatro avisos de hold no log, incluindo checks em
`r_input_weight_reg[14][5]`; o número de violações caiu muito em relação às
execuções anteriores, mas o golden continuou falhando exatamente 2.691 vezes.
Assim, atualizar estímulos em `negedge` melhorou a disciplina temporal do
harness, mas não tornou a timing simulation funcionalmente válida.

Essas execuções são somente diagnósticas: não produziram SAIF para power, e
nenhum valor P3 anterior foi promovido. Não calcular energia, GOPS/W ou pJ/op
com base nelas. Como as duas hipóteses pedidas foram testadas e a falha
permaneceu mesmo sem timing checks, encerrar a investigação do piloto neste
ponto; qualquer passo seguinte exigiria investigar a semântica do SDF/export
e do modelo das memórias, fora de uma simples correção de fase do testbench.

## SAIF/SHM e potência diagnóstica

O SAIF da primeira captura mapeou 5.342 de 5.442 nets no Vivado (**98,16%**),
contra 104/5.442 (1,91%) do RTL-SAIF P1. O Vivado ignorou a atividade do
clock no SAIF, conforme esperado, e usou a constraint do XDC. Apesar do
mapeamento alto, o relatório P3 ainda advertiu que mais de 75% da atividade
de entradas de I/O não tinha especificação do usuário.

| Método | Typical dinâmico | Static | Total | Observação |
| --- | ---: | ---: | ---: | --- |
| P0 vectorless | 0,251 W | 0,593 W | 0,844 W | baseline válido |
| P1 RTL-SAIF híbrido | 0,210 W | 0,593 W | 0,803 W | principal válido |
| P2 atividade de inputs/controles | 0,211 W | 0,593 W | 0,804 W | cross-check válido |
| P3 SAIF da timesim | 0,346 W | 0,594 W | 0,940 W | diagnóstico inválido: golden falhou |

No corner maximum, P3 reportou `0.346 W` dinâmico, `0.815 W` static e
`1.161 W` total. O dinâmico P3 fica cerca de 65% acima de P1/P2, com aumento
especialmente em I/O (`0.254 W` no typical). Como o workload anotado não
passou no golden, essa diferença não deve ser interpretada como glitch power
nem usada para energia/job, GOPS/W ou pJ/op.

O Xcelium criou `xcelium.shm` (aprox. 1,6 MB) com as probes e também um
`waves.shm` de apenas 16 KB. A abertura do banco pelo SimVision não foi
possível nesta sessão: o X11 encaminhado retornou `BadAccess`. Assim, a
inspeção visual solicitada não foi concluída; o SHM foi verificado apenas
estruturalmente. O script TCL deve especificar explicitamente o banco das
probes antes de qualquer nova captura visual.

## Conclusão

P3 demonstrou que a cadeia Vivado → netlist/SDF → Xcelium → SAIF → `read_saif`
→ `report_power` pode ser executada, mas **não forneceu uma estimativa de
potência aceitável** para este piloto. A tentativa controlada de desativar
timing checks e a variante de harness sincronizada em `negedge` não corrigiram
as divergências funcionais sob SDF. Permanecem limitações de anotação e uma
interação não resolvida entre os atrasos SDF e o modelo/harness externo; não
usar P3 para energia. Manter P1 como método principal, P2 como validação
cruzada e P3 apenas como evidência de uma tentativa não validada.
