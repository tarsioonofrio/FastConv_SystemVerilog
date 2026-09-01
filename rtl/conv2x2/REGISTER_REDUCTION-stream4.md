# Conv2x2stream4: registro de reducao de armazenamento

Este documento registra, em ordem executavel, as alteracoes do datapath
streaming e a motivacao de cada uma. A finalidade e permitir que cada etapa
seja aplicada e validada isoladamente, sem confundir reducao de registradores
com uma mudanca funcional no algoritmo Winograd/Toom-Cook.

## 1. Escopo e contrato congelado

O diretorio implementa F(2x2, 3x3), com matriz Hadamard 4x4 e 16 produtos.
As variantes fixas sao:

| Arquivo | MACs por ciclo | Linhas inversas consumidas por ciclo |
| --- | ---: | ---: |
| `conv4mac-stream4.sv` | 4 | 1 |
| `conv4mac-stream4-rdrow.sv` | 4 | 1 (variante com `r_d_row`) |
| `conv8mac-stream4.sv` | 8 | 2 |

O contrato funcional que nao pode mudar durante a reducao e:

1. a FSM de entrada continua produzindo a mesma janela e os mesmos pesos;
2. `Transform` continua calculando a mesma matriz transformada;
3. cada produto continua associado ao peso correspondente;
4. `InverseRowAccumulate` continua recebendo as linhas na mesma ordem;
5. o estado `r_out_acc` continua sendo capturado antes do ciclo seguinte;
6. a FSM de saida continua escrevendo os mesmos 8100 valores nos mesmos
   enderecos;
7. o caminho de referencia `rtl/conv2x2` permanece intocado.

O pacote usado na validacao RTL e
`../conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv`, com os parametros
de `../conv2x2/pack-param/tcn4/pack_param.sv`.

## 2. Inventario do estado streaming antes da reducao

Cada palavra de dados tem 20 bits (`NBITS=20`). Antes da primeira alteracao,
os sinais de estado do streaming eram:

| Sinal | Dimensao | Funcao | Deve permanecer? |
| --- | ---: | --- | --- |
| `r_d_row` | 4 x 20 bits | Mantem a linha transformada que alimenta os MACs no ciclo seguinte | Sim |
| `r_s_row` | 4 x 20 bits | Guardava a ultima linha de produtos apenas para trace/debug | Nao, apos prova de fanout |
| `r_out_acc` | 4 x 20 bits | Acumulador parcial dos quatro pixels de saida | Sim |
| `r_stream_row_idx` | 2 bits | Indice da linha usado pela inversa incremental | Sim |
| `r_stream_product_idx` | 4 bits | Base do grupo de produtos atual | Sim |

Os sinais `w_stream_sigma_current`, `w_stream_acc_next` e
`w_stream_final_capture` sao combinacionais. Eles nao representam palavras
armazenadas e nao devem ser contados como registradores.

## 3. Alteracao 1: eliminar `r_s_row`

### Motivacao

Nos arquivos fixos `conv4mac-stream4.sv` e `conv8mac-stream4.sv`, `r_s_row` recebia
`w_stream_product_row` ou `w_stream_product_row_2`. A unica leitura era uma
instancia adicional de `InverseRow`, cujo resultado (`w_stream_sigma`) era
impresso no bloco `STREAM_DEBUG`. A saida real usa as instancias
`inverse_row_current`/`inverse_row_current_2`, alimentadas diretamente pelos
produtos do ciclo atual, e depois usa `InverseRowAccumulate`.

Portanto, `r_s_row` nao participa de `r_out_acc`, `w_stream_acc_next`,
`w_stream_final_capture`, `p_output_data_write` ou dos enderecos de memoria.

### Mudanca aplicada

Em ambos os arquivos foram removidos:

- a declaracao de `r_s_row`;
- sua inicializacao no reset;
- sua inicializacao no estado `TRANSFORM`;
- sua captura no estado `HADAMARD`;
- a instancia `InverseRow inverse_row` usada somente pelo trace;
- as linhas `Slast` e `SIG` do trace `STREAM_DEBUG`.

