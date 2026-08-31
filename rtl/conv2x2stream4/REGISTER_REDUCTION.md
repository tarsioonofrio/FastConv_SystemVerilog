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
| `conv4mac.sv` | 4 | 1 |
| `conv8mac.sv` | 8 | 2 |

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

Nos arquivos fixos `conv4mac.sv` e `conv8mac.sv`, `r_s_row` recebia
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

Para `conv8mac.sv`, o segundo caminho continua usando
`w_stream_product_row_2` e `inverse_row_acc_second`.

Esta remocao nao deve ser aplicada cegamente ao `conv.sv` generico. Na
variante `NUM_MULT=2`, o vetor `r_s_row` conserva a primeira metade dos
produtos enquanto a segunda metade e calculada no ciclo seguinte; nesse caso
ele e funcional e precisa de outra transformacao arquitetural.

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

## 5. Alteracao 2 candidata: reduzir `r_d_row`

Esta alteracao **ainda nao foi aplicada**. `r_d_row` e diferente de
`r_s_row`: ele segura a linha transformada entre a captura no estado
`TRANSFORM`/`HADAMARD` e o ciclo em que os MACs a consomem.

### Hipotese

Substituir a linha armazenada por selecao combinacional de
`w_conv_transform[r_stream_product_idx + offset]` pode eliminar quatro
palavras, mas somente se o valor selecionado permanecer estavel durante todo
o ciclo de multiplicacao e se a transicao de `r_stream_product_idx` nao mudar
os operandos antes da captura de `w_stream_acc_next`.

### Prova obrigatoria antes de editar

1. desenhar a tabela ciclo a ciclo para `NUM_MULT=4` e `NUM_MULT=8`;
2. confirmar a relacao entre `st_conv_current`, `r_stream_product_idx`,
   `r_conv_multiply_count` e `r_d_row`;
3. criar uma variante temporaria sem `r_d_row`;
4. comparar produto por produto e acumulador por acumulador contra a versao
   congelada;
5. somente depois rodar a regressao completa e, se disponivel, sintese.

O caso `NUM_MULT=8` e especialmente sensivel porque quatro operandos ainda
precisam permanecer registrados enquanto os outros quatro sao selecionados
diretamente da transformada.

## 6. Alteracao 3 candidata: reduzir `r_out_acc`

Tambem nao foi aplicada. `r_out_acc` contem quatro valores que atravessam os
ciclos de Hadamard. Remover esse vetor exigiria uma acumulacao distribuida ou
um banco de linhas, o que pode trocar registradores por multiplexadores e
aumentar a logica combinacional. O objetivo e reduzir armazenamento total,
nao apenas o numero de declaracoes.

Aceite somente com comparacao bit a bit das quatro saidas para cada janela e
com relatorio de area/timing que mostre beneficio real.

## 7. Variante de 2 MACs

O Makefile possui o alvo `run-conv2mac`, e o indice Git contem um `conv.sv`
generico parametrizado para `NUM_MULT` em `{2,4,8}`. No estado observado desta
execucao, `conv2mac.sv` nao existe fisicamente no diretorio e o `conv.sv`
generico estava ausente do working tree, embora estivesse no indice.

Antes de declarar suporte validado a 2 MACs, deve-se:

1. restaurar ou gerar o arquivo fonte de forma controlada;
2. confirmar que o Makefile usa a fonte local, nao `conv2x2stream12`;
3. executar `make NUM_MULT=2`;
4. comparar a mesma golden output usada nos casos 4 e 8;
5. atualizar as listas de sintese para apontarem para este diretorio.

Os logs de sintese existentes nao servem como prova desta etapa porque as
listas antigas apontam para `rtl/conv2x2stream12`.

## 8. Ordem de execucao recomendada

Cada item deve ser um commit separado ou uma unidade de trabalho facilmente
revertivel:

1. baseline atual: 4 e 8 MACs;
2. remover `r_s_row` e o `InverseRow` de trace (aplicado neste commit);
3. repetir baseline e registrar ciclos/saidas;
4. provar e testar a alternativa sem `r_d_row`;
5. medir sintese da alternativa aprovada;
6. somente entao estudar `r_out_acc` ou uma acumulacao dobrada;
7. validar `NUM_MULT=2` e corrigir as listas de sintese;
8. rodar simulacao anotada e power com netlist gerado a partir do commit
   correspondente.

Nenhuma alteracao deve ser promovida por area estimada em RTL. O resultado de
cada etapa precisa conter a mudanca, a razao, os testes e o que ainda nao foi
medido.
