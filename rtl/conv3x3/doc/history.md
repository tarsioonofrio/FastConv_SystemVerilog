# Conv3x3: história da linha `stream-column`

Registro de 30/09/2026 da replicação, no 3x3, do experimento `trunc-column` do
`conv2x2` (ver `../../conv2x2/doc/history.md`, §13). O método e a tabela
comparativa estão em `../../stream-column/README.md`; este arquivo guarda o que é
específico do 3x3. Algoritmos: `ifn9` (tile 5x5, Hadamard 6x6, escala de pesos 1)
e `tcn9` (tile 5x5, Hadamard 5x5, escala 36).

## 1. Estado inicial

- O RTL de referência era `conv.sv`, no estilo `std`: interface escalar e todos os
  pesos transformados em registradores.
- O `Makefile` apontava para `control.sv`, que não existe mais, e não tinha as
  entradas de dados, matrizes e mux. Foi reescrito no molde do `conv4x4`
  (`CONFIG`, `DATASET`, `NUM_MULT`, `mkdir` do diretório de objetos).
- O `conv.sv` tem `HADAMARD_SIZE = 6` como padrão, mas o `pack_param` do `tcn9`
  usa 5 (tile 5x5, 25 produtos); o testbench sobrescreve o parâmetro.
- O testbench passou a importar `pack_mux_mult` para escolher `NUM_MULT` pelo
  arquivo de mux, e ganhou contadores de escritas e de ciclos. O `sim.tcl`
  (fluxo ModelSim) passou a compilar `mux-mult/ifn9/mux_mult_06.sv`; sem isso o
  testbench não compilava (`Could not find the package (pack_mux_mult)`).

## 2. Bases `std` reproduzíveis

| Algoritmo | `NUM_MULT` | Resultado | Ciclos | Tiles inversos |
| --------- | ---------: | --------- | -----: | -------------: |
| `ifn9` | 6 | PASS, zero erros | 17.564 | 900 |
| `tcn9` | 5 | PASS, zero erros | 17.464 | 900 |

`ifn9` foi confirmado também no ModelSim (`vsim -c -do sim.tcl`), com os mesmos
17.564 ciclos. Os transcritos das bases estão em `../report/baseline-*.log`. O
`NUM_MULT = 5` do `tcn9` coincide com uma linha de Hadamard (5x5) e é um dos
mux disponíveis para esse algoritmo (1, 5 e 25); o `ifn9` usa 6, o mux
usado pelo fluxo ModelSim.

Essas bases passam contra um golden que reproduz um defeito do RTL antigo (ver
§3); portanto o PASS delas não garante uma convolução correta.

## 3. Defeito no golden legado de 3x3

A biblioteca `fast-convolution-rtl` (commit `a538e58`) forçava, para saída 3x3,
os três primeiros coeficientes transformados de todos os pares de canais a serem
os do primeiro par. Por isso o R² dos datasets sem truncamento é negativo
(`ifn9` -0,578; `tcn9` -1,147). O contrato de pesos espaciais deixou de aplicar
esse ajuste. Os datasets `sim-032-3-3-normal-trunc` de `ifn9` e `tcn9` foram
regenerados e o R² passou a 0,99991 e 0,99862; em ambos o golden coincide
exatamente com um modelo de ponto fixo independente (108 de 108 amostras
conferidas). Os datasets sem truncamento mantêm o comportamento legado, que as
bases `std` ainda exigem.

## 4. Streaming `trunc-column`

Os RTL `conv-i40-h15-t12-o9-m06-ifn9-...` (6 MACs) e
`conv-i40-h14-t10-o9-m05-tcn9-...` (5 MACs) são gerados por
`../../stream-column/gen_stream_column.py`. Rodam com
`make run-stream-column CONFIG=<algoritmo>` e passam com zero divergências:

| Algoritmo | MACs | Ciclos até `p_end` | Variação contra a base `std` |
| --------- | ---: | -----------------: | ---------------------------: |
| `ifn9` | 6 | 11.046 | -37,1% |
| `tcn9` | 5 | 10.146 | -41,9% |

A saída 3x3 cobre o mapa de 30x30 com dez janelas por eixo, então não há
recorte de borda: 0 beats de entrada e 0 palavras de saída recortadas. O
`tcn9` usa divisão por constante (escala 36) com correção para piso; o
recíproco em ponto fixo ainda não foi testado. Não há síntese lógica nem FPGA
para estes RTL.
