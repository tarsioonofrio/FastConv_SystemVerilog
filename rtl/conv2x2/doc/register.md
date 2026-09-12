# Conv2x2stream00: registro de reducao de armazenamento

Este documento registra, em ordem executavel, as alteracoes do datapath
streaming e a motivacao de cada uma. A finalidade e permitir que cada etapa
seja aplicada e validada isoladamente, sem confundir reducao de registradores
com uma mudanca funcional no algoritmo Winograd/Toom-Cook.

As referencias a `tcn4-*` e `stream4/tcn4-*` nas secoes historicas preservam os
nomes usados nas campanhas originais. Na arvore ativa, os sufixos `stream00`,
`stream04` e `stream08` seguem o campo `t**` do nome do RTL. A arvore foi
achatada: cada resultado de sintese agora fica diretamente em
`synthesis/<nome-do-arquivo-rtl-sem-.sv>/`, conforme a lista atual em
`README.md`.

O estado documentado nesta revisao inclui o commit `8c5407a9`
(`refactor: reuse stream4 output registers`). Nele, as variantes stream00 m04 e
m08 passam a reutilizar `r_output_write` como acumulador da inversa e como banco
final de saida; os resultados de simulacao, sintese e power citados abaixo sao
identificados como historicos ou atuais conforme a campanha que os produziu.

## 0. A historia da reducao: do `std` ao streaming

A forma mais facil de entender estas arquiteturas e acompanhar a vida dos
dados, e nao apenas comparar os nomes dos arquivos. A historia comeca em
`conv-i16-h16-t16-o4-m04-std.sv`, que e a referencia convencional, e segue por
cinco perguntas sucessivas:

```text
std -> all16 -> stream08 -> stream04 -> stream00 -> stream08-*
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
deixa de existir, mas a arquitetura ainda conserva `r_conv_input[16]`. A
inversa agora e capturada diretamente no banco de saida, sem uma copia
intermediaria:

```text
std:   16 input + 16 weights + 16 temp + 16 conv_input + 8 output = 72
all:   16 input + 16 weights + 16 conv_input + 8 output = 56
```

O `all` reduz 16 palavras em relacao ao `std`, mas aumenta de 4 para 16 MACs.
Ele e importante porque mostra duas reducoes distintas: eliminamos o banco da
transformada registrada e, depois, a captura intermediaria da inversa, sem
alterar o ciclo em que o resultado e armazenado.

### 0.3 Segunda mudanca: `stream08`

O `stream08` aceita quatro MACs novamente, mas conserva somente o grupo ativo
de quatro valores da transformada. A matriz `w_conv_transform[0:15]` continua
sendo calculada combinacionalmente; `r_transform_row[0:3]` guarda a faixa que
sera usada no ciclo seguinte. A inversa passa a ser consumida por linhas:

```text
all:       16 input + 16 weights + 16 conv_input + 8 output = 56
stream08:  16 input + 16 weights +  4 transform + 4 inverse + 8 output = 48
```

O ganho de 8 palavras vem de remover a fronteira grande `r_conv_input[16]`;
o `all` ja nao possui uma copia intermediaria da inversa. O acumulado de quatro pixels fica no
banco de saida, e a inversa incremental substitui a matriz de resultado inteira.

### 0.4 Terceira mudanca: `stream04`

No `conv-i16-h16-t04-o4-m04-stream04.sv`, a linha transformada continua
registrada, mas `r_inverse_row[0:3]` deixa de ser necessario. O produto atual
entra diretamente em `InverseRow`; somente o acumulado entre linhas atravessa o
clock em `r_output_write[0:3]`:

```text
stream08: 16 input + 16 weights + 4 transform + 4 inverse + 8 output = 48
stream04:  16 input + 16 weights + 4 transform              + 8 output = 44
```

O sufixo `stream04` segue a fronteira `t04` do RTL e nao a quantidade de MACs:
o arquivo documentado aqui usa quatro MACs. A quantidade de lanes continua
descrita separadamente pelo campo `m04`.

### 0.5 Quarta mudanca: `stream00`

No `conv-i16-h16-t00-o4-m04-stream00.sv`, o banco
`r_transform_row[0:3]` tambem e removido. O indice
`r_transform_product_idx` seleciona diretamente quatro elementos de
`w_conv_transform`. A memoria economizada na transformada reaparece como
`r_output_accumulator[0:3]`, necessario para manter a soma parcial da inversa.
Nas variantes `conv-i16-h16-t00-o4-m04-stream00.sv` e
`conv-i16-h16-t00-o4-m08-stream00.sv`, esse banco e eliminado e
`r_output_write[0:3]` assume as duas funcoes:

```text
stream04: 16 input + 16 weights + 4 transform              + 8 output = 44
stream00-m04: 16 input + 16 weights                          + 8 output = 40
stream00-m08: 16 input + 16 weights                          + 8 output = 40
```

Nas duas variantes, o banco de escrita e reutilizado como acumulador porque a
FSM nao escreve a memoria externa durante HADAMARD. O beneficio nominal e de
quatro palavras (80 bits em `NBITS=20`). Na síntese regenerada do m04, porem,
Genus ja havia eliminado a redundancia equivalente da versao anterior: o
numero de celulas e a area permaneceram iguais, enquanto a potencia caiu
ligeiramente.

### 0.6 Quinta mudanca: variantes `stream08-*`

Depois de reduzir o armazenamento das features, a mesma pergunta foi aplicada
aos pesos. O `stream08-wstream4` e o `stream08-rowconst4` deixam de registrar
16 pesos transformados e passam a guardar nove pesos espaciais mais quatro
pesos transformados ativos:

```text
stream08:       h16 + t08
stream08-* row: h09 espacial + h04 ativo + t08
```

O total de dados cai de 48 para 45 palavras, mas parte do trabalho migrado
para os registradores aparece como logica combinacional de transformacao de
peso. O `rowconst4-exact` mantem a mesma quantidade de palavras, mas usa
larguras maiores e elimina arredondamentos intermediarios. Ja o
`stream08-prefetch4` faz a troca oposta: adiciona quatro palavras para manter a
proxima coluna viva e permitir sobreposicao entre leitura e processamento.

Assim, a historia completa nao e simplesmente "cada arquivo tem menos
registradores":

```text
std       guarda etapas completas e tem 72 palavras
all16     remove a temp e a captura intermediaria, mas paraleliza tudo e fica com 56
stream08  serializa produtos e inversa e fica com 48
stream04   elimina a linha de inversa e fica com 44
stream00   remove a fronteira extra e reutiliza r_output_write, ficando com 40
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
| `conv-i16-h16-t00-o4-m04-stream00.sv` | 4 | 1 |
| `conv-i16-h16-t04-o4-m04-stream04.sv` | 4 | 1 (variante com `r_transform_row`) |
| `conv-i16-h16-t00-o4-m08-stream00.sv` | 8 | 2 |

