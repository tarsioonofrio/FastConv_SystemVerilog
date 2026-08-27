# Arquitetura RTL do FastConv

Este documento descreve a arquitetura do controlador de convolucao FastConv e
a transicao da implementacao convencional para as variantes streaming. A
implementacao convencional usada como referencia esta em
[`conv3x3/conv.sv`](conv3x3/conv.sv). As variantes streaming 3x3 ficam em
[`conv3x3stream-if/`](conv3x3stream-if/) e
[`conv3x3stream-tc/`](conv3x3stream-tc/).

O mesmo principio tambem aparece nas variantes 2x2 e 4x4. O foco deste
documento e o controlador 3x3 porque ele contem os dois caminhos de
transformacao usados no repositorio: IF3x3 e TC3x3.

## 1. Visao geral

O modulo `Conv` coordena uma convolucao por janelas, canais de entrada e
canais de saida. Ele nao e apenas um conjunto de multiplicadores: o modulo
tambem gera os enderecos de memoria, carrega pesos, monta a janela de entrada,
aciona a transformacao Winograd, controla a sequencia Hadamard/inversa e
acumula os nove valores da janela de saida.

A interface externa e a mesma para o caminho convencional e para o streaming:

| Grupo | Sinais | Funcao |
| --- | --- | --- |
| Controle | `clk`, `reset`, `p_start`, `p_end` | Inicia e indica o fim de uma campanha completa. |
| Entrada | `p_input_en`, `p_input_addr`, `p_input_data`, `p_input_valid` | Le IFMAPs e pesos pela memoria compartilhada. |
| Saida | `p_output_en`, `p_output_wr`, `p_output_addr`, `p_output_data_write`, `p_output_data_read`, `p_output_valid` | Le o acumulado anterior e grava o novo tile 3x3. |

O caminho streaming altera o armazenamento interno e a sequencia de consumo,
mas preserva essa interface e o mesmo contrato numerico do golden data.

## 2. Diagrama de blocos da implementacao convencional

O diagrama abaixo mostra a relacao entre memoria, registradores, FSMs e
datapath. As caixas marcadas como `FF` sao predominantemente sequenciais; as
caixas `comb` calculam sinais sem armazenar estado.

```text
                         +----------------------+
                         |       p_start        |
                         +----------+-----------+
                                    |
                                    v
 +------------------+      +-------+---------------------------+
 | Input memory     |----->| INPUT FSM (FF + comb)              |
 | IFMAP + weights  |      | addresses, reads, windows, channels|
 +--------+---------+      +-------+-------------------+---------+
          |                         |                   |
          | p_input_data            | write/shift       | addresses
          v                         v                   |
 +------------------+      +------------------+         |
 | Weight bank (FF) |      | Feature bank (FF)|<--------+
 | r_input_weight   |      | r_input_feat     |
 +--------+---------+      +---------+--------+
          |                          |
          | weights                  | 5x5 window
          |                          v
          |                +---------+----------+
          |                | Transform (comb)  |
          |                | w_conv_transform  |
          |                +---------+----------+
          |                          |
          +--------------------------+----------------------+
                                     v                      |
                         +-----------+------------------+   |
                         | Conv datapath (FF + comb)    |   |
                         | r_conv_temp + MuxMult        |   |
                         | NUM_MULT Multip/products     |   |
                         +-----------+------------------+   |
                                     |                      |
                                     v                      |
                         +-----------+------------------+   |
                         | Inverse (comb)               |   |
                         | w_conv_inverse[0:8]          |   |
                         +-----------+------------------+   |
                                     |                      |
                                     v                      |
 +------------------+      +---------+-------------------+   |
 | Output memory    |<---->| OUTPUT FSM (FF + comb)      |   |
 | read old tile    |      | read/write, channels,       |   |
 | write new tile   |      | windows and addresses       |   |
 +------------------+      +---------+-------------------+   |
                                     |                      |
                                     v                      |
                            +--------+--------+             |
                            |      p_end      |             |
                            +-----------------+             |
                                                            |
                         +----------------------------------+
                         | CONV FSM (FF + comb)              |
                         | WAIT -> TRANSFORM ->              |
                         | HADAMARD -> INVERSE               |
                         +----------------------------------+
```

O fluxo principal e:

```text
IFMAP/pesos -> janela 5x5 -> Transform B -> Hadamard G -> Inverse A
            -> acumulacao entre canais -> memoria de saida
```

Para IF3x3, a matriz intermediaria tem 6x6 = 36 elementos. Para TC3x3, a
matriz intermediaria tem 5x5 = 25 elementos. Os nomes `IF` e `TC` indicam a
familia de matrizes e nao uma mudanca na interface do controlador.

