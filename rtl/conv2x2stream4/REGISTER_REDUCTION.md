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

## 5. Alteracao 2: reduzir `r_d_row`

Esta alteracao foi aplicada primeiro em `conv4mac.sv` e depois em
`conv8mac.sv`. `r_d_row` era diferente de `r_s_row`: ele segurava a linha
transformada entre a captura no estado `TRANSFORM`/`HADAMARD` e o ciclo em que
os MACs a consomem.

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

- removida a declaracao e a inicializacao sequencial de `r_d_row` nos dois
  arquivos;
- removidas as atribuicoes de `w_conv_transform` para `r_d_row` nos estados
  `TRANSFORM` e `HADAMARD`;
- `w_conv_feature` agora usa diretamente os quatro indices da linha atual em
  `conv4mac`;
- `w_conv_feature[0..7]` usa os indices `r_stream_product_idx + offset` em
  `conv8mac`.

O acumulador, os pesos, os contadores e a ordem da inversa nao foram
alterados.

### Reducao obtida

Cada variante removeu outras 4 palavras de 20 bits, ou 80 bits. Somando a
Alteracao 1, cada arquivo fixo agora elimina 8 palavras (160 bits) em relacao
ao estado original; os dois arquivos juntos eliminam 16 palavras (320 bits).
Area, potencia e timing ainda precisam ser medidos com nova sintese.

### Evidencia

Os dois testes fixos continuam com os mesmos resultados da baseline:

```text
conv4mac: inverse_tiles=2025 cycles=29749 valid_writes=8100
          input_samples_clipped=0 invalid_output_beats=0
conv8mac: inverse_tiles=2025 cycles=25699 valid_writes=8100
          input_samples_clipped=0 invalid_output_beats=0
```

Nenhum erro de golden output foi observado. Os avisos adicionais de largura
nos indices constantes `2'd2` e `2'd3` nao alteram a elaboracao, mas devem ser
limpos em uma etapa posterior para manter o lint silencioso.

## 6. Alteracao 3 candidata: reduzir `r_out_acc`

Tambem nao foi aplicada. `r_out_acc` contem quatro valores que atravessam os
ciclos de Hadamard. Remover esse vetor exigiria uma acumulacao distribuida ou
um banco de linhas, o que pode trocar registradores por multiplexadores e
aumentar a logica combinacional. O objetivo e reduzir armazenamento total,
nao apenas o numero de declaracoes.

Aceite somente com comparacao bit a bit das quatro saidas para cada janela e
com relatorio de area/timing que mostre beneficio real.

## 7. Variante de 2 MACs

O Makefile possui o alvo generico `run` e o `conv.sv` parametrizado para
`NUM_MULT` em `{2,4,8}`. Os arquivos fixos `conv2mac.sv`, `conv4mac.sv` e
`conv8mac.sv` nao sao todos mantidos nesta arvore; a validacao de 2 MACs usa o
caminho generico com `-GNUM_MULT=2`.

Antes de declarar suporte validado a 2 MACs, deve-se:

1. confirmar que o Makefile usa a fonte local, nao `conv2x2stream12`;
2. executar `make NUM_MULT=2 run`;
3. comparar a mesma golden output usada nos casos 4 e 8;
4. atualizar as listas de sintese para apontarem para este diretorio.

Resultado observado nesta etapa:

```text
NUM_MULT=2: inverse_tiles=2025 cycles=37849 valid_writes=8100
             input_samples_clipped=0 invalid_output_beats=0
Core active cycles: 20250
```

Os caminhos genericos `NUM_MULT=4` e `NUM_MULT=8` tambem passaram com,
respectivamente, `cycles=29749`/`core=12150` e `cycles=25699`/`core=8100`.

O Makefile foi tornado reproduzivel apos `make clean`: cada alvo cria seu
diretorio `obj_dir` antes de chamar o Verilator. Sem isso, uma primeira
execucao em uma arvore limpa falhava apenas por ausencia do diretorio de
saida, antes de qualquer erro RTL.

Os logs de sintese existentes nao servem como prova desta etapa porque as
listas antigas apontam para `rtl/conv2x2stream12`.

