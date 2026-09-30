# Conv4x4: história da linha `stream-column`

Registro de 30/09/2026 da replicação, no 4x4, do experimento `trunc-column` do
`conv2x2` (ver `../../conv2x2/doc/history.md`, §13). O método e a tabela
comparativa estão em `../../stream-column/README.md`; este arquivo guarda o que é
específico do 4x4. Algoritmos: `tcn16` (tile 6x6, Hadamard 6x6, escala de pesos
576) e `wpn16` (tile 6x6, Hadamard 8x8, escala 4).

## 1. Estado inicial

- O RTL de referência era `conv.sv`, no estilo `std`, com interface escalar. O
  `make run` falhava com `Can't write file: obj_dir/tcn16-18/Vtb__Syms__Slow.cpp`
  porque o Verilator não cria o diretório de objetos aninhado
  (`obj_dir/<CONFIG>-<NUM_MULT>`); o `Makefile` passou a criá-lo.
- Como o mapa de saída tem 30 amostras e a janela tem 4, o testbench usa uma saída
  física de 32x32 e recorta o excesso. As bases mostram 1.440 amostras de entrada
  recortadas e 1.116 beats de saída inválidos.

## 2. Bases `std` reproduzíveis

| Algoritmo | `NUM_MULT` | Resultado | Ciclos | Tiles inversos |
| --------- | ---------: | --------- | -----: | -------------: |
| `tcn16` | 18 | PASS | 19.262 | 576 |
| `wpn16` | 64 | PASS | 19.274 | 576 |

Os transcritos estão em `../report/baseline-*.log`.

## 3. Datasets truncados

Os datasets `sim-032-3-3-normal-trunc` de `tcn16` (escala 576) e `wpn16` (escala
4) foram regenerados pela biblioteca atual e coincidem byte a byte com os já
existentes (`d.txt`, `g.txt`, `s.txt`). O golden coincide exatamente com um
modelo de ponto fixo independente (192 de 192 amostras conferidas) para os dois.

A escala 576 do `tcn16` não é potência de 2; a biblioteca passou a aceitar essas
escalas com divisão por piso. O R² do `tcn16` truncado é 0,741 e o do `wpn16`,
0,9998: com QUANT = 8, os pesos do `tcn16` divididos por 576 perdem precisão.
Isso é uma propriedade do algoritmo com essa largura, não um defeito do RTL.

## 4. Streaming `trunc-column`

Os RTL `conv-i60-h15-t12-o16-m06-tcn16-...` (6 MACs) e
`conv-i60-h17-t16-o16-m08-wpn16-...` (8 MACs) são gerados por
`../../stream-column/gen_stream_column.py`. Rodam com
`make run-stream-column CONFIG=<algoritmo>` e passam com zero divergências:

| Algoritmo | MACs | Ciclos até `p_end` | Variação contra a base `std` | Beats de entrada recortados | Palavras de saída recortadas |
| --------- | ---: | -----------------: | ---------------------------: | --------------------------: | ---------------------------: |
| `tcn16` | 6 | 7.699 | -60,0% | 432 | 1.116 |
| `wpn16` | 8 | 8.851 | -54,1% | 432 | 1.116 |

Aqui as bases usam 18 e 64 MACs e a nova versão, 6 e 8, com menos ciclos por causa
da interface de colunas; a comparação mistura interface e número de MACs. O
`tcn16` usa divisão por constante (escala 576) com correção para piso; o
recíproco em ponto fixo ainda não foi testado. Não há síntese lógica nem FPGA
para estes RTL.