A acumulacao funcional nao foi reescrita. O trecho continua sendo:

```systemverilog
InverseRow inverse_row_current(... w_stream_product_row ...);
InverseRowAccumulate inverse_row_acc(... w_stream_sigma_current ...);
```

Para `conv8mac-stream4.sv`, o segundo caminho continua usando
`w_stream_product_row_2` e `inverse_row_acc_second`.

Na antiga variante parametrizada de 2 MACs, o vetor `r_s_row` conservava a
primeira metade dos produtos enquanto a segunda metade era calculada no ciclo
seguinte. Essa variante foi removida desta pasta; a observacao fica registrada
apenas para explicar por que a reducao nao foi aplicada de forma mecanica.

### Reducao obtida

Cada variante removeu 4 palavras de 20 bits, ou 80 bits de armazenamento.
Considerando `conv4mac` e `conv8mac`, a reducao textual e de 8 palavras, ou
160 bits. A reducao de area pos-sintese ainda deve ser medida com uma sintese
nova; ela nao deve ser inferida apenas da contagem RTL.

### Criterio de aceite

- compilacao e simulacao Verilator sem erros;
- mesmos `inverse_tiles`, `valid_writes` e valores golden;
- lint tambem com `STREAM_DEBUG` definido;
- nenhuma referencia residual a `r_s_row`, `w_stream_sigma` ou ao
  `inverse_row` de trace.

## 4. Evidencia da Alteracao 1

### `conv4mac`

Comando:

```bash
make run-conv4mac
```

Resultado observado:

```text
2x2 simulation passed: inverse_tiles=2025 cycles=29749
valid_writes=8100 input_samples_clipped=0 invalid_output_beats=0
Core active cycles: 12150
```

### `conv8mac`

Comando:

```bash
make run-conv8mac
```

Resultado observado:

```text
2x2 simulation passed: inverse_tiles=2025 cycles=25699
valid_writes=8100 input_samples_clipped=0 invalid_output_beats=0
Core active cycles: 8100
```

### Lint

Os dois arquivos tambem passaram por:

```bash
verilator --lint-only -Wno-fatal -DSIMULATION -DSTREAM_DEBUG ...
```

Os avisos restantes sao avisos de largura ja existentes em memoria,
multiplicador, contadores e testbench; nao houve erro de elaboracao.

O wrapper ModelSim `fish ./test-streaming.fish` nao iniciou neste ambiente e
terminou com codigo 159 (SIGSYS do sandbox). Isso e uma limitacao da
execucao local, nao uma falha funcional observada no Verilator.

## 5. Alteracao 2: reduzir `r_d_row`

Esta alteracao foi inicialmente experimentada em `conv4mac-stream4.sv` e
`conv8mac-stream4.sv`. A variante preservada com essa fronteira esta agora em
`conv4mac-stream4-rdrow.sv`, enquanto `conv4mac-stream4.sv` permanece identico
ao `HEAD`. `r_d_row` e diferente de `r_s_row`: ele segura a linha
transformada entre a captura no estado `TRANSFORM`/`HADAMARD` e o ciclo em que
os MACs a consomem. A selecao combinacional sem essa fronteira foi mantida
somente como variante experimental; a variante `conv4mac-stream4-rdrow.sv`
restaura `r_d_row` porque a sintese mostrou uma reducao material de area.

### Hipotese

Substituimos a linha armazenada por selecao combinacional de
`w_conv_transform[r_stream_product_idx + offset]`. O valor selecionado fica
estavel durante o ciclo porque `r_stream_product_idx` so muda na borda de
clock que encerra o grupo de Hadamard; nessa mesma borda os pesos ativos sao
rotacionados. Assim, a nova linha e os novos pesos passam a valer juntos no
ciclo seguinte.

