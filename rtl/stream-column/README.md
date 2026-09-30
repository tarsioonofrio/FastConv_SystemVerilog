# Convolução streaming `trunc-column` para outros tamanhos

Esta pasta contém o método usado para replicar, nos tamanhos 3x3 e 4x4, a linha
`trunc-column` do `conv2x2` (ver `../conv2x2/doc/history.md`, §13). O que muda
de um algoritmo para outro é gerado a partir do `build.json` dele; o controle é
comum.

| Arquivo | Função |
| ------- | ------ |
| `conv_stream_column_core.svtmpl` | Módulo `Conv` genérico (FSMs de entrada, convolução e saída, prefetch, pipeline). |
| `gen_stream_column.py` | Gera o RTL de um algoritmo: instancia o núcleo e escreve `WeightTransformRowConst`, `InverseRow` e `InverseRowAccumulate` a partir do `build.json`. |
| `testbench_stream_column.sv` | Testbench de colunas para qualquer tamanho, com o golden do pacote de dados. |

Os RTL gerados ficam na pasta do tamanho, com o algoritmo no nome:

| Algoritmo | Tile de entrada | Hadamard | Saída | MACs | Escala dos pesos | Arquivo |
| --------- | --------------: | -------: | ----: | ---: | ---------------: | ------- |
| `tcn9` | 5x5 | 5x5 | 3x3 | 5 | 36 | `../conv3x3/conv-tcn9-i40-h14-t10-o9-m05-stream10-prefetch15-rowconst5-trunc-column.sv` |
| `ifn9` | 5x5 | 6x6 | 3x3 | 6 | 1 | `../conv3x3/conv-ifn9-i40-h15-t12-o9-m06-stream12-prefetch15-rowconst6-trunc-column.sv` |
| `tcn16` | 6x6 | 6x6 | 4x4 | 6 | 576 | `../conv4x4/conv-tcn16-i60-h15-t12-o16-m06-stream12-prefetch24-rowconst6-trunc-column.sv` |
| `wpn16` | 6x6 | 8x8 | 4x4 | 8 | 4 | `../conv4x4/conv-wpn16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8-trunc-column.sv` |

O nome segue a convenção do 2x2: `i` são as palavras de entrada guardadas (banco
do tile mais banco de prefetch), `h` as de pesos (nove espaciais mais a linha
transformada), `t` as da fronteira de transformação (aqui, a linha de features mais
a de produtos registradas, 2*H, como no m04 do 2x2), `o` as de saída e `m` os MACs. O número de MACs é uma linha de
Hadamard por ciclo, ou seja, `HADAMARD_SIZE`.

## Como usar

Regerar um RTL (não editar os arquivos gerados à mão):

```bash
python3 stream-column/gen_stream_column.py <tamanho>/data/<algoritmo>/config/build.json \
        <algoritmo> <tamanho>/<arquivo>.sv
```

Simular (Verilator; a partir de `conv3x3/` ou `conv4x4/`):

```bash
make run-stream-column CONFIG=<algoritmo>     # constroi, roda e checa o golden
make lint-stream-column CONFIG=<algoritmo>
make clean-stream-column CONFIG=<algoritmo>   # apaga o obj_dir (AGENTS.md, 2.3)
```

O dataset é `data/<algoritmo>/sim/sim-032-3-3-normal-trunc/pack_data.sv` (pesos
truncados, com os nove pesos espaciais anexados). Ele é gerado pela biblioteca
`fast-convolution-rtl`:

```bash
python -m fast_convolution.cli -p <diretorio-com-config> sim normal --image-side 32 \
       -i 3 -o 3 -d 0 --truncated-weight-transform --no-c -n trunc
```

## O que muda em relação ao `conv2x2` m04

O controle parte do `conv-i24-h13-t08-o4-m04-...-trunc-column.sv`, generalizado
para `CONV_INPUT_SIZE = CONV_OUTPUT_SIZE + CONV_KERNEL_SIZE - 1` e
`HADAMARD_SIZE` independente:

- **Banco de features e prefetch.** O banco tem `IN*IN` palavras, indexadas por
  `lane*IN + beat`. Janelas consecutivas compartilham as duas colunas mais à
  direita (`KEEP_COLUMNS = K-1`) e buscam `NEW_COLUMNS = M` colunas novas. O
  prefetch guarda `M*IN` palavras. O atalho de deslocamento e o commit do
  prefetch são laços em vez de máscaras fixas de 16 bits.
- **Uma única fase `READ_IN`.** Os quatro estados `READ_IN_10A/10B/8C/8D` viraram
  um estado com um contador de beat. O estado `WAIT_PREFETCH` não era alcançável
  pelo fluxo de estados (conclusão da leitura do código, não de uma prova formal)
  e foi removido; os quatro casos passam sem ele.
- **Ponteiro de endereço.** `r_input_addr_feat` aponta sempre para a última
  coluna carregada. O `TRANSFER` avança uma coluna e o commit do prefetch avança
  as `M-1` restantes; o prefetch usa um endereço corrente em vez de
  `fase * FEAT_INPUT_WIDTH`, sem multiplicador.
- **Pesos por linha.** Há um `WeightTransformRowConst` por linha de Hadamard. O
  valor transformado é o piso da soma inteira dividida pela escala dos pesos:
  deslocamento aritmético quando a escala é potência de 2 e divisão por constante
  (com correção para piso, pois `/` do SystemVerilog trunca em direção a zero)
  quando não é. A síntese decide a implementação da divisão; a alternativa por
  recíproco em ponto fixo fica para um experimento posterior.
