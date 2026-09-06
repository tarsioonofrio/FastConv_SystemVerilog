# Conv2x2stream4: registro de reducao de armazenamento

Este documento registra, em ordem executavel, as alteracoes do datapath
streaming e a motivacao de cada uma. A finalidade e permitir que cada etapa
seja aplicada e validada isoladamente, sem confundir reducao de registradores
com uma mudanca funcional no algoritmo Winograd/Toom-Cook.

As referencias a `tcn4-*`, `stream4/*` e `stream12/*` nas secoes historicas
preservam os nomes usados nas campanhas originais. A arvore ativa foi
achatada: cada resultado de sintese agora fica diretamente em
`synthesis/<nome-do-arquivo-rtl-sem-.sv>/`, conforme a lista atual em
`README.md`.

## 0. A historia da reducao: do `std` ao streaming

A forma mais facil de entender estas arquiteturas e acompanhar a vida dos
dados, e nao apenas comparar os nomes dos arquivos. A historia comeca em
`conv-i16-h16-t16-o4-m04-std.sv`, que e a referencia convencional, e segue por
cinco perguntas sucessivas:

```text
std -> all16 -> stream12 -> stream8 -> stream4 -> stream12-*
```

Cada seta representa uma mudanca de fronteira entre logica combinacional e
registradores. O algoritmo Winograd continua calculando a mesma combinacao de
transformada, produtos e inversa; o que muda e quanto tempo cada valor precisa
ficar armazenado.

### 0.1 O ponto de partida: `std`

O `std` e parametrizado para quatro MACs, mas registra a matriz transformada
inteira em `r_conv_temp[0:15]`. Ele tambem conserva `r_conv_input[0:15]` como
fronteira da entrada da convolucao. O caminho de dados tem, portanto, os
seguintes bancos de 20 bits:

```text
r_input_feat[16]       janela 4x4
r_input_weight[16]     pesos transformados
r_conv_temp[16]        transformada inteira registrada
r_conv_input[16]       entrada capturada para a convolucao
r_output_write[4]      tile que sera escrito
r_output_read[4]       contribuicao anterior de canais
                                      total: 72 palavras de dados
```

O `std` e simples de raciocinar porque cada etapa possui uma fronteira clara:

```text
r_input_feat -> Transform -> r_conv_temp -> Multip[0:3] -> Inverse
                                                           -> output
```

O preco dessa clareza e manter 16 valores transformados mesmo quando somente
quatro produtos estao sendo calculados por ciclo.

### 0.2 Primeira bifurcacao: `all` com 16 MACs

O arquivo `conv-i16-h16-t00-o4-m16-all.sv` pergunta se podemos trocar ciclos
por paralelismo. A transformada e a inversa passam a ser fios combinacionais e
os 16 produtos sao calculados no mesmo ciclo. Para isso, `r_conv_temp[16]`
deixa de existir, mas a arquitetura ainda conserva `r_conv_input[16]` e cria
`r_conv_result[4]` para capturar a inversa completa:

```text
std:   16 input + 16 weights + 16 temp + 16 conv_input + 8 output = 72
all:   16 input + 16 weights + 16 conv_input + 4 conv_result + 8 output = 60
```

O `all` reduz 12 palavras em relacao ao `std`, mas aumenta de 4 para 16 MACs.
Ele e importante porque mostra uma reducao parcial: eliminamos o banco da
transformada, porem ainda guardamos uma copia da entrada e uma captura do
resultado final.

### 0.3 Segunda mudanca: `stream12`

O `stream12` aceita quatro MACs novamente, mas conserva somente o grupo ativo
de quatro valores da transformada. A matriz `w_conv_transform[0:15]` continua
sendo calculada combinacionalmente; `r_transform_row[0:3]` guarda a faixa que
sera usada no ciclo seguinte. A inversa passa a ser consumida por linhas:

```text
all:       16 input + 16 weights + 16 conv_input + 4 conv_result + 8 output = 60
stream12:  16 input + 16 weights +  4 transform + 4 inverse + 8 output = 48
```

O ganho de 12 palavras vem de remover duas fronteiras grandes:
`r_conv_input[16]` e `r_conv_result[4]`. O acumulado de quatro pixels fica no
banco de saida, e a inversa incremental substitui a matriz de resultado inteira.

### 0.4 Terceira mudanca: `stream8`

No `conv-i16-h16-t04-o4-m04-stream8.sv`, a linha transformada continua
registrada, mas `r_inverse_row[0:3]` deixa de ser necessario. O produto atual
entra diretamente em `InverseRow`; somente o acumulado entre linhas atravessa o
clock em `r_output_write[0:3]`:

```text
stream12: 16 input + 16 weights + 4 transform + 4 inverse + 8 output = 48
stream8:  16 input + 16 weights + 4 transform              + 8 output = 44
```

O nome historico `stream8` nao deve ser interpretado como oito MACs nesta
fonte: o arquivo documentado aqui usa quatro MACs. O numero importante para a
reducao e a fronteira `t04`, nao o apelido antigo da pasta.

### 0.5 Quarta mudanca: `stream4`

No `conv-i16-h16-t00-o4-m04-stream4.sv`, o banco
`r_transform_row[0:3]` tambem e removido. O indice
`r_transform_product_idx` seleciona diretamente quatro elementos de
`w_conv_transform`. A memoria economizada na transformada reaparece como
`r_output_accumulator[0:3]`, necessario para manter a soma parcial da inversa:

```text
stream8: 16 input + 16 weights + 4 transform              + 8 output = 44
stream4: 16 input + 16 weights + 4 accumulator             + 8 output = 44
```

Esta igualdade e didaticamente importante: remover um banco nao significa
necessariamente reduzir o total de palavras. A fronteira foi deslocada da
entrada dos MACs para a acumulacao da saida. O beneficio precisa ser medido em
area, timing e potencia, porque muxes e somadores podem custar mais que os
flip-flops removidos.

### 0.6 Quinta mudanca: variantes `stream12-*`