O contrato funcional que nao pode mudar durante a reducao e:

1. a FSM de entrada continua produzindo a mesma janela e os mesmos pesos;
2. `Transform` continua calculando a mesma matriz transformada;
3. cada produto continua associado ao peso correspondente;
4. `InverseRowAccumulate` continua recebendo as linhas na mesma ordem;
5. o estado acumulado continua disponivel em `r_output_write` antes do ciclo seguinte;
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

Nos arquivos fixos `conv-i16-h16-t00-o4-m04-stream00.sv` e `conv-i16-h16-t00-o4-m08-stream00.sv`, `r_inverse_row` recebia
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

Para `conv-i16-h16-t00-o4-m08-stream00.sv`, o segundo caminho continua usando
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
- nenhuma referencia residual ao banco `r_inverse_row` nem à instancia
  `InverseRow` que existia somente para trace;
- as referencias funcionais a `w_inverse_partial_current` e às instancias
  `inverse_row_current`/`inverse_row_lane1` continuam esperadas e nao devem
  ser removidas.

## 4. Evidencia da Alteracao 1

### `conv4mac`

Comando:

```bash
make run-stream08 NUM_MULT=4
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
make run-stream08 NUM_MULT=8
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

Esta alteracao foi inicialmente experimentada nas variantes stream00 m04 e m08.
No estado atual, a fronteira foi removida dos arquivos
`conv-i16-h16-t00-o4-m04-stream00.sv` e
`conv-i16-h16-t00-o4-m08-stream00.sv`: os MACs selecionam diretamente a faixa
correspondente de `w_conv_transform` usando `r_transform_product_idx`. A
variante que preserva essa fronteira esta em
`conv-i16-h16-t04-o4-m04-stream04.sv`, que funciona como comparador experimental
de area e timing. `r_transform_row` e diferente de `r_inverse_row`: ele segura a linha
transformada entre a captura no estado `TRANSFORM`/`HADAMARD` e o ciclo em que
os MACs a consomem. A selecao combinacional sem essa fronteira foi mantida
como a implementacao atual do stream00; a variante
`conv-i16-h16-t04-o4-m04-stream04.sv` restaura `r_transform_row` porque a
sintese mostrou uma reducao material de area.

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

Na variante sem o banco, a declaracao de `r_transform_row` foi removida e
`w_transform_feature` passou a usar diretamente os indices da linha atual. A
regressao funcional passou, mas a sintese contabilizou os muxes de selecao
dentro da hierarquia `Transform`.

Na variante `conv-i16-h16-t04-o4-m04-stream04.sv`, `r_transform_row[0..3]` foi restaurado:

- a primeira linha `w_conv_transform[0..3]` e capturada na entrada do Hadamard;
- as linhas seguintes `4..7`, `8..11` e `12..15` sao carregadas nas bordas dos
  ciclos correspondentes;
- os MACs leem somente o banco registrado durante cada ciclo.

`conv-i16-h16-t00-o4-m04-stream00.sv` continua sendo a referencia sem essa fronteira, e
`conv-i16-h16-t00-o4-m08-stream00.sv` continua sendo uma variante separada e nao e alterada
por esta restauracao.

O acumulador, os pesos, os contadores e a ordem da inversa nao foram
alterados.

### Reducao obtida

Na variante `conv-i16-h16-t04-o4-m04-stream04.sv`, a restauracao recoloca 4 palavras de 20
bits (80 bits) e deixa somente a reducao de `r_inverse_row` em relacao ao estado
original. A sintese atual produziu 6.515 celulas, 10.857,984 de area total e
1.768,687 de area na hierarquia `Transform`, contra 8.765 celulas, 12.072,861
e 2.987,622 respectivamente na variante sem `r_transform_row`. Portanto, os 80 bits
adicionais reduziram a area total em aproximadamente 10,1% e a area atribuida
`Transform` em aproximadamente 40,8%.

### Evidencia

O teste da variante `conv-i16-h16-t04-o4-m04-stream04.sv` continua funcionalmente
equivalente:

```text
conv4mac: inverse_tiles=2025 cycles=27724 valid_writes=8100
          input_samples_clipped=0 invalid_output_beats=0