### Prova obrigatoria antes de editar

1. desenhar a tabela ciclo a ciclo para `NUM_MULT=4` e `NUM_MULT=8`;
2. confirmar a relacao entre `st_conv_current`, `r_stream_product_idx`,
   `r_conv_multiply_count` e `r_d_row`;
3. criar uma variante temporaria sem `r_d_row`;
4. comparar produto por produto e acumulador por acumulador contra a versao
   congelada;
5. somente depois rodar a regressao completa e, se disponivel, sintese.

No caso `NUM_MULT=4`, os quatro indices usados sao 0, 4, 8 e 12. No caso
`NUM_MULT=8`, os grupos sao 0 e 8 e todos os oito operandos passam a ser
selecionados diretamente da matriz transformada.

### Mudanca aplicada

Na variante experimental sem o banco, a declaracao de `r_d_row` foi removida
e `w_conv_feature` passou a usar diretamente os indices da linha atual. A
regressao funcional passou, mas a sintese contabilizou os muxes de selecao
dentro da hierarquia `Transform`.

Na variante `conv4mac-stream4-rdrow.sv`, `r_d_row[0..3]` foi restaurado:

- a primeira linha `w_conv_transform[0..3]` e capturada na entrada do Hadamard;
- as linhas seguintes `4..7`, `8..11` e `12..15` sao carregadas nas bordas dos
  ciclos correspondentes;
- os MACs leem somente o banco registrado durante cada ciclo.

`conv4mac-stream4.sv` continua sendo a referencia sem essa fronteira, e
`conv8mac-stream4.sv` continua sendo uma variante separada e nao e alterada
por esta restauracao.

O acumulador, os pesos, os contadores e a ordem da inversa nao foram
alterados.

### Reducao obtida

Na variante `conv4mac-stream4-rdrow.sv`, a restauracao recoloca 4 palavras de 20
bits (80 bits) e deixa somente a reducao de `r_s_row` em relacao ao estado
original. A sintese atual produziu 6.515 celulas, 10.857,984 de area total e
1.768,687 de area na hierarquia `Transform`, contra 8.765 celulas, 12.072,861
e 2.987,622 respectivamente na variante sem `r_d_row`. Portanto, os 80 bits
adicionais reduziram a area total em aproximadamente 10,1% e a area atribuida
`Transform` em aproximadamente 40,8%.

### Evidencia

O teste da variante `conv4mac-stream4-rdrow.sv` continua funcionalmente
equivalente:

```text
conv4mac: inverse_tiles=2025 cycles=27724 valid_writes=8100
          input_samples_clipped=0 invalid_output_beats=0
```

Nenhum erro de golden output foi observado. A simulacao anotada do netlist
regenerado tambem passou com `cycles=27725` e 0 erros de elaboracao.

## 6. Alteracao 3 candidata: reduzir `r_out_acc`

Tambem nao foi aplicada. `r_out_acc` contem quatro valores que atravessam os
ciclos de Hadamard. Remover esse vetor exigiria uma acumulacao distribuida ou
um banco de linhas, o que pode trocar registradores por multiplexadores e
aumentar a logica combinacional. O objetivo e reduzir armazenamento total,
nao apenas o numero de declaracoes.

Aceite somente com comparacao bit a bit das quatro saidas para cada janela e
com relatorio de area/timing que mostre beneficio real.

## 7. Variante de 2 MACs (historica e removida)

A antiga variante parametrizada de 2 MACs foi validada durante o
desenvolvimento, mas nao faz mais parte desta arvore. O arquivo
`conv2mac.sv`, o alvo correspondente do Makefile e a configuracao de sintese
`synthesis/tcn4-02mac` foram removidos para que nao exista uma fonte ou
netlist obsoleto apresentado como configuracao suportada.

Os resultados antigos permanecem nas secoes de campanha historica somente
para rastreabilidade; eles nao devem ser usados como resultados atuais da
pasta `conv2x2`.