## 3. Blocos sequenciais da implementacao convencional

Todos os blocos abaixo sao acionados pela borda de subida de `clk`; os blocos
com reset tambem respondem a `reset` assincrono. Eles representam o estado que
precisa sobreviver entre dois ciclos.

### Entrada, enderecos e registradores

- `INPUT_ADDR_POINTER_BLOCK`: atualiza `r_input_addr_feat` e
  `r_input_window_next`. O endereco e deslocado por linha, janela, canal e
  tamanho da entrada.
- `WEIGHT_ADDR_POINTER_BLOCK`: inicializa e incrementa
  `r_input_addr_kernel`, apontando para o trecho de pesos da memoria.
- `INPUT_STATE_REG_BLOCK`: registra `st_input_current`, a FSM de leitura.
- `INPUT_READ_COUNTER_BLOCK`: registra `r_input_addr_count`, usado para
  percorrer os elementos de cada linha da janela 5x5.
- `INPUT_CONTROL_COUNTERS_BLOCK`: registra contadores de canal, janela,
  coluna e pesos. Esses contadores determinam quando uma IFMAP, uma linha ou
  um canal terminou.
- `INPUT_FEATURE_REG_BLOCK`: grava os valores lidos em `r_input_feat`. A
  escrita e seletiva, usando `w_input_feat_en`, para reaproveitar a janela
  durante o deslocamento.
- `WEIGHT_REG_BLOCK`: grava os pesos em `r_input_weight` e, durante o
  Hadamard, pode rotacionar o banco para apresentar o grupo correto aos
  multiplicadores.

### Controle da convolucao

- `CONV_STATE_REG_BLOCK`: registra `st_conv_current`.
- `CONV_END_FLAG_BLOCK`: registra `w_conv_end` quando a ultima etapa da
  convolucao esta pronta para ser consumida pela FSM de saida.
- `CONV_MULTIPLY_COUNTER_BLOCK`: registra `r_conv_multiply_count` e define o
  numero de ciclos Hadamard de acordo com `STATE_MULT`.
- `CONV_DATAPATH_BLOCK`: registra a matriz inteira em `r_conv_temp` durante
  `TRANSFORM`. Em cada ciclo `HADAMARD`, desloca a matriz registrada e insere
  os novos produtos na extremidade do banco.

### Saida e acumulacao entre canais

- `OUTPUT_STATE_REG_BLOCK`: registra `st_output_current`.
- `OUTPUT_CONTROL_COUNTERS_BLOCK`: registra os contadores dos canais de
  entrada e saida atualmente acumulados.
- `OUTPUT_WINDOW_COUNTERS_BLOCK`: registra a posicao da janela na linha,
  coluna e IFMAP.
- `OUTPUT_RW_COUNTER_BLOCK`: registra os indices de leitura e escrita dos
  nove elementos do tile 3x3.
- `OUTPUT_DATA_BLOCK`: guarda em `r_output_read` o tile antigo e em
  `r_output_write` o tile produzido pela inversa.
- `OUTPUT_ADDR_POINTER_BLOCK`: registra a base do endereco de saida por
  canal, linha e coluna da janela.
- `OUTPUT_ADDR_OFFSET_BLOCK`: registra os deslocamentos internos do burst
  3x3, avancando em ordem row-major e aplicando o salto de linha.

A FSM de entrada pode continuar carregando a proxima janela enquanto a FSM de
saida conclui a leitura ou escrita da janela anterior. Os sinais
`w_input_write_done`, `w_conv_end` e os contadores de leitura/escrita fazem o
acoplamento entre essas tres FSMs.

## 4. Blocos combinacionais da implementacao convencional

Os blocos combinacionais nao guardam estado; eles calculam valores usados no
proximo ciclo ou alimentam diretamente outro bloco.

### FSMs e seletores de dados

- `INPUT_NEXT_STATE_BLOCK`: calcula `st_input_next` a partir de
  `st_input_current`, `p_start`, contadores e flags de fim.
- `INPUT_SHIFT_DATA_BLOCK`: calcula `w_input_feat_next`, escolhendo entre o
  dado lido da memoria e os valores que permanecem na janela deslocada.
- `INPUT_SHIFT_WE_BLOCK`: calcula quais posicoes de `r_input_feat` podem ser
  escritas no ciclo.
- `WEIGHT_WE_BLOCK`: calcula `w_input_weight_en`, habilitando uma posicao do
  banco de pesos durante `READ_WEIGHTS`.
- `CONV_NEXT_STATE_BLOCK`: calcula a transicao entre `WAIT_CONV`, `TRANSFORM`,
  `HADAMARD` e `INVERSE`.