```

Nenhum erro de golden output foi observado. A simulacao anotada do netlist
regenerado tambem passou com `cycles=27725` e 0 erros de elaboracao.

## 6. Alteracao 3: reutilizar `r_output_write` como acumulador

Esta alteracao foi aplicada a `conv-i16-h16-t00-o4-m04-stream00.sv` e
`conv-i16-h16-t00-o4-m08-stream00.sv`. Antes, quatro palavras de
`r_output_accumulator` mantinham a soma parcial e outras quatro palavras de
`r_output_write` mantinham o tile final. Como a FSM nao escreve a memoria
externa durante HADAMARD, os dois papeis podem usar o mesmo banco.

O `STREAMING_DATAPATH_BLOCK` agora zera `r_output_write` no inicio da janela e
grava nele `w_output_acc_next` a cada ciclo HADAMARD. O `OUTPUT_DATA_BLOCK`
deixou de escrever esse banco e permanece responsavel apenas por
`r_output_read`. Assim, nao existem dois processos sequenciais dirigindo o
mesmo sinal.

```text
antes: r_output_accumulator[4] -> acumulacao
       r_output_write[4]       -> escrita
depois: r_output_write[4]      -> acumulacao e escrita
```

A reducao nominal e de quatro palavras, ou 80 bits com `NBITS=20`. O criterio
de aceite foi a simulacao bit a bit das variantes m04 e m08:

```text
stream00 m04: inverse_tiles=2025 cycles=27725 valid_writes=8100
stream00 m08: inverse_tiles=2025 cycles=23675 valid_writes=8100
input_samples_clipped=0 invalid_output_beats=0 (ambas)
```

A síntese regenerada do m04 produziu 8.473 células, área 12.127,770 um2,
slack de 243 ps e potência de 0,684856 mW. A área permaneceu igual à rodada
anterior porque o Genus já removia a redundância equivalente; a potência foi
recalculada com o novo netlist.

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
6. somente entao estudar a reutilizacao de `r_output_write` ou uma acumulacao dobrada;
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
fixos (`conv-i16-h16-t00-o4-m04-stream00.sv` e `conv-i16-h16-t00-o4-m08-stream00.sv`). O nome do topo e os caminhos das listas
precisam continuar coerentes com o layout local para que a sintese nao leia
fontes de outra pasta.

### Mudanca aplicada

Os scripts de parsing que originaram as campanhas historicas de
`stream4/tcn4-04mac` e `stream4/tcn4-08mac` foram corrigidos para:

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
- `make run-stream04-4mac` e `make run-stream00-8mac` passam no RTL;
- uma campanha final de Genus para as duas configuracoes, seguida de
  simulacao anotada e power usando os artefatos dessa mesma campanha.

## 10. Configuracao de sintese por variante

As configuracoes ativas foram achatadas para diretorios nomeados pelo arquivo
RTL. Os caminhos atuais sao:

| Configuracao | Fonte do core | Parametro |
| --- | --- | --- |
| `conv-i16-h16-t00-o4-m04-stream00` | `conv-i16-h16-t00-o4-m04-stream00.sv` | fixo em 4 MACs |
| `conv-i16-h16-t04-o4-m04-stream04` | `conv-i16-h16-t04-o4-m04-stream04.sv` | fixo em 4 MACs |
| `conv-i16-h16-t00-o4-m08-stream00` | `conv-i16-h16-t00-o4-m08-stream00.sv` | fixo em 8 MACs |

As listas antigas apontavam para `rtl/conv2x2/synthesis/stream12`, de modo que os
logs/registros de sintese daquele layout nao comprovavam a
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

Os relatórios permanecem no Paxos e no espelho local, sob os diretórios
`rtl/conv2x2/synthesis/conv-i16-h16-*/{logical,power}`. Os caminhos históricos
`rtl/conv2x2/synthesis/tcn4-*` não fazem parte da árvore ativa. Eles devem ser
copiados ou regenerados quando uma nova alteração de RTL for feita; não se
deve misturar esses números com os logs legados que apontavam para
`conv2x2/synthesis/stream08`.

## 12. Remocao dos estados TRANSFORM e INVERSE

Depois da campanha gate-level anterior, a arquitetura stream foi simplificada
para refletir o caminho real do datapath. As variantes fixas `conv-i16-h16-t00-o4-m04-stream00.sv` e
`conv-i16-h16-t00-o4-m08-stream00.sv` passaram a usar somente os estados necessarios. A antiga fonte de
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
| `conv-i16-h16-t00-o4-m04-stream00.sv` | 2.025 | 27.724 | 8.100 | 8.100 |
| `conv-i16-h16-t00-o4-m08-stream00.sv` | 2.025 | 23.674 | 4.050 | 8.100 |

Os resultados mostram a remocao dos dois ciclos de controle por janela sem
alterar os dados: todos os golden checks passaram, nao houve escrita fora da
faixa e cada variante manteve 2.025 tiles e 8.100 escritas. A campanha unica
de Genus, anotada e Joules foi entao executada no Paxos a partir deste RTL.
Os numeros abaixo substituem os da secao 11 para esta microarquitetura:

| Variante | Celulas | Area total (um2) | Flip-flops | Slack nominal (ps) | Power total (mW) |
| --- | ---: | ---: | ---: | ---: | ---: |
| `stream4/tcn4-04mac` | 8.473 | 12.127,770 | 1.024 | 243 | 0,684856 |
| `stream4/tcn4-08mac` | 11.818 | 16.855,605 | 1.023 | 206 | 0,918483 |

A anotada final usou os netlists desta mesma campanha e a biblioteca
`work_gate_final`, sem compilar o RTL comportamental junto com o netlist:

| Variante | SDF errors | SDF warnings | Inverse tiles | Ciclos totais | Ciclos ativos | Escritas validas |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `stream4/tcn4-04mac` | 0 | 950 | 2.025 | 27.725 | 8.100 | 8.100 |
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
`stream00` foram atualizadas em 11/09/2026 com sintese, SDF, anotada e Joules
gerados a partir dos RTLs `conv-i16-h16-t00-o4-m04-stream00.sv` e `conv-i16-h16-t00-o4-m08-stream00.sv`.
A rodada inclui a reutilizacao de `r_output_write` tambem no m04; a area
permaneceu igual apos a otimizacao do Genus e a potencia foi recalculada.

| Variante | Fonte | Anotada | Celulas | Area total (um2) | Data path (ps) | Slack (ps) | Ciclos | Power (mW) | Energia (nJ) |
| --- | --- | :---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Conv std 4 MACs | `conv-i16-h16-t16-o4-m04-std.sv` | PASS | 6.613 | 12.017,925 | 763 | 237 | 23.677 | 0,826093 | 39,119 |
| Conv all 16 MACs | `conv-i16-h16-t00-o4-m16-all.sv` | PASS | 15.200 | 23.129,636 | 764 | 236 | 23.672 | 0,650788 | 30,811 |
| Stream00 4 MACs, banco compartilhado | `conv-i16-h16-t00-o4-m04-stream00.sv` | PASS | 8.473 | 12.127,770 | 757 | 243 | 27.725 | 0,684856 | 37,975 |
| Stream00 8 MACs | `conv-i16-h16-t00-o4-m08-stream00.sv` | PASS | 11.818 | 16.855,605 | 794 | 206 | 23.675 | 0,918483 | 43,490 |
| Stream04 4 MACs, `r_transform_row` | `conv-i16-h16-t04-o4-m04-stream04.sv` | PASS | 6.515 | 10.857,984 | 757 | 243 | 27.725 | 0,582814 | 32,317 |
| Stream08 2 MACs (historical) | `conv-i16-h16-t08-o4-mxx-stream08-generic.sv` | PASS | 6.483 | 11.012,366 | 766 | 234 | 29.749 | 0,531211 | 31,606 |
| Stream08 4 MACs | `conv-i16-h16-t08-o4-m04-stream08.sv` | PASS | 6.478 | 11.010,342 | 774 | 226 | 29.749 | 0,508947 | 30,281 |
| Stream08 8 MACs | `conv-i16-h16-t08-o4-m08-stream08.sv` | PASS | 10.394 | 15.873,661 | 752 | 248 | 25.699 | 0,669638 | 34,418 |

### Leitura dos resultados

- A antiga igualdade entre `stream00` e `stream08` nao existe quando os RTLs
  corretos sao sintetizados. Em 4 MACs, `stream00` usa 8.473 celulas contra
  6.478 de `stream08`; em 8 MACs, usa 11.818 contra 10.394.
- Dentro da familia `stream00`, a variante de 8 MACs reduz a latencia em
  4.050 ciclos em relacao a 4 MACs, mas aumenta area, caminho critico,
  potencia e energia.
- A variante `stream04` com `r_transform_row` e a menor em area e potencia entre as
  duas variantes de 4 MACs: -10,5% de area total e -15,8% de energia em relacao
  a `stream00` sem essa fronteira, neste workload.
- `stream00` e `stream08` nao sao comparaveis apenas pelo numero de MACs: usam
  agendamentos, fronteiras de registradores e implementacoes de matriz
  diferentes. A comparacao correta exige manter separadas a fonte HDL, o
  netlist, o SDF e a anotada de cada configuracao.
- Nao ha uma sintese atual versionada para uma variante convencional de 8
  MACs nesta arvore; por isso ela nao foi inventada ou extrapolada na tabela.

Os relatorios canônicos de `stream00` estao atualmente em
`archive/m04/synthesis/conv-i16-h16-t00-o4-m04-stream00/` e
`synthesis/conv-i16-h16-t00-o4-m08-stream00/`. Os caminhos antigos
`synthesis/stream4/tcn4-04mac/` e `synthesis/stream4/tcn4-08mac/` pertencem às
campanhas historicas e nao devem ser usados como origem da arvore atual. A
proveniencia do HDL usado pelo Genus e a anotada correspondente permanecem nos
respectivos `logical/genus.log` e `sim/xrun.log`. Os valores de `stream08`,
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
`r_output_accumulator`, `r_output_read` e um banco de prefetch sao
registradores reais, mas nao estao todos codificados nos cinco
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
| `r_output_write[0:3]` | 4 | Mantem os quatro valores que serao escritos |
| `r_output_read[0:3]` | 4 | Mantem a contribuicao anterior de outro canal |
| **total de dados** | **56** | Soma dos bancos acima |

Os 56 valores sao uma contagem de armazenamento de dados, nao uma contagem de
flip-flops sintetizados. Ainda existem registradores escalares de endereco,
contagem de janela, canais, FSM e controle de leitura/escrita.

### 15.2 Sequencia de vida dos dados

1. A FSM de entrada preenche `r_input_feat` com a janela 4x4.
2. A FSM de pesos preenche `r_input_weight` com 16 pesos.
3. `Transform` calcula `w_conv_transform[0:15]`. Esse vetor e `w_*`: e fio,
   nao banco registrado.
4. Os 16 `Multip` calculam `w_conv_product[0:15]` no mesmo ciclo.
5. `Inverse` calcula `w_conv_inverse[0:3]`, tambem combinacional.
6. `r_output_write` captura diretamente `w_conv_inverse` no mesmo ciclo em que
   `st_input_current == CONV_INPUT`; nao existe uma copia intermediaria.
7. `r_output_read` guarda a contribuicao anterior que sera somada pelo banco
   de saida.

O ponto importante e que o `all` troca tempo por largura: ele mantem mais
fronteiras de dados, mas termina uma janela Hadamard em um unico ciclo. A
primeira reducao streaming nao tenta remover o banco de entrada ou o banco de
pesos; ela remove as fronteiras completas do caminho de transformada, produto e
inversa.

## 16. Segunda etapa: `stream08`

Arquivo principal: `conv-i16-h16-t08-o4-m04-stream08.sv`.

O `stream08` mantem a janela e os pesos completos, mas percorre os 16 produtos
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

O `stream08` elimina `r_conv_input[16]`, pois a entrada ja esta em `r_input_feat`
e o acumulador de saida pode ser atualizado uma linha
por ciclo. Em troca, introduz `r_transform_row[4]`, `r_inverse_row[4]` e dois
indices curtos (`r_transform_product_idx` e `r_inverse_row_idx`).

Em palavras de dados, a transicao e:

```text
all16:    16 input + 16 weights + 16 conv_input + 4 out + 4 read = 56
stream08: 16 input + 16 weights +  4 transform  + 4 inverse    + 4 out + 4 read = 48
```

A reducao nominal e de 8 palavras, ou 160 bits a 20 bits por palavra. Ela
nao implica automaticamente 11% de area, porque a multiplexacao, os quatro
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
baseline nao e ainda o limite minimo da familia `stream08`.

## 17. Terceira etapa: `stream04`

Arquivo: `conv-i16-h16-t04-o4-m04-stream04.sv`.

O sufixo `stream04` identifica a fronteira `t04`; esta fonte fixa tem quatro
MACs. Somente uma linha de quatro valores da
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

Em comparacao direta com o `stream08`, saem as quatro palavras de
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

## 18. Quarta etapa: `stream00`

Arquivo: `conv-i16-h16-t00-o4-m04-stream00.sv`.

Aqui a fronteira `r_transform_row` tambem foi removida. `Transform` continua
produzindo os 16 valores, mas eles permanecem em `w_conv_transform`; o indice
`r_transform_product_idx` seleciona diretamente os quatro valores que alimentam
os MACs no ciclo corrente.

### 18.1 Bancos registrados

| Banco | Palavras | Motivo |
| --- | ---: | --- |
| `r_input_feat[0:15]` | 16 | Mantem o tile de entrada |
| `r_input_weight[0:15]` | 16 | Mantem e rotaciona os pesos |
| `r_output_write[0:3]` | 4 | Acumula a inversa e depois fornece o tile a FSM de saida |
| `r_output_read[0:3]` | 4 | Mantem a contribuicao anterior |
| **total integral de dados** | **40** |

O `t00` agora faz sentido para a transformada: nao existe banco registrado de
transformada nem de linha inversa. A acumulacao tambem nao exige um banco
adicional: `r_output_write` e zerado no inicio da janela e recebe
`w_output_acc_next` em cada ciclo HADAMARD.

Por isso `stream00` m04 e m08 possuem a mesma fronteira de armazenamento:

```text
stream00-m04: 16 input + 16 weights + 4 output-write + 4 output-read = 40
stream00-m08: 16 input + 16 weights + 4 output-write + 4 output-read = 40
```

A diferenca entre m04 e m08 e temporal: m04 consome uma linha da inversa por
ciclo e precisa de quatro ciclos HADAMARD; m08 consome duas linhas e precisa de
dois ciclos. O banco registrado e o mesmo.

### 18.2 Implementacao comum do banco compartilhado

O arquivo `conv-i16-h16-t00-o4-m08-stream00.sv` usa dois grupos de quatro MACs
por ciclo e, por isso, produz duas linhas da inversa de uma vez. O arquivo m04
usa um grupo, mas segue a mesma politica: `r_output_accumulator` foi removido
e o valor anterior entra diretamente em `InverseRowAccumulate` por meio de
`r_output_write`, que recebe o novo acumulado no mesmo processo sequencial do
datapath.

O ultimo resultado ja fica em `r_output_write` quando `w_conv_end` sinaliza o
fim da convolucao. A FSM de saida apenas consome esse banco, somando
`r_output_read` quando necessario. Nao ha copia final nem ciclo adicional:

```text
HADAMARD:      r_output_write <= w_output_acc_next
fim HADAMARD:  w_conv_end <= 1
WRITE_OUTPUT:  p_output_data_write <- r_output_write + r_output_read
```

## 19. Variantes `stream08-*`: reduzir pesos sem guardar 16 pesos transformados

Depois de comparar as arquiteturas de feature, a proxima linha de trabalho foi
aplicar a mesma ideia aos pesos. A pergunta passou a ser:

> Precisamos manter os 16 pesos transformados, ou podemos manter os 9 pesos
> espaciais e gerar somente a linha que os MACs usam?

Essa mudanca nao reduz o banco de entrada: `r_input_feat[0:15]` continua
necessario. Ela reduz ou reorganiza somente o lado dos pesos.

### 19.1 `stream08-wstream4`

Arquivo: `conv-i16-h13-t08-o4-m04-stream08-wstream4.sv`.

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

### 19.2 `stream08-rowconst4`

Arquivo: `conv-i16-h13-t08-o4-m04-stream08-rowconst4.sv`.

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

### 19.3 `stream08-rowconst4-exact`

Arquivo: `conv-i16-h13-t08-o4-m04-stream08-rowconst4-exact.sv`.

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

### 19.4 `stream08-exact`

Arquivo: `conv-i16-h20-t08-o4-m04-stream08-exact.sv`.

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
armazenamento de pesos e calcula uma linha; `stream08-exact` preserva os 16
valores transformados para simplificar a aritmetica durante o tile.

### 19.5 `stream08-prefetch4`

Arquivo: `conv-i20-h16-t08-o4-m04-stream08-prefetch4.sv`.

Essa variante nao transforma pesos. Ela usa o mesmo nucleo `stream08` e adiciona
`r_input_prefetch[0:3]` para capturar a proxima coluna enquanto a janela atual
esta sendo processada.

```text
stream08 baseline: 16 input + 16 weights + 4 transform + 4 inverse + 8 out = 48
prefetch4:         20 input + 16 weights + 4 transform + 4 inverse + 8 out = 52
```

O banco de prefetch nao reduz o trabalho de uma janela. Ele protege a entrada
seguinte e pode reduzir bolhas entre janelas. O custo e quatro palavras extras
de estado, alem dos flags `r_input_prefetch_full` e do controle de commit.

### 19.6 `stream08-prefetch4-rowconst4`

Arquivo ativo: `conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4.sv`.

Esta variante combina o prefetch de quatro amostras com a tecnica
`rowconst4`. O tile espacial de pesos continua registrado em
`r_weight_spatial[0:8]`, mas apenas as oito palavras transformadas das duas
linhas consumidas pelos oito MACs ficam no banco ativo `r_input_weight[0:7]`.
As quatro instancias `WeightTransformRowConst` geram as linhas sob o controle
da FSM de Hadamard; nao ha um banco registrado de 16 pesos transformados.

```text
entrada:       16 palavras da janela + 4 palavras do prefetch
pesos:           9 palavras espaciais + 8 palavras transformadas ativas
computacao:      8 MACs, duas linhas por ciclo de Hadamard
```

O prefetch so e habilitado depois que o primeiro tile de pesos foi carregado.
Na borda direita ou quando o banco ainda nao esta cheio, a variante preserva
o deslocamento de duas colunas do `stream08` original; quando o banco esta
cheio, o commit substitui as colunas novas antes da leitura da segunda coluna.
O baseline `rowconst4` anterior foi preservado em
`archive/m08/conv-i16-h13-t08-o4-m08-stream08-rowconst4.sv` e sua configuracao
de sintese correspondente em `archive/m08/synthesis/`.

## 20. Comparativo de registradores de dados

A tabela usa a contagem integral, incluindo `r_output_read`, porque o objetivo
e enxergar o armazenamento real. As fontes de 8 MACs foram omitidas conforme o
escopo desta documentacao.

| Arquitetura | Input | Pesos | Transform/inversa | Estado adicional de dados | Saida/interface | Total de palavras |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `all`, 16 MACs | 16 | 16 | 0 | `r_conv_input16` | 8 | **56** |
| `stream08`, 4 MACs | 16 | 16 | 8 | 0 | 8 | **48** |
| `stream04`, 4 MACs | 16 | 16 | 4 | 0 | 8 | **44** |
| `stream00`, 4 MACs, banco compartilhado | 16 | 16 | 0 | 0 | 8 | **40** |
| `stream00`, 8 MACs, banco compartilhado | 16 | 16 | 0 | 0 | 8 | **40** |
| `stream08-wstream4` | 16 | 13 | 8 | 0 | 8 | **45** |
| `stream08-rowconst4` | 16 | 13 | 8 | 0 | 8 | **45** |
| `stream08-rowconst4-exact` | 16 | 13 | 8 | 0 | 8 | **45** |
| `stream08-exact` | 16 | 20 | 8 | 0 | 8 | **52** |
| `stream08-prefetch4` | 20 | 16 | 8 | 0 | 8 | **52** |

Essa tabela mostra tres licoes importantes:

1. `t00` nao quer dizer que a arquitetura tem menos registradores totais; no
   `all`, o banco `r_conv_input` fica fora de `t`, enquanto a inversa e
   capturada diretamente no banco de saida.
2. `stream00` e `stream04` podem empatar em palavras, mas colocam a fronteira em
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
  guarda a janela, os pesos, a entrada da convolucao e o tile de saida;
  calcula tudo em paralelo e captura a inversa diretamente na saida.
        |
        | remove r_conv_input; serializa os 16 produtos
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
STREAM08-* WEIGHT STREAMING
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

## 24. O generic `stream08`

Arquivo: `conv-i16-h16-t08-o4-mxx-stream08-generic.sv`.

O generic nao cria uma nova estrategia de armazenamento. Ele implementa a mesma
organizacao `stream08` e escolhe `NUM_MULT` igual a 4 ou 8. Para a variante
de quatro MACs, o inventario e o mesmo do `stream08` fixo: 16 palavras de
entrada, 16 de pesos, 4 de transformada, 4 de inversa e 8 de saida/interface,
totalizando 48 palavras de dados.

O caminho de dois MACs foi retirado do generic. Assim, qualquer parametrizacao
fora de `{4,8}` falha no `STREAM_PARAMETER_CHECK_BLOCK`, em vez de selecionar
um datapath parcialmente implementado. Reduzir MACs nao reduz automaticamente
os bancos de transformada/inversa; uma variante com banco menor exige uma
mudanca explicita de agendamento e fronteira de dados.

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
1. retirar bancos duplicados (`r_conv_input` e capturas intermediarias da saida)
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

## 27. Conversao dos modelos m04 para m08

Na rodada de setembro de 2026, os modelos ativos que só tinham quatro MACs
receberam uma variante `m08` separada. Os arquivos e diretórios `m04` foram
movidos para `archive/m04/` como referência histórica para que os resultados
anteriores de área, timing e potência continuem reproduzíveis.

Nos novos `stream04` e `stream08-*`, cada ciclo de Hadamard consome duas linhas
de quatro elementos: a primeira linha permanece registrada e a segunda é
alimentada diretamente pela transformada. A inversa é feita em dois blocos
`InverseRow` e dois `InverseRowAccumulate`, com avanço de
`r_inverse_row_idx` em dois. Assim, há oito instâncias físicas de `Multip` (ou
`MultipExact`/`MultipSpatialExact` nas variantes exatas) sem alterar a
interface externa `Conv`.

Arquivos `m08` adicionados:

```text
conv-i16-h16-t16-o4-m08-std.sv
conv-i16-h16-t04-o4-m08-stream04.sv
conv-i16-h13-t08-o4-m08-stream08-wstream4.sv
conv-i16-h13-t08-o4-m08-stream08-rowconst4-exact.sv
conv-i20-h16-t08-o4-m08-stream08-prefetch4.sv
conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4.sv
conv-i16-h20-t08-o4-m08-stream08-exact.sv
```

`conv-i16-h13-t08-o4-m08-stream08-rowconst4.sv` deixou de ser ativo e foi
movido para `archive/m08/`; os seus resultados de síntese continuam sendo
coletados pelo relatório consolidado.

O alvo `make std` agora usa `conv-i16-h16-t16-o4-m08-std.sv` e passa
`NUM_MULT=8`. Os alvos explícitos de oito MACs foram adicionados ao
`Makefile`; os alvos e fontes de quatro MACs continuam disponíveis para
comparação.

O fluxo RTL foi checado com Verilator para as fontes `m08` ativas, incluindo a
nova combinação `prefetch4-rowconst4`. O fluxo de
potência foi executado na Paxos a partir do commit publicado
`bd4ff8aed77ee173682016c7a33f0d501358673e`, usando Genus 21.1, Xcelium 23.03,
o banco gate-level e o `dut.shm` produzido pela simulação. Os relatórios foram
gerados em clones isolados na Paxos; o checkout de trabalho já existente, que
continha alterações não relacionadas, não foi tocado.

Resultados nominais de `report_power -unit mW` (linha `Subtotal`):

| Variante m08 | Leakage | Internal | Switching | Total |
|---|---:|---:|---:|---:|
| `std` | 0.0527922 | 0.475721 | 0.334820 | **0.863333** |
| `stream04` | 0.0553297 | 0.411765 | 0.291210 | **0.758305** |
| `stream08-wstream4` | 0.0648294 | 0.346387 | 0.261474 | **0.672691** |
| `stream08-rowconst4` | 0.0649760 | 0.342512 | 0.264060 | **0.671548** |
| `stream08-rowconst4-exact` | 0.0693252 | 0.412595 | 0.332482 | **0.814403** |
| `stream08-exact` | 0.0602179 | 0.383106 | 0.290075 | **0.733399** |

As seis linhas acima tiveram `LOGICAL_RC=0`, `SIM_RC=0` e `POWER_RC=0`; a
simulação também reportou 2.025 tiles inversos, 8.100 escritas válidas e zero
amostras de entrada fora dos limites. A soma de percentuais `100,01%` na
linha de `rowconst4-exact` é apenas efeito do arredondamento da apresentação.

A nova `stream08-prefetch4-rowconst4` já passou pela simulação RTL com
2.025 tiles inversos, 8.100 escritas válidas e 21.892 ciclos. Sua síntese e
fluxo de potência ainda não foram executados nesta rodada; portanto ela não
entra na tabela de potência acima.

`stream08-prefetch4` teve síntese lógica concluída (`LOGICAL_RC=0`), mas sua
simulação gate-level permaneceu em `xmsim> run` sem emitir o contrato de
conclusão. Ela foi interrompida após a janela de diagnóstico e, por isso, não
há `power_evaluation.txt` válido para essa variante. O resultado não deve ser
comparado como se fosse potência medida.

Os resultados `m04` e os relatórios de síntese anteriores permanecem sob
`archive/m04/`; nenhum arquivo `m04` foi sobrescrito pelos artefatos `m08`.

## 28. Diagrama de ondas das FSMs e do prefetch

O diagrama abaixo mostra a relação temporal entre as três FSMs do
`stream08-prefetch4` e o leitor auxiliar de entrada. Cada coluna representa
um ciclo completo entre duas bordas de subida de `clk`. O nome mostrado é o
valor do estado registrado (`*_current`) durante aquele ciclo; a transição
para o próximo estado acontece na borda seguinte.

O leitor auxiliar não é uma nova enumeração dentro de `type_st_input`. Ele é
representado pelos registradores `r_input_prefetch_active`,
`r_input_prefetch_phase` e `r_input_prefetch_full`. A fase é um contador
portável: `PREFETCH_PHASES = STREAM_CYCLES + 2`, com uma fase para
`TRANSFORM`, uma para cada ciclo de `HADAMARD` e uma para `INVERSE`.
Por isso, no diagrama ele aparece como uma quarta faixa paralela à FSM de
entrada, sem acrescentar estados enumerados à FSM principal.

### 28.1 Carregamento do primeiro tile

Antes do primeiro `CONV_INPUT`, a FSM de entrada ainda precisa carregar as
quatro linhas completas da janela 4x4. A notação `[4]` significa quatro
ciclos, um para cada palavra da linha. Assim que o tile entra em
`CONV_INPUT`, o endereço da primeira coluna do tile seguinte já é emitido.
Com a latência de uma borda da RAM, a amostra chega no início de `TRANSFORM`.

```text
                         ciclos de clock  ───────────────────────────────────────────────────────────────>

