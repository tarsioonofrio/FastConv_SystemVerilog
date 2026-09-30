# Vetores com índice variável em `trunc-column`

Registro de uma revisão feita em 30/09/2026 por leitura do código de
`../conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc-column.sv`. As
linhas citadas são desse arquivo; no m04
(`../conv-i24-h13-t08-o4-m04-stream08-prefetch8-rowconst4-trunc-column.sv`)
elas ficam deslocadas em cerca de seis linhas. Contexto do desenvolvimento em
`history.md`, §13.5 e §13.6.

A pergunta era se algum vetor é indexado por outro sinal, em especial por um
elemento de outro vetor, o que geraria muxes ou decodificadores encadeados.

**Resultado.** Nenhum vetor é indexado por um elemento de outro vetor. Todo
índice variável é um contador escalar registrado (1 a 4 bits) ou um valor
derivado do estado da FSM, somado a um `lane` constante do laço `for`. Os
índices `lane` e `d` dos laços, e os part-selects `p_input_data[lane*NBITS +:
NBITS]`, são constantes na elaboração e não geram mux.

| Vetor | Índice variável | Linha | Uso | Estrutura esperada |
| ----- | --------------- | ----: | --- | ------------------ |
| `w_input_feat_next` | `w_input_base_feat + lane*4` | 456 | escrita | decodificador de 2 bits, vindo do estado da FSM |
| `w_input_feat_en` | `w_input_base_feat + lane*4` | 500 | escrita | habilitação por decodificação de 2 bits |
| `r_input_prefetch` | `r_input_prefetch_phase*4 + lane` | 546 | escrita | fase de 1 bit escolhe um de dois grupos de 4 palavras |
| `r_weight_spatial` | `r_weight_row_count + lane` | 609 | escrita | contador só assume 0, 3 e 6: três grupos de 3 palavras |
| `r_output_read` | `r_output_read_count*2 + lane` | 973 | escrita | contador de 1 bit |
| `r_output_write` | `r_output_write_count*2 + lane` | 1044 | leitura | mux 2:1 por lane, direto na porta `p_output_data_write` |
| `r_output_read` | `r_output_write_count*2 + lane` | 1045 | leitura | mesmo mux 2:1, antes do somador de saída |

As multiplicações por 2 e por 4 nesses índices são deslocamentos, sem
multiplicador. O único caminho de leitura que chega a uma porta de saída é o
das linhas 1044-1045, e o seletor é `r_output_write_count`, um registrador de
1 bit; não há índice calculado a partir de dados.

**Diferença m04/m08.** `r_conv_multiply_count` e
`r_hadamard_product_row_idx_reg` entram apenas em `case` ou como entrada de
módulo, nunca como índice. O banco `r_transform_feature_reg` é recarregado de
`w_conv_transform` de forma diferente nas duas variantes: no m08 o acesso usa
o índice constante `FIXED_NUM_MULT + lane` (linha 730), sem mux. No m04 ele usa
`r_transform_product_idx`, um registrador de 4 bits que avança de quatro em
quatro, então cada lane tem um mux 4:1 sobre `w_conv_transform`. Esse mux só
existe no m04.

**Limite desta análise.** Ela vem da leitura do RTL. Não foi conferida no
netlist do Genus nem do Vivado, portanto a forma como cada acesso foi
efetivamente mapeado (LUTs, decodificadores, enables) não está registrada aqui.