- `OUTPUT_NEXT_STATE_BLOCK`: calcula a transicao entre espera, leitura,
  escrita e mudanca de canal/janela.

### Datapath combinacional

- `Transform trf`: aplica a matriz B a janela 5x5 e produz
  `w_conv_transform`.
- `MuxMult mux_mult`: traduz o indice Hadamard em indices de entrada e saida
  para o esquema de multiplicacao da implementacao convencional.
- Instancias `Multip`: calculam os produtos entre `r_conv_temp`,
  `r_input_weight` e `w_conv_product`.
- `Inverse inv`: aplica a matriz A a `r_conv_temp` e produz os nove valores de
  `w_conv_inverse`.
- Atribuicoes de flags: `w_input_weight_done`, flags de ultima janela/canal,
  `w_conv_end` e `p_end`.
- Atribuicoes de memoria: `w_output_addr`, `p_output_addr`,
  `p_output_data_write`, `p_output_en` e `p_output_wr`.

O ponto importante e que `Transform`, `Multip` e `Inverse` sao combinacionais,
mas os valores que entram neles sao escolhidos e mantidos pelos blocos
sequenciais. A FSM nao substitui o datapath; ela define quando cada parte do
datapath e valida.

## 5. Sequencia ciclo a ciclo da implementacao convencional

1. `WAIT_INPUT` aguarda `p_start`.
2. `ADDRESS_INPUT` posiciona os ponteiros da IFMAP e dos pesos.
3. `READ_WEIGHTS` carrega `r_input_weight`.
4. `READ_IN_10A` ate `READ_IN_15C` leem as linhas da janela e atualizam
   `r_input_feat`.
5. `TRANSFER` sinaliza que a janela esta pronta para a convolucao e avanca os
   contadores de janelas.
6. `TRANSFORM` calcula a matriz intermediaria e registra toda a matriz em
   `r_conv_temp`.
7. Cada ciclo `HADAMARD` multiplica um grupo de elementos, desloca
   `r_conv_temp` e insere os novos produtos.
8. `INVERSE` calcula os nove valores do tile a partir da matriz completa.
9. `RESET_OUTPUT` inicia uma escrita ou uma leitura de acumulacao.
10. `READ_OUTPUT` busca o tile anterior quando ainda existem canais de entrada
    a acumular.
11. `WRITE_OUTPUT` grava os nove resultados e decide se deve avancar para a
    proxima janela, canal ou IFMAP.

## 6. Por que criar o caminho streaming

Na implementacao convencional, `r_conv_temp` materializa a matriz
intermediaria completa. Para IF3x3 isso representa 36 palavras de registrador,
mesmo quando o datapath consome apenas uma linha transformada por ciclo.
 Existe uma declaracao de uma segunda copia da janela (`r_conv_input`) no RTL
 convencional, mas o bloco que a preencheria esta comentado; o `Transform`
 consome diretamente `r_input_feat`.

O objetivo do streaming e manter a mesma funcao matematica com menos estado:

- consumir a matriz transformada por linha, ou por um pacote fixo de linhas;
- calcular a inversa por contribuicoes parciais;
- manter apenas a linha atual, a linha de produtos e o acumulador de saida;
- preservar a FSM de memoria e o formato de saida;
- separar cada ponto fixo de MAC em um arquivo `Conv`, sem `generate` ou
  `genvar` no datapath especializado.

O caminho streaming nao e uma simples troca de nome de registradores. Ele muda
o tempo de vida dos dados: a janela precisa permanecer estavel desde
`TRANSFER` ate que a ultima linha Hadamard seja capturada.

## 7. Migracao passo a passo para `Conv` streaming

### Passo 1 - Congelar a referencia convencional

O primeiro passo foi preservar [`conv3x3/conv.sv`](conv3x3/conv.sv) como
baseline. Isso permite comparar produto, inversa, endereco, numero de ciclos e
resultado final sem misturar a reducao de registradores com uma alteracao da
interface.

Motivo: sem uma referencia congelada, um resultado diferente poderia ser
atribuido ao streaming quando na verdade viesse de uma mudanca de matriz,
quantizacao ou enderecamento.

### Passo 2 - Separar IF e TC por diretorio

Foram criadas duas familias independentes:

- [`conv3x3stream-if/`](conv3x3stream-if/): IF3x3 com 6, 12 e 18 MACs.
- [`conv3x3stream-tc/`](conv3x3stream-tc/): TC3x3 com 5 MACs.

Cada familia tem suas matrizes, `Makefile`, README e um unico
[`testbench.sv`](conv3x3stream-if/testbench.sv) compartilhado por seus
arquivos `Conv`.