## 8. Ordem de execucao recomendada

Cada item deve ser um commit separado ou uma unidade de trabalho facilmente
revertivel:

1. baseline atual: 4 e 8 MACs;
2. remover `r_s_row` e o `InverseRow` de trace (commit anterior);
3. repetir baseline e registrar ciclos/saidas;
4. comparar a variante sem `r_d_row` com a restauracao da fronteira
   sequencial;
5. aprovar a alternativa somente apos medir area, timing e potencia;
6. somente entao estudar `r_out_acc` ou uma acumulacao dobrada;
7. rodar simulacao anotada e power com netlist gerado a partir do commit
   correspondente.

Nenhuma alteracao deve ser promovida por area estimada em RTL. O resultado de
cada etapa precisa conter a mudanca, a razao, os testes e o que ainda nao foi
medido.

O comando `sdf_cmd.cmd` tambem precisa usar exatamente o nome produzido pelo
Genus (`Conv_...sdf`, respeitando maiusculas/minusculas). Se ele apontar para
`conv_...sdf`, o Xcelium pode continuar a simulacao sem anotacao e emitir
apenas um warning; isso nao e uma simulacao anotada valida.

O runner de anotacao tambem nao deve compilar o `conv*.sv` comportamental junto
com `Conv_logic_mapped.v`: o netlist ja contem a hierarquia mapeada e os
modulos auxiliares. A lista da simulacao gate-level agora retém somente
`pack_data.sv`, `pack_param.sv`, `mem.sv`, o testbench e o netlist. Isso evita
que uma definicao duplicada de `Conv` seja escolhida silenciosamente pelo
simulador.

## 9. Alteracao 4: tornar as configuracoes de sintese coerentes

### Motivacao

As duas variantes mantidas compartilham o mesmo fluxo Genus e usam modulos
fixos (`conv4mac-stream4.sv` e `conv8mac-stream4.sv`). O nome do topo e os caminhos das listas
precisam continuar coerentes com o layout local para que a sintese nao leia
fontes de outra pasta.

### Mudanca aplicada

Os parsers locais de `stream4/tcn4-04mac` e `stream4/tcn4-08mac` agora:

- ignoram linhas vazias e comentarios;
- convertem `NAME=VALUE` em `{NAME VALUE}` antes de `elaborate`;
- preservam a possibilidade de uma linha ja estar no formato Tcl;
- resolvem as listas de HDL a partir do diretorio da configuracao ou da raiz
  do repositorio;
- leem o topo de `top-module.txt`, evitando o nome legado `system` quando o
  modulo real e `Conv`.

A mesma correcao de origem foi aplicada ao caminho do testbench e às duas
`list-file.txt`. Nenhuma sintese e considerada atualizada apenas por essa
mudanca de script: a prova exige executar Genus depois que todas as alteracoes
de RTL forem finalizadas.

### Criterio de aceite

- validacao textual de que todos os caminhos das listas existem;
- `make run-conv4mac` e `make run-conv8mac` passam no RTL;
- uma campanha final de Genus para as duas configuracoes, seguida de
  simulacao anotada e power usando os artefatos dessa mesma campanha.

## 10. Configuracao de sintese por variante

As duas configuracoes em `synthesis/tcn4-*mac` foram corrigidas para usar os
artefatos locais deste diretorio:

| Configuracao | Fonte do core | Parametro |
| --- | --- | --- |
| `stream4/tcn4-04mac` | `conv4mac-stream4.sv` | fixo em 4 MACs |
| `stream4/tcn4-08mac` | `conv8mac-stream4.sv` | fixo em 8 MACs |

As listas anteriores apontavam para `rtl/conv2x2/synthesis/stream12`, de modo que os
logs/registros de sintese que ja estavam no diretorio nao comprovavam a
sintese do RTL desta pasta. Tambem foi corrigido o `testbench-file.txt` para o
testbench compartilhado local e o nome de topo para `Conv`, respeitando
maiusculas/minusculas do SystemVerilog.