Depois de reduzir o armazenamento das features, a mesma pergunta foi aplicada
aos pesos. O `stream12-wstream4` e o `stream12-rowconst4` deixam de registrar
16 pesos transformados e passam a guardar nove pesos espaciais mais quatro
pesos transformados ativos:

```text
stream12:       h16 + t08
stream12-* row: h09 espacial + h04 ativo + t08
```

O total de dados cai de 48 para 45 palavras, mas parte do trabalho migrado
para os registradores aparece como logica combinacional de transformacao de
peso. O `rowconst4-exact` mantem a mesma quantidade de palavras, mas usa
larguras maiores e elimina arredondamentos intermediarios. Ja o
`stream12-prefetch4` faz a troca oposta: adiciona quatro palavras para manter a
proxima coluna viva e permitir sobreposicao entre leitura e processamento.

Assim, a historia completa nao e simplesmente "cada arquivo tem menos
registradores":

```text
std       guarda etapas completas e tem 72 palavras
all16     remove a temp, mas paraleliza tudo e fica com 60
stream12  serializa produtos e inversa e fica com 48
stream8   elimina a linha de inversa e fica com 44
stream4   move a fronteira para o acumulador e continua com 44
rowconst  reduz pesos transformados, chegando a 45
prefetch  adiciona estado de entrada para ganhar overlap, chegando a 52
```

As secoes seguintes detalham cada uma dessas transicoes e mostram exatamente
qual banco saiu, qual banco entrou e qual sinal combinacional passou a carregar
a responsabilidade funcional.

## 1. Escopo e contrato congelado

O diretorio implementa F(2x2, 3x3), com matriz Hadamard 4x4 e 16 produtos.
As variantes fixas sao:

| Arquivo | MACs por ciclo | Linhas inversas consumidas por ciclo |
| --- | ---: | ---: |
| `conv-i16-h16-t00-o4-m04-stream4.sv` | 4 | 1 |
| `conv-i16-h16-t04-o4-m04-stream8.sv` | 4 | 1 (variante com `r_transform_row`) |
| `conv-i16-h16-t00-o4-m08-stream4.sv` | 8 | 2 |

O contrato funcional que nao pode mudar durante a reducao e:

1. a FSM de entrada continua produzindo a mesma janela e os mesmos pesos;
2. `Transform` continua calculando a mesma matriz transformada;
3. cada produto continua associado ao peso correspondente;
4. `InverseRowAccumulate` continua recebendo as linhas na mesma ordem;
5. o estado `r_output_accumulator` continua sendo capturado antes do ciclo seguinte;
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
| `r_transform_row` | 4 x 20 bits | Mantem a linha transformada que alimenta os MACs no ciclo seguinte | Sim |
| `r_inverse_row` | 4 x 20 bits | Guardava a ultima linha de produtos apenas para trace/debug | Nao, apos prova de fanout |
| `r_output_accumulator` | 4 x 20 bits | Acumulador parcial dos quatro pixels de saida | Sim |
| `r_inverse_row_idx` | 2 bits | Indice da linha usado pela inversa incremental | Sim |
| `r_transform_product_idx` | 4 bits | Base do grupo de produtos atual | Sim |

Os sinais `w_inverse_partial_current`, `w_output_acc_next` e
`w_output_capture` sao combinacionais. Eles nao representam palavras
armazenadas e nao devem ser contados como registradores.

## 3. Alteracao 1: eliminar `r_inverse_row`

### Motivacao

Nos arquivos fixos `conv-i16-h16-t00-o4-m04-stream4.sv` e `conv-i16-h16-t00-o4-m08-stream4.sv`, `r_inverse_row` recebia
`w_inverse_product_row` ou `w_inverse_product_row_lane1`. A unica leitura era uma
instancia adicional de `InverseRow`, cujo resultado (`w_inverse_partial`) era
impresso no bloco `STREAM_DEBUG`. A saida real usa as instancias
`inverse_row_lane0`/`inverse_row_lane1`, alimentadas diretamente pelos
produtos do ciclo atual, e depois usa `InverseRowAccumulate`.

Portanto, `r_inverse_row` nao participa de `r_output_accumulator`, `w_output_acc_next`,
`w_output_capture`, `p_output_data_write` ou dos enderecos de memoria.

### Mudanca aplicada

Em ambos os arquivos foram removidos:

- a declaracao de `r_inverse_row`;
- sua inicializacao no reset;
- sua inicializacao no estado `TRANSFORM`;
- sua captura no estado `HADAMARD`;
- a instancia `InverseRow inverse_row` usada somente pelo trace;
- as linhas `Slast` e `SIG` do trace `STREAM_DEBUG`.

A acumulacao funcional nao foi reescrita. O trecho continua sendo:

```systemverilog
InverseRow inverse_row_current(... w_inverse_product_row ...);
InverseRowAccumulate inverse_row_acc(... w_inverse_partial_current ...);
```

Para `conv-i16-h16-t00-o4-m08-stream4.sv`, o segundo caminho continua usando
`w_inverse_product_row_lane1` e `inverse_row_acc_second`.

Na antiga variante parametrizada de 2 MACs, o vetor `r_inverse_row` conservava a
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
- nenhuma referencia residual a `r_inverse_row`, `w_inverse_partial` ou ao
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

## 5. Alteracao 2: reduzir `r_transform_row`

Esta alteracao foi inicialmente experimentada em `conv-i16-h16-t00-o4-m04-stream4.sv` e
`conv-i16-h16-t00-o4-m08-stream4.sv`. A variante preservada com essa fronteira esta agora em
`conv-i16-h16-t04-o4-m04-stream8.sv`, enquanto `conv-i16-h16-t00-o4-m04-stream4.sv` permanece identico
ao `HEAD`. `r_transform_row` e diferente de `r_inverse_row`: ele segura a linha
transformada entre a captura no estado `TRANSFORM`/`HADAMARD` e o ciclo em que
os MACs a consomem. A selecao combinacional sem essa fronteira foi mantida
somente como variante experimental; a variante `conv-i16-h16-t04-o4-m04-stream8.sv`
restaura `r_transform_row` porque a sintese mostrou uma reducao material de area.

