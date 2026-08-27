# FastConv streaming - Fase 1

Implementacao conservadora com `P = K1D`, selecionavel por
`STREAMING_CONV`. O caminho legado permanece como baseline.

## Resultados funcionais

| variante | modo | inversas | ciclos de sistema | ciclos ativos do core | erros |
|---|---|---:|---:|---:|---:|
| TC2x2 / tcn4 | baseline `conv2x2` | 2025 | 23677 | 12150 | 0 |
| TC2x2 / tcn4 | `conv2x2stream12` | 2025 | 29749 | 12150 | 0 |
| IF3x3 / ifn9 | baseline `conv3x3` | 900 | 17564 | 7200 | 0 |
| IF3x3 / ifn9 | `conv3x3stream21` | 900 | 22059 | 7200 | 0 |

Os quatro numeros foram obtidos pelos wrappers oficiais `test.fish` e
`test-streaming.fish`, com ModelSim configurado por `modelsim-set-path`.
Tambem passaram os testes unitarios com 1000 vetores aleatorios para TC2x2,
IF3x3 normal e IF3x3 CSA, alem do caso dirigido TC2x2 do plano.

## Armazenamento sequencial do datapath

Palavras de 20 bits no estado transform-domain:

| variante | baseline (`r_conv_temp`) | streaming (`r_d_row + r_s_row + r_out_acc`) | delta |
|---|---:|---:|---:|
| TC2x2 | 16 | 12 | -4 palavras (-80 bits) |
| IF3x3 | 36 | 21 | -15 palavras (-300 bits) |

`r_input_feat`, `r_input_weight` e `r_output_write` permanecem iguais. No
modo streaming, o writer de `r_conv_temp` e a instancia `Inverse` completa sao
eliminados por `generate`; a confirmacao de FFs e area total depende da
sintese.

O core mantem a mesma quantidade de ciclos ativos e de multiplicacoes
Hadamard. O sistema fica aproximadamente 25,6% mais lento porque a politica
`STREAM_FREEZE` adia o shift da entrada ate o ultimo row do tile.

## PPA e fases posteriores

`genus` e `xrun` nao estao disponiveis no ambiente, portanto area, FFs
sintetizados, timing, potencia, energia e top-5 caminhos criticos nao foram
medidos. A generalizacao para `P` divisor de `K1D`, `PACKED_ROWS`, `P > K1D` e
partial prefetch permanece para a Fase 2.

O codigo das variantes fica em `rtl/conv2x2stream12/` e
`rtl/conv3x3stream21/`; as pastas baseline `rtl/conv2x2/` e `rtl/conv3x3/`
permanecem sem as alteracoes do streaming.