Essa etapa corrige a origem dos arquivos, mas ainda nao e uma nova sintese.
Genus, simulacao anotada e power devem ser executados no Paxos a partir deste
commit; os resultados antigos devem ser substituidos e identificados pelo
commit do RTL usado.

## 11. Campanha gate-level anterior a remocao dos estados (`f71dd2a2`)

Depois da correcao dos nomes SDF, foi executada uma campanha completa no
Paxos. As tres sinteses usaram o mesmo commit de RTL (`e112a460`) e os mesmos
scripts locais desta arvore. O commit desta secao (`f71dd2a2`) altera somente o
testbench e a biblioteca de trabalho da anotada; portanto nao foi necessario
repetir a sintese logica. Os valores abaixo sao os resultados efetivamente
gerados, nao estimativas baseadas na contagem de declaracoes SystemVerilog.

| Variante | Celulas | Area total (um2) | Flip-flops | Slack nominal (ps) | Power total (mW) |
| --- | ---: | ---: | ---: | ---: | ---: |
| `tcn4-02mac` | 5.391 | 9.309,779 | 1.111 | 235 | 0,620796 |
| `stream4/tcn4-04mac` | 8.325 | 12.083,943 | 1.027 | 240 | 0,653916 |
| `stream4/tcn4-08mac` | 11.628 | 16.780,670 | 1.025 | 242 | 0,839179 |

O slack e positivo no view nominal de 2 ns (`analysis_view_0p90v_25c_captyp_nominal`).
O power foi calculado pelo Joules a partir do `dut.shm` da simulacao anotada,
com o resultado consolidado em `power_evaluation.txt`. A tabela abaixo registra
a mesma campanha gate-level, agora compilada em bibliotecas Xcelium novas
(`work_gate_final`) e sem os modulos comportamentais `Conv` da lista RTL:

| Variante | SDF errors | SDF warnings | Inverse tiles | Ciclos totais | Ciclos ativos | Escritas validas |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `tcn4-02mac` | 0 | 1.194 | 2.025 | 37.850 | 20.250 | 8.100 |
| `stream4/tcn4-04mac` | 0 | 1.107 | 2.025 | 29.750 | 12.150 | 8.100 |
| `stream4/tcn4-08mac` | 0 | 1.108 | 2.025 | 25.700 | 8.100 | 8.100 |

O Xcelium reportou warnings `SDFINF` de instancias sem atraso anotavel (por
exemplo, celulas removidas ou reescritas pelo Genus), mas nenhum erro de SDF.
Os warnings nao invalidam a equivalencia funcional, mas significam que nem
todo atraso individual foi associado a uma instancia homonima no netlist.
O uso de uma biblioteca de trabalho nova e a ausencia do RTL comportamental
eliminam a contaminacao por modulos compilados de rodadas anteriores. A
execucao de 2 MACs agora mostra 20.250 ciclos ativos, em vez dos 12.150 da
rodada contaminada, confirmando que cada netlist esta sendo simulado de forma
independente.

Os relatórios permanecem no Paxos em
`rtl/conv2x2/synthesis/tcn4-*/{logical/results,power}`. Eles devem ser
copiados ou regenerados quando uma nova alteração de RTL for feita; não se
deve misturar esses números com os logs legados que apontavam para
`conv2x2/synthesis/stream12`.

## 12. Remocao dos estados TRANSFORM e INVERSE

Depois da campanha gate-level anterior, a arquitetura stream foi simplificada
para refletir o caminho real do datapath. As variantes fixas `conv4mac-stream4.sv` e
`conv8mac-stream4.sv` passaram a usar somente os estados necessarios. A antiga fonte de
2 MACs e sua sintese foram removidas posteriormente; por isso os resultados de
2 MACs nesta secao sao historicos, nao uma configuracao atual.

### Motivo arquitetural