## 8. Ordem de execucao recomendada

Cada item deve ser um commit separado ou uma unidade de trabalho facilmente
revertivel:

1. baseline atual: 4 e 8 MACs;
2. remover `r_s_row` e o `InverseRow` de trace (commit anterior);
3. repetir baseline e registrar ciclos/saidas;
4. remover `r_d_row` por selecao indexada (aplicado no working tree apos a
   prova temporal desta etapa);
5. medir sintese da alternativa aprovada;
6. somente entao estudar `r_out_acc` ou uma acumulacao dobrada;
7. validar `NUM_MULT=2` e corrigir as listas de sintese;
8. rodar simulacao anotada e power com netlist gerado a partir do commit
   correspondente.

Nenhuma alteracao deve ser promovida por area estimada em RTL. O resultado de
cada etapa precisa conter a mudanca, a razao, os testes e o que ainda nao foi
medido.

O comando `sdf_cmd.cmd` tambem precisa usar exatamente o nome produzido pelo
Genus (`Conv_...sdf`, respeitando maiusculas/minusculas). Se ele apontar para
`conv_...sdf`, o Xcelium pode continuar a simulacao sem anotacao e emitir
apenas um warning; isso nao e uma simulacao anotada valida.

## 9. Alteracao 4: tornar as tres configuracoes de sintese coerentes

### Motivacao

As tres variantes compartilham o mesmo fluxo Genus, mas a configuracao de
`NUM_MULT=2` e parametrizada enquanto `conv4mac.sv` e `conv8mac.sv` ja sao
modulos fixos. O arquivo `top-parameters.txt` usa a forma legivel
`NUM_MULT=2`; o comando `elaborate -parameters` do Genus, porem, exige uma
lista Tcl de pares `{nome valor}`. Se somente uma configuracao fizer essa
conversao, o resultado dependera da variante e a sintese podera falhar antes
de ler o RTL.

### Mudanca aplicada

Os parsers locais de `tcn4-02mac`, `tcn4-04mac` e `tcn4-08mac` agora:

- ignoram linhas vazias e comentarios;
- convertem `NAME=VALUE` em `{NAME VALUE}` antes de `elaborate`;
- preservam a possibilidade de uma linha ja estar no formato Tcl;
- resolvem as listas de HDL a partir do diretorio da configuracao ou da raiz
  do repositorio;
- leem o topo de `top-module.txt`, evitando o nome legado `system` quando o
  modulo real e `Conv`.

A mesma correcao de origem foi aplicada ao caminho do testbench e aos tres
`list-file.txt`. Nenhuma sintese e considerada atualizada apenas por essa
mudanca de script: a prova exige executar Genus depois que todas as alteracoes
de RTL forem finalizadas.

### Criterio de aceite

- validacao textual de que todos os caminhos das listas existem;
- `make NUM_MULT=2/4/8` continua passando no RTL;
- uma unica campanha final de Genus para as tres configuracoes, seguida de
  simulacao anotada e power usando os artefatos dessa mesma campanha.

## 10. Configuracao de sintese por variante

As tres configuracoes em `synthesis/tcn4-*mac` foram corrigidas para usar os
artefatos locais deste diretorio:

| Configuracao | Fonte do core | Parametro |
| --- | --- | --- |
| `tcn4-02mac` | `conv.sv` | `NUM_MULT=2` |
| `tcn4-04mac` | `conv4mac.sv` | fixo em 4 MACs |
| `tcn4-08mac` | `conv8mac.sv` | fixo em 8 MACs |

As listas anteriores apontavam para `rtl/conv2x2stream12`, de modo que os
logs/registros de sintese que ja estavam no diretorio nao comprovavam a
sintese do RTL desta pasta. Tambem foi corrigido o `testbench-file.txt` para o
testbench compartilhado local e o nome de topo para `Conv`, respeitando
maiusculas/minusculas do SystemVerilog.

Essa etapa corrige a origem dos arquivos, mas ainda nao e uma nova sintese.
Genus, simulacao anotada e power devem ser executados no Paxos a partir deste
commit; os resultados antigos devem ser substituidos e identificados pelo
commit do RTL usado.