Motivo: a ordem das linhas, o tamanho da matriz Hadamard e as formulas da
inversa sao diferentes entre IF e TC. Isolar os arquivos evita flags de
compilacao que poderiam selecionar uma arquitetura errada em tempo de
simulacao.

### Passo 3 - Remover o banco completo `r_conv_temp`

No caminho streaming, a transformacao continua produzindo
`w_conv_transform`, mas o resultado nao e copiado para um banco sequencial de
36 palavras. Em seu lugar, o datapath registra apenas os dados necessarios
para o proximo grupo de multiplicacoes:

- `r_d_row`: linha ou pacote de linhas do dominio transformado;
- `r_s_row`: linha de produtos Hadamard;
- `r_out_acc`: acumulador dos nove valores da inversa.

Motivo: o banco completo era o maior armazenamento especifico do core e nao
era necessario para calcular uma linha por vez.

### Passo 4 - Trocar `Inverse` completa por inversa incremental

Foram introduzidos os modulos `InverseRow` e `InverseRowAccumulate`.
`InverseRow` reduz uma linha de produtos a uma pequena quantidade de sinais
`sigma`. `InverseRowAccumulate` aplica a contribuicao da linha ao acumulador
dos nove resultados.

No TC5, as formulas de `InverseRow` seguem as combinacoes da matriz TC. No
IF, a mesma ideia e aplicada para as linhas da matriz IF6. A ultima linha e
capturada explicitamente antes da transicao para `INVERSE`, evitando perder a
contribuicao que ainda estava combinacional no ultimo ciclo Hadamard.

Motivo: guardar nove acumuladores e uma linha e mais barato do que guardar a
matriz inteira e recalcular a inversa sobre o banco completo.

### Passo 5 - Fixar os pontos de MAC e abrir as conexoes

Os arquivos especializados declaram todos os multiplicadores explicitamente.
Os pontos fixos sao:

| Arquivo | Transformacao | MACs | Ciclos Hadamard |
| --- | --- | ---: | ---: |
| `conv3x3stream-if/conv6mac.sv` | IF3x3 | 6 | 6 |
| `conv3x3stream-if/conv12mac.sv` | IF3x3 | 12 | 3 |
| `conv3x3stream-if/conv18mac.sv` | IF3x3 | 18 | 2 |
| `conv3x3stream-tc/conv5mac.sv` | TC3x3 | 5 | 5 |

Os `localparam` `FIXED_NUM_MULT` e `FIXED_STATE_MULT` deixam o ponto de
implementacao fixo. Os parametros homonimos que permanecem na porta do
modulo servem apenas para compatibilidade com o testbench compartilhado.

Motivo: a versao fixa torna o numero de multiplicadores visivel no RTL e
permite comparar diretamente area, registradores e ciclos de cada ponto, sem
uma flag `FIXED_CONV` ou selecao condicional no testbench.

### Passo 6 - Ajustar o consumo de linhas para cada fatoracao

- IF6 carrega uma linha de seis elementos por ciclo.
- IF12 carrega dois pacotes de seis elementos por ciclo e atualiza duas
  contribuicoes de inversa.
- IF18 carrega tres pacotes de seis elementos por ciclo e atualiza tres
  contribuicoes de inversa.
- TC5 carrega uma linha de cinco elementos por ciclo.

O banco de pesos e rotacionado pelo numero de produtos consumidos no ciclo.
Assim, cada multiplicador recebe o par feature/peso correspondente mesmo sem
`MuxMult` e sem materializar a matriz Hadamard completa em registradores.

Motivo: aumentar `NUM_MULT` deve reduzir o numero de ciclos Hadamard, mas nao
pode alterar a ordem matematica das linhas nem repetir um produto.

### Passo 7 - Proteger o tempo de vida da janela de entrada

Durante `TRANSFER`, a FSM de entrada normalmente desloca `r_input_feat` para
preparar a proxima janela. No streaming, `TRANSFORM` ainda esta capturando
`w_conv_transform` e precisa que a janela atual permaneca estavel.

Por isso, nos arquivos streaming, `INPUT_SHIFT_WE_BLOCK` bloqueia o deslocamento
quando `st_conv_current == TRANSFORM`. O deslocamento fica adiado ate
`w_conv_input_release`, depois da ultima linha Hadamard.

Motivo: sem esse congelamento, as primeiras linhas poderiam pertencer a uma
janela e as ultimas linhas a outra. O sintoma era uma falha que aparecia como
erro de inversa ou erro de escrita, embora as formulas da inversa estivessem
corretas.