FSM de entrada       WAIT_INPUT  ADDRESS_INPUT  READ_WEIGHTS[n]  READ_IN_10A[4]  READ_IN_10B[4]
                     READ_IN_8C[4]  READ_IN_8D[4]  CONV_INPUT  TRANSFER  HOLD_WRITE  ...

FSM de convolução    WAIT_CONV ────────────────────────────────────────────────┐
                                                                                └─ TRANSFORM
                                                                                   HADAMARD[2]
                                                                                   INVERSE
                                                                                   WAIT_CONV

FSM de saída         WAIT_OUTPUT  RESET_OUTPUT ────────────────────────────────┐
                                                                                └─ WRITE_OUTPUT /
                                                                                   READ_OUTPUT

Prefetch auxiliar    idle       idle       idle       idle       START  READ[0:3]  READY  COMMIT
```

Durante `TRANSFORM`, `HADAMARD` e `INVERSE`, o banco `r_input_feat` permanece
estável. O prefetch do próximo tile começa somente depois que o tile atual
foi carregado em `CONV_INPUT`; a emissão do endereço antecipado usa a borda
anterior para que a primeira amostra fique disponível em `TRANSFORM`.

### 28.2 Regime estacionário com prefetch

A partir do tile seguinte, a coluna necessária para o próximo tile é lida
durante o uso do tile corrente. A sequência abaixo não fixa a duração de
`HOLD_WRITE`, pois ela também depende da FSM de saída e de
`w_input_write_done`; ela mostra apenas a sobreposição relevante.

```text
                         k       k+1       k+2       k+3       k+4       k+5       k+6       k+7
                         │         │         │         │         │         │         │         │