### Hipotese

Substituimos a linha armazenada por selecao combinacional de
`w_conv_transform[r_transform_product_idx + offset]`. O valor selecionado fica
estavel durante o ciclo porque `r_transform_product_idx` so muda na borda de
clock que encerra o grupo de Hadamard; nessa mesma borda os pesos ativos sao
rotacionados. Assim, a nova linha e os novos pesos passam a valer juntos no
ciclo seguinte.

### Prova obrigatoria antes de editar

1. desenhar a tabela ciclo a ciclo para `NUM_MULT=4` e `NUM_MULT=8`;
2. confirmar a relacao entre `st_conv_current`, `r_transform_product_idx`,
   `r_conv_multiply_count` e `r_transform_row`;
3. criar uma variante temporaria sem `r_transform_row`;
4. comparar produto por produto e acumulador por acumulador contra a versao
   congelada;
5. somente depois rodar a regressao completa e, se disponivel, sintese.

No caso `NUM_MULT=4`, os quatro indices usados sao 0, 4, 8 e 12. No caso
`NUM_MULT=8`, os grupos sao 0 e 8 e todos os oito operandos passam a ser
selecionados diretamente da matriz transformada.

### Mudanca aplicada

Na variante experimental sem o banco, a declaracao de `r_transform_row` foi removida
e `w_transform_feature` passou a usar diretamente os indices da linha atual. A
regressao funcional passou, mas a sintese contabilizou os muxes de selecao
dentro da hierarquia `Transform`.

Na variante `conv-i16-h16-t04-o4-m04-stream8.sv`, `r_transform_row[0..3]` foi restaurado:

- a primeira linha `w_conv_transform[0..3]` e capturada na entrada do Hadamard;
- as linhas seguintes `4..7`, `8..11` e `12..15` sao carregadas nas bordas dos
  ciclos correspondentes;
- os MACs leem somente o banco registrado durante cada ciclo.

`conv-i16-h16-t00-o4-m04-stream4.sv` continua sendo a referencia sem essa fronteira, e
`conv-i16-h16-t00-o4-m08-stream4.sv` continua sendo uma variante separada e nao e alterada
por esta restauracao.

O acumulador, os pesos, os contadores e a ordem da inversa nao foram
alterados.

### Reducao obtida

Na variante `conv-i16-h16-t04-o4-m04-stream8.sv`, a restauracao recoloca 4 palavras de 20
bits (80 bits) e deixa somente a reducao de `r_inverse_row` em relacao ao estado
original. A sintese atual produziu 6.515 celulas, 10.857,984 de area total e
1.768,687 de area na hierarquia `Transform`, contra 8.765 celulas, 12.072,861
e 2.987,622 respectivamente na variante sem `r_transform_row`. Portanto, os 80 bits
adicionais reduziram a area total em aproximadamente 10,1% e a area atribuida
`Transform` em aproximadamente 40,8%.

### Evidencia

O teste da variante `conv-i16-h16-t04-o4-m04-stream8.sv` continua funcionalmente
equivalente:

```text
conv4mac: inverse_tiles=2025 cycles=27724 valid_writes=8100
          input_samples_clipped=0 invalid_output_beats=0
```

Nenhum erro de golden output foi observado. A simulacao anotada do netlist
regenerado tambem passou com `cycles=27725` e 0 erros de elaboracao.

## 6. Alteracao 3 candidata: reduzir `r_output_accumulator`

Tambem nao foi aplicada. `r_output_accumulator` contem quatro valores que atravessam os
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
2. remover `r_inverse_row` e o `InverseRow` de trace (commit anterior);
3. repetir baseline e registrar ciclos/saidas;
4. comparar a variante sem `r_transform_row` com a restauracao da fronteira
   sequencial;
5. aprovar a alternativa somente apos medir area, timing e potencia;
6. somente entao estudar `r_output_accumulator` ou uma acumulacao dobrada;
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
fixos (`conv-i16-h16-t00-o4-m04-stream4.sv` e `conv-i16-h16-t00-o4-m08-stream4.sv`). O nome do topo e os caminhos das listas
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
| `stream4/tcn4-04mac` | `conv-i16-h16-t00-o4-m04-stream4.sv` | fixo em 4 MACs |
| `stream4/tcn4-08mac` | `conv-i16-h16-t00-o4-m08-stream4.sv` | fixo em 8 MACs |

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
para refletir o caminho real do datapath. As variantes fixas `conv-i16-h16-t00-o4-m04-stream4.sv` e
`conv-i16-h16-t00-o4-m08-stream4.sv` passaram a usar somente os estados necessarios. A antiga fonte de
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
ciclo HADAMARD ja calcula `w_output_acc_next`, grava `r_output_write` e pode
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
| `conv-i16-h16-t00-o4-m04-stream4.sv` | 2.025 | 27.724 | 8.100 | 8.100 |
| `conv-i16-h16-t00-o4-m08-stream4.sv` | 2.025 | 23.674 | 4.050 | 8.100 |

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

## 13. Comparativo geral das variantes Conv2x2

Esta tabela consolida os resultados gate-level disponiveis para as variantes
atuais. A potencia e a potencia media do `power_evaluation.txt`; a energia foi
calculada para o mesmo workload da anotada (`2 ns` por ciclo). As linhas de
`stream4` foram atualizadas em 01/09/2026 com sintese, SDF, anotada e Joules
gerados a partir dos RTLs `conv-i16-h16-t00-o4-m04-stream4.sv` e `conv-i16-h16-t00-o4-m08-stream4.sv`.