`Transform` continua sendo um modulo combinacional necessario: a matriz C
inteira fica disponivel em `w_conv_transform` enquanto cada ciclo seleciona a
faixa de produtos correspondente. O estado FSM `TRANSFORM`, porem, nao
executava a matriz; ele apenas inseria um ciclo para inicializar acumuladores e
indices. Essa inicializacao foi movida para `w_hadamard_start`, detectado na
transicao em que a entrada termina e o primeiro ciclo HADAMARD comeca.

O estado FSM `INVERSE` tambem nao executava uma inversa completa. O ultimo
ciclo HADAMARD ja calcula `w_stream_acc_next`, grava `r_output_write` e pode
gerar o termino da janela. O novo sinal `w_hadamard_last` substitui o antigo
salto para `INVERSE` e aciona `w_conv_end` e `w_conv_input_release` diretamente.
`InverseRow` e `InverseRowAccumulate` permanecem no caminho, pois sao as
operacoes incrementais de A1 e A0 que reduzem a necessidade de registrar a
matriz M x M inteira.

### Mudancas de controle

Antes, a sequencia era:

```text
WAIT_CONV -> TRANSFORM -> HADAMARD x N -> INVERSE -> WAIT_CONV
```

Agora ela e:

```text
WAIT_CONV -- w_hadamard_start --> HADAMARD x N -- w_hadamard_last --> WAIT_CONV
```

Nos cores mantidos, a enum passou de quatro estados para dois, reduzindo o
registrador de estado de dois bits para um bit. O contador de produtos continua
sendo inicializado antes do primeiro Hadamard, e o ultimo resultado continua
sendo capturado no mesmo ciclo da ultima acumulacao.

### Verificacao RTL apos a remocao

Os tres executaveis fixos passaram pelo mesmo `testbench.sv`, com golden,
contagem de tiles e contagem de escritas:

| Variante | Inverse tiles | Ciclos totais | Ciclos ativos | Escritas validas |
| --- | ---: | ---: | ---: | ---: |
| `conv4mac-stream4.sv` | 2.025 | 27.724 | 8.100 | 8.100 |
| `conv8mac-stream4.sv` | 2.025 | 23.674 | 4.050 | 8.100 |

Os resultados mostram a remocao dos dois ciclos de controle por janela sem
alterar os dados: todos os golden checks passaram, nao houve escrita fora da
faixa e cada variante manteve 2.025 tiles e 8.100 escritas. A campanha unica
de Genus, anotada e Joules foi entao executada no Paxos a partir deste RTL.
Os numeros abaixo substituem os da secao 11 para esta microarquitetura:

| Variante | Celulas | Area total (um2) | Flip-flops | Slack nominal (ps) | Power total (mW) |
| --- | ---: | ---: | ---: | ---: | ---: |
| `stream4/tcn4-04mac` | 8.473 | 12.127,770 | 1.024 | 243 | 0,692382 |
| `stream4/tcn4-08mac` | 11.818 | 16.855,605 | 1.023 | 206 | 0,918483 |

A anotada final usou os netlists desta mesma campanha e a biblioteca
`work_gate_final`, sem compilar o RTL comportamental junto com o netlist:

| Variante | SDF errors | SDF warnings | Inverse tiles | Ciclos totais | Ciclos ativos | Escritas validas |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `stream4/tcn4-04mac` | 0 | 879 | 2.025 | 27.725 | 8.100 | 8.100 |
| `stream4/tcn4-08mac` | 0 | 866 | 2.025 | 23.675 | 4.050 | 8.100 |

O power foi calculado pelo Joules a partir do `dut.shm` de cada anotada. Os
warnings `SDFINF` continuam sendo informativos: nao houve erro de anotacao,
mas algumas celulas nao possuem atraso individual associavel apos a
otimizacao do Genus. A reducao do estado da convolucao tambem aparece no
relatorio: foram sintetizados 1.024 e 1.023 flip-flops nos cores mantidos de 4
e 8 MACs, respectivamente.