clk                      ↑         ↑         ↑         ↑         ↑         ↑         ↑         ↑

FSM de entrada       CONV_INPUT TRANSFER  HOLD_WRITE HOLD_WRITE HOLD_WRITE READ_IN_8D ...
                                  │         │         │         │         │
                                  └─────────┴─────────┴─────────┴─────────┘
                                    espera a liberação e o buffer pronto

FSM de convolução    WAIT_CONV  TRANSFORM  HADAMARD  HADAMARD  INVERSE  WAIT_CONV ...

FSM de saída         RESET_OUTPUT  RESET_OUTPUT  RESET_OUTPUT  WRITE_OUTPUT /
                                                            READ_OUTPUT ...

Prefetch auxiliar    START      READ[0]   READ[1]   READ[2]   READ[3]   READY  COMMIT
                     issue      phase=0   phase=1   phase=2   phase=3   full=1 full→0

Porta de entrada     request    prefetch  prefetch  prefetch  prefetch  livre   READ_IN_8D
                     addr+b0    addr+b1   addr+b2   addr+b3
```

No ciclo `START` (`CONV_INPUT`), o leitor auxiliar emite um endereço-base
derivado da mesma progressão de `r_input_addr_feat`, mas grava em
`r_input_prefetch[0:3]`. Com a latência de uma borda da RAM, a primeira
amostra fica válida no início de `TRANSFORM`. O contador de fase
`r_input_prefetch_phase` avança apenas quando `p_input_valid` está ativo.
Assim, ele não altera `r_input_addr_count`, que continua pertencendo à FSM
principal. Para o
`stream08` atual, os valores são `0 = TRANSFORM`, `1..STREAM_CYCLES =
HADAMARD` e `STREAM_CYCLES + 1 = INVERSE`; portanto, com dois ciclos de
Hadamard, as quatro leituras são indexadas por `0, 1, 2, 3`.

O commit não ocorre simplesmente quando `full=1`. A condição é:

```text
r_input_prefetch_full
&& (w_conv_input_release || w_conv_end ||
    (st_conv_current == WAIT_CONV &&
     st_output_current inside {RESET_OUTPUT, READ_OUTPUT}))