| Variante | Fonte | Anotada | Celulas | Area total (um2) | Data path (ps) | Slack (ps) | Ciclos | Power (mW) | Energia (nJ) |
| --- | --- | :---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Conv std 4 MACs | `conv-i16-h16-t16-o4-m04-std.sv` | PASS | 6.613 | 12.017,925 | 763 | 237 | 23.677 | 0,826093 | 39,119 |
| Conv all 16 MACs | `conv-i16-h16-t00-o4-m16-all.sv` | PASS | 15.200 | 23.129,636 | 764 | 236 | 23.672 | 0,650788 | 30,811 |
| Stream4 4 MACs | `conv-i16-h16-t00-o4-m04-stream4.sv` | PASS | 8.473 | 12.127,770 | 757 | 243 | 27.725 | 0,692382 | 38,393 |
| Stream4 8 MACs | `conv-i16-h16-t00-o4-m08-stream4.sv` | PASS | 11.818 | 16.855,605 | 794 | 206 | 23.675 | 0,918483 | 43,490 |
| Stream4 4 MACs, `r_transform_row` | `conv-i16-h16-t04-o4-m04-stream8.sv` | PASS | 6.515 | 10.857,984 | 757 | 243 | 27.725 | 0,582814 | 32,317 |
| Stream12 2 MACs | `conv-i16-h16-t08-o4-mxx-stream12-generic.sv` | PASS | 6.483 | 11.012,366 | 766 | 234 | 29.749 | 0,531211 | 31,606 |
| Stream12 4 MACs | `conv-i16-h16-t08-o4-m04-stream12.sv` | PASS | 6.478 | 11.010,342 | 774 | 226 | 29.749 | 0,508947 | 30,281 |
| Stream12 8 MACs | `conv-i16-h16-t08-o4-m08-stream12.sv` | PASS | 10.394 | 15.873,661 | 752 | 248 | 25.699 | 0,669638 | 34,418 |

### Leitura dos resultados

- A antiga igualdade entre `stream4` e `stream12` nao existe quando os RTLs
  corretos sao sintetizados. Em 4 MACs, `stream4` usa 8.473 celulas contra
  6.478 de `stream12`; em 8 MACs, usa 11.818 contra 10.394.
- Dentro da familia `stream4`, a variante de 8 MACs reduz a latencia em
  4.050 ciclos em relacao a 4 MACs, mas aumenta area, caminho critico,
  potencia e energia.
- A variante `stream4` com `r_transform_row` e a menor em area e potencia entre as
  duas variantes stream4 de 4 MACs: -10,5% de area total e -15,8% de energia
  em relacao a `stream4` sem essa fronteira, neste workload.
- `stream4` e `stream12` nao sao comparaveis apenas pelo numero de MACs: usam
  agendamentos, fronteiras de registradores e implementacoes de matriz
  diferentes. A comparacao correta exige manter separadas a fonte HDL, o
  netlist, o SDF e a anotada de cada configuracao.
- Nao ha uma sintese atual versionada para uma variante convencional de 8
  MACs nesta arvore; por isso ela nao foi inventada ou extrapolada na tabela.

Os relatorios canônicos de `stream4` estao em
`synthesis/stream4/tcn4-04mac/` e `synthesis/stream4/tcn4-08mac/`. A
proveniencia do HDL usado pelo Genus e a anotada correspondente permanecem nos
respectivos `logical/genus.log` e `sim/xrun.log`. Os valores de `stream12`,
`std`, `all16` e `rdrow` sao os ultimos artefatos gate-level disponiveis nesta
arvore; eles nao foram re-sintetizados nesta rodada.

## 14. Como ler a reducao pela perspectiva dos registradores

As secoes anteriores registram decisoes e resultados de campanhas. Esta secao
reorganiza a historia de forma didatica: em vez de comecar pela FSM, comeca
pelas palavras que precisam sobreviver a uma borda de clock.

Uma palavra e um elemento de um vetor como `r_input_feat[0]`. Para o caso
TC2x2 usado nesta pasta, a maior parte das palavras tem `NBITS=20` bits. Um
vetor de 4 elementos, portanto, representa 4 palavras ou 80 bits de estado.

Ha tres categorias diferentes no RTL:

1. **Estado de dados:** valores de feature, pesos, produtos parciais e saidas.
2. **Estado de controle:** FSMs, contadores, indices e enderecos. Eles tambem
   sao flip-flops, mas nao aparecem nos campos `i`, `h`, `t` e `o` do nome.
3. **Fios combinacionais:** sinais `w_*`, modulos `Transform`, `InverseRow`,
   `Multip` e muxes. Eles podem consumir area e timing, mas nao mantem um valor
   entre ciclos e, por isso, nao sao registradores.

O nome do arquivo resume apenas os bancos de dados principais:

| Campo | Significado neste documento | Exemplo |
| --- | --- | --- |
| `i` | palavras no banco da janela de entrada | `r_input_feat[0:15]` = `i16` |
| `h` | palavras registradas dos pesos ativos | `r_input_weight[0:15]` = `h16` |
| `t` | palavras registradas para transformada/inversa | `r_transform_row[0:3]` + `r_inverse_row[0:3]` = `t08` |
| `o` | palavras no banco de saida do tile | `r_output_write[0:3]` = `o4` |
| `m` | multiplicadores fisicos ativos por ciclo Hadamard | `m04`, `m16` |

Essa convencao nao substitui a leitura do RTL. Por exemplo, `r_conv_input`,
`r_conv_result`, `r_output_accumulator`, `r_output_read` e um banco de
prefetch sao registradores reais, mas nao estao todos codificados nos cinco
campos do nome. Por isso as tabelas seguintes mostram tambem um inventario
integral de palavras de dados.

### 14.1 O que significa reduzir registradores

Para uma matriz Hadamard 4x4 existem 16 valores transformados. A arquitetura
naive pode registrar esses 16 valores e depois registrar uma matriz inteira de
produtos ou resultados intermediarios. A arquitetura streaming faz uma pergunta
mais economica:

> Qual e o menor trecho do resultado que precisa permanecer vivo quando o
> proximo ciclo chega?

A resposta muda conforme a fronteira sequencial escolhida:

```text
tile de entrada -- Transform combinacional -- produtos -- inversa por linha
      |                    |                     |              |
   r_input_feat       w_conv_transform       w_conv_product   parcial
      16 palavras         16 fios              m palavras     acumulado
```

No caminho all16, todos os 16 produtos sao calculados juntos. No caminho
streaming, somente uma linha ou um grupo de `m` produtos atravessa a fronteira
de clock. A economia vem de nao guardar simultaneamente aquilo que pode ser
recalculado ou consumido no mesmo ciclo.

## 15. Primeiro ponto de referencia: `all` com 16 MACs

Arquivo: `conv-i16-h16-t00-o4-m16-all.sv`.

Esta e a melhor arquitetura para entender o que o streaming tenta remover. Ela
faz a transformada inteira, todos os produtos e a inversa inteira de forma
paralela. O nome `t00` significa apenas que nao ha um banco dedicado chamado
`r_transform_row` ou `r_inverse_row`; nao significa que o datapath nao tenha
registradores intermediarios.

### 15.1 Bancos de dados do `all`

| Banco | Palavras | Papel durante a janela |
| --- | ---: | --- |
| `r_input_feat[0:15]` | 16 | Mantem a janela 4x4 lida da feature map |
| `r_input_weight[0:15]` | 16 | Mantem todos os pesos transformados |
| `r_conv_input[0:15]` | 16 | Captura a entrada da convolucao antes do caminho de produtos |
| `r_conv_result[0:3]` | 4 | Captura o resultado de `Inverse` antes da escrita |
| `r_output_write[0:3]` | 4 | Mantem os quatro valores que serao escritos |
| `r_output_read[0:3]` | 4 | Mantem a contribuicao anterior de outro canal |
| **total de dados** | **60** | Soma dos bancos acima |

Os 60 valores sao uma contagem de armazenamento de dados, nao uma contagem de
flip-flops sintetizados. Ainda existem registradores escalares de endereco,
contagem de janela, canais, FSM e controle de leitura/escrita.

### 15.2 Sequencia de vida dos dados

1. A FSM de entrada preenche `r_input_feat` com a janela 4x4.
2. A FSM de pesos preenche `r_input_weight` com 16 pesos.
3. `Transform` calcula `w_conv_transform[0:15]`. Esse vetor e `w_*`: e fio,
   nao banco registrado.
4. Os 16 `Multip` calculam `w_conv_product[0:15]` no mesmo ciclo.
5. `Inverse` calcula `w_conv_inverse[0:3]`, tambem combinacional.
6. `r_conv_result` cria uma fronteira de clock para o resultado completo.
7. `r_output_write` prepara a escrita e `r_output_read` guarda a contribuicao
   anterior que sera somada pelo banco de saida.

O ponto importante e que o `all` troca tempo por largura: ele mantem mais
fronteiras de dados, mas termina uma janela Hadamard em um unico ciclo. A
primeira reducao streaming nao tenta remover o banco de entrada ou o banco de
pesos; ela remove as fronteiras completas do caminho de transformada, produto e
inversa.

## 16. Segunda etapa: `stream12`

Arquivo principal: `conv-i16-h16-t08-o4-m04-stream12.sv`.

O `stream12` mantem a janela e os pesos completos, mas percorre os 16 produtos
em quatro ciclos de quatro MACs. A matriz transformada continua existindo como
`w_conv_transform[0:15]`, mas apenas quatro palavras passam para
`r_transform_row` por ciclo. A inversa tambem e consumida por linha.

### 16.1 Bancos registrados

| Banco | Palavras | O que atravessa o clock |
| --- | ---: | --- |
| `r_input_feat[0:15]` | 16 | Tile 4x4 em processamento |
| `r_input_weight[0:15]` | 16 | Os 16 pesos, rotacionados em grupos de 4 |
| `r_transform_row[0:3]` | 4 | Grupo da transformada consumido pelo proximo ciclo |
| `r_inverse_row[0:3]` | 4 | Linha de produto mantida para a inversa/trace nesta versao |
| `r_output_write[0:3]` | 4 | Acumulador parcial do tile de saida |
| `r_output_read[0:3]` | 4 | Contribuicao de canais anteriores |
| **total integral de dados** | **48** | Inclui os dois bancos de interface de saida |

Na convencao do nome, `i16 + h16 + t08 + o4` soma 44 palavras porque `o4`
conta somente o banco de escrita. A contagem integral acrescenta as quatro
palavras de `r_output_read` e chega a 48.

### 16.2 O que foi eliminado em relacao ao `all`

O `stream12` elimina `r_conv_input[16]` e `r_conv_result[4]`, pois a entrada
ja esta em `r_input_feat` e o acumulador de saida pode ser atualizado uma linha
por ciclo. Em troca, introduz `r_transform_row[4]`, `r_inverse_row[4]` e dois
indices curtos (`r_transform_product_idx` e `r_inverse_row_idx`).

Em palavras de dados, a transicao e:

```text
all16:    16 input + 16 weights + 16 conv_input + 4 conv_result + 4 out + 4 read = 60
stream12: 16 input + 16 weights +  4 transform  + 4 inverse    + 4 out + 4 read = 48
```

A reducao nominal e de 12 palavras, ou 240 bits a 20 bits por palavra. Ela
nao implica automaticamente 20% de area, porque a multiplexacao, os quatro
ciclos de controle e os modulos `InverseRowAccumulate` tambem ocupam area.

### 16.3 O ciclo a ciclo

```text
ciclo 0: r_transform_row <- w_conv_transform[0:3]   -> 4 produtos
ciclo 1: r_transform_row <- w_conv_transform[4:7]   -> 4 produtos
ciclo 2: r_transform_row <- w_conv_transform[8:11]  -> 4 produtos
ciclo 3: r_transform_row <- w_conv_transform[12:15] -> 4 produtos
```

Em cada borda, `r_output_write` recebe o novo acumulado da inversa. O valor
anterior nao precisa de uma matriz 4x4: quatro acumuladores de saida sao
suficientes para os quatro pixels do tile.