### Passo 8 - Ajustar contadores e captura final

O contador da FSM de convolucao passou a representar o numero de grupos de
linhas consumidos por ciclo. A condicao de fim e diferente para cada ponto:

- 6 MACs: seis grupos de uma linha;
- 12 MACs: tres grupos de duas linhas;
- 18 MACs: dois grupos de tres linhas;
- TC5: cinco grupos de uma linha.

O resultado final e capturado a partir do acumulador que inclui o ultimo grupo
Hadamard. Essa captura ocorre antes de `WRITE_OUTPUT`, para que a FSM de saida
continue vendo exatamente nove elementos no mesmo formato da implementacao
convencional.

Motivo: uma transicao de estado acontece em uma borda de clock, enquanto a
ultima soma ainda e combinacional naquele ciclo. Usar o acumulador anterior
causaria uma saida incompleta ou repetiria a linha anterior.

### Passo 9 - Preservar o caminho de saida

O streaming reutiliza a mesma ideia de leitura, acumulacao entre canais,
geracao de endereco e escrita do tile 3x3. O valor produzido pela inversa
streaming entra em `r_output_write`; quando existem canais anteriores, o valor
antigo vem de `r_output_read` e os dois sao somados em
`p_output_data_write`.

Motivo: a reducao de registradores deve ficar restrita ao core de convolucao.
Alterar simultaneamente o contrato de memoria dificultaria a equivalencia e
misturaria dois problemas diferentes.

## 8. Relacao entre os blocos convencional e streaming

| Funcao | Convencional | Streaming |
| --- | --- | --- |
| Leitura de IFMAP/pesos | FSM de entrada e bancos `r_input_feat`/`r_input_weight` | Mantida, com congelamento durante `TRANSFORM`. |
| Transformacao B | `Transform` comb. gera a matriz completa | `Transform` comb. continua igual; apenas o consumo e fatiado. |
| Armazenamento intermediario | `r_conv_temp` com toda a matriz | `r_d_row` com uma ou mais linhas. |
| Hadamard | `MuxMult` + produtos inseridos em `r_conv_temp` | Multiplicadores fixos e produtos de linha/pacote. |
| Inversa A | `Inverse` sobre a matriz completa | `InverseRow` + `InverseRowAccumulate`. |
| Estado da inversa | Resultado completo em `w_conv_inverse` | `r_out_acc` e captura final do ultimo grupo. |
| Saida | FSM de leitura/escrita e acumulacao | Reutilizada com o mesmo protocolo. |
| Parametrizacao | `NUM_MULT`/`STATE_MULT` controlam o datapath | Cada arquivo fixa um ponto de MAC. |

Em termos de dependencias, a mudanca pode ser resumida assim:

```text
Conv convencional:
  Transform -> [r_conv_temp completo] -> Multip/MuxMult -> Inverse completa

Conv streaming:
  Transform -> [r_d_row] -> Multip fixos -> InverseRow -> acumulador -> saida
```

## 9. Verificacao funcional

Os quatro pontos implementados podem ser compilados e simulados com os
`Makefile`s locais:

```bash
make -C rtl/conv3x3stream-if run-conv6mac
make -C rtl/conv3x3stream-if run-conv12mac
make -C rtl/conv3x3stream-if run-conv18mac
make -C rtl/conv3x3stream-tc run-conv5mac
```

Cada testbench verifica as escritas contra o golden da mesma configuracao.
Com o dataset atual, os pontos fixos foram validados com 900 inversas e zero
erros de escrita:

| Variante | Ciclos ativos do core | Erros de escrita |
| --- | ---: | ---: |
| IF6 | 7200 | 0 |
| IF12 | 4500 | 0 |
| IF18 | 3600 | 0 |
| TC5 | 6300 | 0 |

O lint pode ser executado diretamente com Verilator. Warnings de largura em
enderecos e no multiplicador compartilhado nao impedem a elaboracao; erros de
compilacao ou divergencia do golden devem ser tratados antes de qualquer
medicao de PPA.

## 10. Limites atuais

- O caminho streaming documentado cobre os pontos fixos IF6, IF12, IF18 e
  TC5.
- O suporte a outros valores de `NUM_MULT` exige uma nova definicao do
  empacotamento de linhas, da rotacao de pesos e das condicoes de captura.
- A reducao de registradores nao deve ser avaliada separadamente da
  equivalencia funcional: primeiro o golden precisa fechar, depois devem ser
  medidos registradores, area, timing, potencia e ciclos de sistema.
- `rtl/conv3x3/conv.sv` continua sendo a referencia convencional e nao deve
  receber a logica especifica das variantes streaming.