&& w_input_write_done
```

Essa proteção impede que a coluna prefetched sobrescreva
`r_input_feat` enquanto o transformador, o Hadamard ou a inversa ainda podem
consultar o tile corrente. Depois do commit, `READ_IN_8D` captura a segunda
coluna nova e a janela seguinte fica completa.

### 28.3 Transições de controle

```text
FSM de entrada:

  READ_IN_10A ─> READ_IN_10B ─> READ_IN_8C ─> READ_IN_8D
        │                                      │
        └──────── carregamento inicial ────────┘

  CONV_INPUT ─> TRANSFER ─> HOLD_WRITE
                 │
                 ├─ prefetch incompleto: permanece em HOLD_WRITE
                 ├─ prefetch completo e commit seguro: ─> READ_IN_8D
                 └─ primeiro tile/sem prefetch: ────────> READ_IN_8C

  READ_IN_8D ─> CONV_INPUT ─> TRANSFER

FSM de convolução:

  WAIT_CONV ─> TRANSFORM ─> HADAMARD ─> INVERSE ─> WAIT_CONV
                         (2 ciclos no m08)

FSM de saída:

  WAIT_OUTPUT ─> RESET_OUTPUT ─> WRITE_OUTPUT
                              └─> READ_OUTPUT
```

A leitura do prefetch e o cálculo da convolução compartilham a porta externa
de memória de entrada, mas não compartilham seus contadores temporais. A
convolução usa `r_input_feat`; o prefetch usa `r_input_prefetch`. Essa é a
razão pela qual a implementação precisa de alguns registradores adicionais,
mas não de uma segunda cópia da FSM de endereçamento completa.