O `r_inverse_row` da fonte baseline e uma fronteira adicional que nao participa
do resultado final quando `STREAM_DEBUG` esta desligado; ele existe por causa
do caminho legado de trace. Esse detalhe explica por que a contagem textual do
baseline nao e ainda o limite minimo da familia `stream12`.

## 17. Terceira etapa: `stream8`

Arquivo: `conv-i16-h16-t04-o4-m04-stream8.sv`.

Apesar do nome historico `stream8`, esta fonte fixa tem quatro MACs. O campo
`t04` descreve a fronteira relevante: somente uma linha de quatro valores da
transformada e registrada. A linha da inversa nao e armazenada; o produto do
ciclo atual entra diretamente em `InverseRow` e depois em `InverseRowAccumulate`.

### 17.1 Bancos registrados

| Banco | Palavras |
| --- | ---: |
| `r_input_feat[0:15]` | 16 |
| `r_input_weight[0:15]` | 16 |
| `r_transform_row[0:3]` | 4 |
| `r_output_write[0:3]` | 4 |
| `r_output_read[0:3]` | 4 |
| **total integral de dados** | **44** |

Em comparacao direta com o `stream12`, saem as quatro palavras de
`r_inverse_row`. A acumulacao funcional nao desaparece: ela continua em
`r_output_write`, que passa a exercer simultaneamente o papel de banco de
saida do tile e de estado parcial entre linhas.

### 17.2 Por que isso reduz estado sem mudar a matematica

`InverseRow` e um bloco combinacional. Ele recebe o vetor de produtos do ciclo,
calcula os quatro valores parciais da inversa e entrega o resultado ao
`InverseRowAccumulate`. Como o acumulador ja esta registrado em
`r_output_write`, guardar novamente a linha de produtos em `r_inverse_row` seria
duplicar uma informacao que ja foi consumida.

O fluxo fica:

```text
r_transform_row -> Multip[0:3] -> InverseRow -> Accumulate -> r_output_write
```

Essa e a primeira reducao que remove um banco inteiro sem aumentar o numero de
produtos. O preco e uma dependencia combinacional mais direta entre MAC,
inversa e acumulador.

## 18. Quarta etapa: `stream4`

Arquivo: `conv-i16-h16-t00-o4-m04-stream4.sv`.

Aqui a fronteira `r_transform_row` tambem foi removida. `Transform` continua
produzindo os 16 valores, mas eles permanecem em `w_conv_transform`; o indice
`r_transform_product_idx` seleciona diretamente os quatro valores que alimentam
os MACs no ciclo corrente.

### 18.1 Bancos registrados

| Banco | Palavras | Motivo |
| --- | ---: | --- |
| `r_input_feat[0:15]` | 16 | Mantem o tile de entrada |
| `r_input_weight[0:15]` | 16 | Mantem e rotaciona os pesos |
| `r_output_accumulator[0:3]` | 4 | Mantem a soma parcial da inversa |
| `r_output_write[0:3]` | 4 | Captura o tile final para a FSM de saida |
| `r_output_read[0:3]` | 4 | Mantem a contribuicao anterior |
| **total integral de dados** | **44** |

O `t00` agora faz sentido para a transformada: nao existe banco registrado de
transformada nem de linha inversa. Mas a ausencia de `r_transform_row` nao
elimina o estado; ela desloca quatro palavras para `r_output_accumulator`.

Por isso `stream4` e `stream8` podem ter o mesmo total integral de palavras,
mas por motivos diferentes:

```text
stream8: 16 input + 16 weights + 4 transform_row + 4 out + 4 read = 44
stream4: 16 input + 16 weights + 4 accumulator  + 4 out + 4 read = 44
```

A diferenca e temporal. No `stream8`, a fronteira registrada protege a linha
transformada. No `stream4`, a linha transformada e selecionada diretamente e a
fronteira registrada fica na acumulacao da saida.

## 19. Variantes `stream12-*`: reduzir pesos sem guardar 16 pesos transformados

Depois de comparar as arquiteturas de feature, a proxima linha de trabalho foi
aplicar a mesma ideia aos pesos. A pergunta passou a ser:

> Precisamos manter os 16 pesos transformados, ou podemos manter os 9 pesos
> espaciais e gerar somente a linha que os MACs usam?

Essa mudanca nao reduz o banco de entrada: `r_input_feat[0:15]` continua
necessario. Ela reduz ou reorganiza somente o lado dos pesos.

### 19.1 `stream12-wstream4`

Arquivo: `conv-i16-h13-t08-o4-m04-stream12-wstream4.sv`.

| Banco | Palavras |
| --- | ---: |
| `r_input_feat[0:15]` | 16 |
| `r_weight_spatial[0:8]` | 9 |
| `r_input_weight[0:3]` | 4 |
| `r_transform_row[0:3]` | 4 |
| `r_inverse_row[0:3]` | 4 |
| `r_output_write[0:3]` + `r_output_read[0:3]` | 8 |
| **total integral de dados** | **45** |

O campo `h13` e a soma dos nove pesos espaciais com os quatro pesos
transformados ativos. Nao ha um banco `r_input_weight[0:15]`: a FSM le a tile
espacial, `WeightTransform` calcula a matriz transformada e
`WeightTransformRow` seleciona a linha correspondente ao ciclo.

O ponto de economia nao e simplesmente trocar 16 por 9. Quatro palavras
transformadas ainda precisam existir para alimentar os quatro MACs; o ganho
vem de nao armazenar as outras doze ao mesmo tempo.

### 19.2 `stream12-rowconst4`

Arquivo: `conv-i16-h13-t08-o4-m04-stream12-rowconst4.sv`.

A fronteira de registradores e a mesma de `wstream4`: 9 pesos espaciais, 4
pesos ativos, 4 palavras de transformada, 4 de inversa e os bancos de saida.
Assim, a contagem integral continua em 45 palavras.