- **Inversa por linha.** `InverseRow` calcula uma linha de `M * A1` e
  `InverseRowAccumulate` soma `A0[linha][i]` vezes essa linha à linha `i` da saída.
- **Saída física.** A memória de saída é uma grade de janelas inteiras
  (`OUTPUT_PHYSICAL_SIZE = janelas * M`): 30 no 3x3 e 32 no 4x4. O canto de 30x30
  é o resultado lógico; as amostras além dele (4x4) são recortadas no testbench.

## Verificação

Todas as execuções abaixo são do Verilator, com o dataset `sim-032-3-3-normal-trunc`
(32x32, 3 canais de entrada e 3 de saída, seed 0, NBITS = 20, QUANT = 8), e o
testbench compara cada palavra escrita com o golden. Os quatro casos terminam com
zero divergências, 8.100 escritas válidas e o número esperado de tiles inversos
(900 no 3x3, 576 no 4x4). Depois de `p_end`, não há inversa terminal, novo acesso
às memórias nem FSM presa fora de `WAIT_*`. Os transcritos estão em `../conv3x3/report/` e
`../conv4x4/report/` (`stream-column-<algoritmo>-verilator.log`).

| Algoritmo | MACs | Ciclos até `p_end` (streaming) | Base `std`: MACs / ciclos | Variação de ciclos |
| --------- | ---: | ------------------------------: | ------------------------- | -----------------: |
| `ifn9` | 6 | 11.046 | 6 / 17.564 | -37,1% |
| `tcn9` | 5 | 10.146 | 5 / 17.464 | -41,9% |
| `tcn16` | 6 | 7.699 | 18 / 19.262 | -60,0% |
| `wpn16` | 8 | 8.851 | 64 / 19.274 | -54,1% |

Esses ciclos não comparam só o controle: a base `std` usa interface escalar e
os pesos já transformados na memória, e a nova usa interface de colunas e pesos
espaciais. As bases contam cerca de 20 ciclos de espera final que o número de
ciclos até `p_end` não inclui (diferença menor que 0,3%).

Teste de mutação: trocar o piso pela divisão que trunca em direção a zero no
`tcn9` gera divergências já na primeira janela (por exemplo `got=-1674
expected=-1613`), então o testbench de fato detecta erro numérico.

## Achados durante o trabalho

1. **O golden legado de 3x3 reproduzia um defeito do RTL antigo.** A biblioteca
   (`simulation.py`, commit `a538e58`, "align 3x3 simulation with legacy RTL")
   fazia `bg_quant[:, :, :3] = bg_quant[0, 0, :3]` para saída 3x3: os três
   primeiros coeficientes transformados ficavam com os do primeiro par de canais.
   Por isso o R² dos datasets `ifn9` e `tcn9` era negativo (-0,578 e -1,14) e o
   RTL `std` passava contra um golden que não é a convolução correta. O contrato
   de pesos espaciais (`--truncated-weight-transform` e `--exact-scaled`) não
   herda mais esse defeito; o R² dos datasets `trunc` passou a 0,99991 (`ifn9`)
   e 0,99862 (`tcn9`). Os datasets sem truncamento e as bases `std` do 3x3
   continuam com o comportamento legado.
2. **Precisão do `tcn16` com QUANT = 8.** O R² do dataset é 0,741 (contra 0,9998
   do `wpn16`), embora o golden coincida com o modelo de ponto fixo. Os pesos
   transformados ficam divididos por 576 e perdem bits fracionários. É uma
   propriedade do algoritmo com essa largura, não do RTL.
3. **Tile terminal (corrigido).** A FSM agora reconhece o limite depois da
   última combinação de canal de entrada/saída antes de avançar os contadores ou
   iniciar outra leitura. O testbench exige zero eventos inversos terminais,
   ausência de acessos às memórias após `p_end` e retorno das FSMs a `WAIT_*`.
4. **Reemissão do prefetch.** O gatilho do prefetch corrigido no commit
   `4184991c` do 2x2 (só emitir se estiver ocioso e sem `full`) já nasce
   corrigido aqui.
5. **Fluxo ModelSim do 3x3.** O testbench do 3x3 passou a importar
   `pack_mux_mult` e o `sim.tcl` não compilava o arquivo de mux. Habilitei
   `mux_mult_06.sv` no `sim.tcl`; a base `ifn9` roda de novo no ModelSim (900 tiles,
   17.564 ciclos, zero erros).

## Limitações

- Só há simulação RTL em Verilator, com um seed e `NBITS = 20`. Não há síntese
  lógica, Xcelium, Vivado nem potência para estes RTL, e a largura de 16 bits
  não foi testada.
- O testbench usa referências hierárquicas ao `Conv` (`w_input_read_weights`,
  `r_input_channel_counter_input` e outros), como o testbench do 2x2.
- O sinal de depuração novo `w_input_read_weights` ainda não está no `wave.do`.
- As alterações na biblioteca `fast-convolution-rtl` (divisão por piso para
  escala qualquer, `--nbits`, o gate do defeito legado e os testes
  `test_simulation_nbits.py` e `test_simulation_3x3_truncated.py`) estão no
  working tree daquele repositório e não foram commitadas.