A diferenca esta no combinacional. `WeightTransformRowConst` calcula uma linha
com constantes fixas e faz o arredondamento no fim da soma. Os vetores locais
`weight[0:8]`, `sum[0:3]`, `rounded[0:3]` e `remainder[0:3]` sao sinais
combinacionais do modulo; eles nao devem ser contados como registradores.

Essa versao pode alterar area e timing mesmo mantendo a mesma contagem de
palavras. Reduzir registradores nao garante reduzir area quando o arredondamento
adiciona comparadores, extensoes de sinal e somadores.

### 19.3 `stream12-rowconst4-exact`

Arquivo: `conv-i16-h13-t08-o4-m04-stream12-rowconst4-exact.sv`.

O inventario de palavras permanece igual ao `rowconst4`: 16 de entrada, 9
espaciais, 4 ativos, 4 de transformada, 4 de inversa e 8 de saida/interface.
O sufixo `exact` muda a largura aritmetica (`WEIGHT_NBITS` e `ACC_NBITS`) e
remove o arredondamento intermediario da multiplicacao espacial. Portanto:

```text
mesmas palavras de estado != mesmos bits de estado != mesma area
```

Uma palavra de acumulador mais larga pode custar mais flip-flops e logica,
mesmo que o numero de elementos continue igual. A avaliacao correta deve
registrar tanto a quantidade de palavras quanto a largura de cada banco.

### 19.4 `stream12-exact`

Arquivo: `conv-i16-h20-t08-o4-m04-stream12-exact.sv`.

Esta variante recebe os 16 numeradores de pesos ja transformados e exatos.
Ela registra:

| Banco | Palavras |
| --- | ---: |
| `r_input_feat[0:15]` | 16 |
| `r_weight_transformed[0:15]` | 16 |
| `r_input_weight[0:3]` | 4 |
| `r_transform_row[0:3]` | 4 |
| `r_inverse_row[0:3]` | 4 |
| saida write/read | 8 |
| **total integral** | **52** |

Ela troca arredondamento no RTL por armazenamento de 16 pesos transformados
mais largos/exatos. E uma escolha diferente de `wstream4`: `wstream4` reduz o
armazenamento de pesos e calcula uma linha; `stream12-exact` preserva os 16
valores transformados para simplificar a aritmetica durante o tile.

### 19.5 `stream12-prefetch4`

Arquivo: `conv-i20-h16-t08-o4-m04-stream12-prefetch4.sv`.

Essa variante nao transforma pesos. Ela usa o mesmo nucleo `stream12` e adiciona
`r_input_prefetch[0:3]` para capturar a proxima coluna enquanto a janela atual
esta sendo processada.

```text
stream12 baseline: 16 input + 16 weights + 4 transform + 4 inverse + 8 out = 48
prefetch4:         20 input + 16 weights + 4 transform + 4 inverse + 8 out = 52
```

O banco de prefetch nao reduz o trabalho de uma janela. Ele protege a entrada
seguinte e pode reduzir bolhas entre janelas. O custo e quatro palavras extras
de estado, alem dos flags `r_input_prefetch_full` e do controle de commit.

## 20. Comparativo de registradores de dados

A tabela usa a contagem integral, incluindo `r_output_read`, porque o objetivo
e enxergar o armazenamento real. As fontes de 8 MACs foram omitidas conforme o
escopo desta documentacao.

| Arquitetura | Input | Pesos | Transform/inversa | Estado adicional de dados | Saida/interface | Total de palavras |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `all`, 16 MACs | 16 | 16 | 0 | `r_conv_input16` + `r_conv_result4` | 8 | **60** |
| `stream12`, 4 MACs | 16 | 16 | 8 | 0 | 8 | **48** |
| `stream8`, 4 MACs | 16 | 16 | 4 | 0 | 8 | **44** |
| `stream4`, 4 MACs | 16 | 16 | 0 | `r_output_accumulator4` | 8 | **44** |
| `stream12-wstream4` | 16 | 13 | 8 | 0 | 8 | **45** |
| `stream12-rowconst4` | 16 | 13 | 8 | 0 | 8 | **45** |
| `stream12-rowconst4-exact` | 16 | 13 | 8 | 0 | 8 | **45** |
| `stream12-exact` | 16 | 20 | 8 | 0 | 8 | **52** |
| `stream12-prefetch4` | 20 | 16 | 8 | 0 | 8 | **52** |

Essa tabela mostra tres licoes importantes:

1. `t00` nao quer dizer que a arquitetura tem menos registradores totais; no
   `all`, os bancos `r_conv_input` e `r_conv_result` ficam fora de `t`.
2. `stream4` e `stream8` podem empatar em palavras, mas colocam a fronteira em
   pontos diferentes do datapath.
3. A variante com menos pesos transformados (`wstream4`/`rowconst4`) pode ter
   a mesma quantidade de palavras que outra, mas usar larguras e logica muito
   diferentes.

## 21. O que a contagem nao mostra

A contagem de palavras e uma ferramenta de raciocinio arquitetural, nao um
substituto para Genus. Ela nao mostra:

- numero de flip-flops depois de otimizacao e remocao de registradores mortos;
- largura real de cada sinal, principalmente nas variantes `exact`;
- muxes necessarios para selecionar linhas e rotacionar pesos;
- profundidade dos somadores da transformada, inversa e arredondamento;
- clock-enable e atividade de cada banco;
- registradores escalares de FSM, endereco e contadores;
- area e potencia de fios longos e buffers.

Por isso a ordem correta de estudo e:

```text
contar palavras -> provar a vida dos dados -> simular bit a bit
-> sintetizar o mesmo RTL -> rodar anotada -> medir power/energia
```

Se uma reducao remove quatro palavras, mas cria uma arvore de muxes maior que
o banco removido, a sintese pode ficar pior. O registro da decisao deve mostrar
os dois lados: palavras removidas e logica adicionada.

## 22. Mapa mental final

```text
ALL16
  guarda a janela, os pesos, a entrada da convolucao, o resultado da inversa
  e o tile de saida; calcula tudo em paralelo.
        |
        | remove r_conv_input e r_conv_result; serializa os 16 produtos
        v
STREAM12
  guarda quatro linhas da transformada e quatro linhas de inversa;
  quatro ciclos de quatro MACs.
        |
        | elimina a linha de inversa porque ela pode ser consumida no ciclo
        v
STREAM8
  guarda somente r_transform_row; o acumulador de saida carrega a parcial.
        |
        | elimina tambem r_transform_row e seleciona w_conv_transform direto
        v
STREAM4
  guarda a parcial da saida, nao uma linha da transformada.
        |
        | aplica a mesma ideia aos pesos
        v
STREAM12-* WEIGHT STREAMING
  guarda 9 pesos espaciais + 4 pesos ativos, ou escolhe outra troca
  entre armazenamento, largura aritmetica, arredondamento e prefetch.
```

O principio comum e simples: uma informacao deve ser registrada somente se
precisa sobreviver a uma borda de clock. Todo o restante deve ser consumido no
ciclo em que e produzido, desde que a ordem, o valor bit-exato e o contrato de
memoria permaneçam inalterados.

## 23. Referencia convencional: `std` com 4 MACs

Arquivo: `conv-i16-h16-t16-o4-m04-std.sv`.

Embora a ordem principal deste guia comece pelo `all`, a versao convencional e
um ponto de comparacao importante. Ela registra a matriz transformada inteira
em `r_conv_temp[0:15]` e ainda conserva `r_conv_input[0:15]` para a entrada da
convolucao. O caminho de produtos e parametrizado por `NUM_MULT`, mas o caso
documentado aqui usa quatro MACs.

| Banco | Palavras | Papel |
| --- | ---: | --- |
| `r_input_feat[0:15]` | 16 | Janela 4x4 |
| `r_input_weight[0:15]` | 16 | Pesos transformados |
| `r_conv_temp[0:15]` | 16 | Matriz transformada registrada |
| `r_conv_input[0:15]` | 16 | Fronteira da entrada da convolucao |
| `r_output_write[0:3]` + `r_output_read[0:3]` | 8 | Saida e contribuicao anterior |
| **total integral de dados** | **72** |

O `std` mostra por que o campo `t16` sozinho nao descreve todo o custo: o
banco `r_conv_input` acrescenta outras 16 palavras. A primeira familia
streaming remove primeiro esse banco duplicado; em seguida troca
`r_conv_temp[16]` por uma linha ou por selecao combinacional.

## 24. O generic `stream12`

Arquivo: `conv-i16-h16-t08-o4-mxx-stream12-generic.sv`.

O generic nao cria uma nova estrategia de armazenamento. Ele implementa a mesma
organizacao `stream12` e escolhe `NUM_MULT` igual a 2, 4 ou 8. Para a variante
de quatro MACs, o inventario e o mesmo do `stream12` fixo: 16 palavras de
entrada, 16 de pesos, 4 de transformada, 4 de inversa e 8 de saida/interface,
totalizando 48 palavras de dados.

Quando `NUM_MULT=2`, a largura dos bancos `r_transform_row` e
`r_inverse_row` continua sendo determinada pela matriz 4x4; o que muda e o
numero de lanes de produto e a quantidade de ciclos Hadamard. Portanto, reduzir
MACs nao reduz automaticamente os bancos de transformada/inversa. A arquitetura
precisa de um banco menor somente quando o agendamento tambem muda a fronteira
de dados.

As configuracoes de oito MACs do generic e dos fontes fixos foram deixadas fora
deste guia, conforme o escopo solicitado. Elas duplicam lanes de produto e
algumas instancias de inversa, mas nao mudam o principio da contagem.

## 25. Como comparar duas alteracoes sem se enganar

Ao comparar duas fontes, preencha esta sequencia antes de olhar para area:

1. Liste cada declaracao `r_*` que possui vetor de dados.
2. Separe bancos de dados de contadores, estados e enderecos.
3. Para cada banco, escreva quando ele recebe um valor e por quantos ciclos o
   valor precisa continuar valido.
4. Marque se o mesmo valor aparece em outro banco com outro nome.
5. Conte palavras e bits separadamente.
6. Identifique o fio combinacional que passou a fazer o trabalho do banco
   removido.

Um exemplo concreto:

```text
remover r_transform_row[4]
  ganho: -4 palavras e -80 bits
  substituto: muxes de w_conv_transform indexados por r_transform_product_idx
  risco: caminho combinacional maior e selecao desalinhada com os pesos

remover r_inverse_row[4]
  ganho: -4 palavras e -80 bits
  substituto: InverseRow alimentado diretamente por w_inverse_product_row
  risco: perder somente trace ou, se houver outro fanout, perder dado funcional
```

O segundo caso e seguro somente depois de procurar todos os consumidores do
sinal. Uma linha usada apenas por `$display` e diferente de uma linha usada
como entrada de `InverseRowAccumulate`.

## 26. Regra pratica para as proximas reducoes

A sequencia de reducao que este inventario recomenda e:

```text
1. retirar bancos duplicados (`r_conv_input`, `r_conv_result`)
2. retirar linhas que sao somente trace (`r_inverse_row` quando comprovado)
3. mover a fronteira da transformada (`r_transform_row` versus mux direto)
4. dobrar ou reutilizar o acumulador de saida
5. somente depois reduzir o banco de pesos
6. por ultimo avaliar prefetch e overlap de entrada
```

Essa ordem evita otimizar o lugar errado. O banco de pesos espaciais de nove
palavras parece menor que 16, mas pode exigir transformadores, arredondadores e
controle de linhas. O prefetch de quatro palavras parece pequeno, mas aumenta a
vida da entrada e pode permitir que a FSM leia enquanto a convolucao esta
ocupada.

O criterio final continua sendo triplo:

```text
mesmos resultados + mesma interface de memoria + menor custo medido
```

Uma contagem menor que falha no golden, perde uma contribuicao de canal ou
precisa de uma arvore de muxes maior nao e uma reducao arquitetural valida.
