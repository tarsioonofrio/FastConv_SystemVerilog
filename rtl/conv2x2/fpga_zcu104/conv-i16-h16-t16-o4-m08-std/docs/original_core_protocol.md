# Protocolo observado do core piloto

Este documento registra a interface observada no RTL congelado
`conv-i16-h16-t16-o4-m08-std.sv` e no testbench funcional antes da criação do
wrapper. Ele não altera nem redefine o protocolo do core.

## Interfaces e uso dos sinais

| Grupo | Sinais | Uso observado |
| --- | --- | --- |
| Controle | `clk`, `reset`, `p_start`, `p_end` | `p_start` é amostrado pela FSM de entrada. `p_end` é combinacional e fica ativo no último beat de escrita do último canal de saída. |
| Leitura compartilhada de entrada/pesos | `p_input_en`, `p_input_addr`, `p_input_data`, `p_input_valid` | Um único canal de leitura serve primeiro aos 16 pesos transformados e depois às features. Os dois tipos de leitura ocorrem em estados mutuamente exclusivos. Endereços de pesos começam em `N_CHANNEL_IN * FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH` (3072 no workload) e seguem em ordem; endereços de features percorrem os três mapas 32x32. |
| Leitura/escrita da memória de saída | `p_output_en`, `p_output_wr`, `p_output_addr`, `p_output_data_write`, `p_output_data_read`, `p_output_valid` | A FSM lê resultados anteriores em `READ_OUTPUT` e escreve acumuladores em `WRITE_OUTPUT`; não solicita leitura e escrita simultâneas. Cada pixel de saída é atualizado por read-modify-write entre canais de entrada. |

## Semântica temporal observada

- O modelo `Memory` usado pelo testbench tem leitura de dados combinacional:
  `data_out = data[address]` enquanto a porta está habilitada. `LATENCY=1`
  afeta `data_valid`, não registra `data_out`; depois do reset, `valid` fica
  alto durante o enable.
- O core consome o dado de entrada na borda de subida enquanto está em
  `READ_WEIGHTS` ou nos estados `READ_IN_*`. A captura de feature é condicionada
  por `p_input_valid`, mas os contadores de endereço/estado não esperam por
  `valid`. A captura de peso ocorre em cada ciclo `READ_WEIGHTS` sem condição
  `p_input_valid`. Portanto, a interface atual exige um dado correspondente ao
  endereço corrente em cada borda de subida; não há backpressure para leituras
  de entrada.
- O modelo da memória de saída também fornece `data_out` combinacional. Em
  `READ_OUTPUT`, o core captura `p_output_data_read` na borda de subida quando
  `p_output_valid` está alto e só então avança o contador de leitura. Em
  `WRITE_OUTPUT`, a memória externa captura `p_output_data_write` e
  `p_output_addr` na borda de subida quando `p_output_wr` está alto.
- `p_output_en` é ativo tanto durante leitura quanto durante escrita;
  `p_output_wr` distingue os beats de escrita. O testbench usa uma única
  memória de saída com leitura combinacional e escrita síncrona.
- O pacote canônico contém 3297 palavras em `const_data`: 3072 valores de
  feature seguidos por 144 pesos transformados. A memória de saída tem 2700
  endereços para `30 x 30 x 3`; os dados golden de saída são consultados
  separadamente pelo testbench.

## Consequência para o wrapper BRAM

Uma BRAM/XPM com leitura síncrona diretamente na mesma borda de subida não
preserva esse contrato: o dado registrado só fica disponível depois da borda
na qual o core o captura, e o core não pode pausar a leitura de pesos/features.
O protocolo permite uma memória lógica de uma porta por grupo (features,
pesos e output, separadamente), mas uma implementação em BRAM precisa de um
adaptador temporal explícito. A hipótese a avaliar é ler em fase oposta
(borda de descida) para apresentar o dado antes da próxima borda de subida do
core; isso conserva o número de ciclos do core, mas cria caminhos de meio
período que precisam fechar timing a 317 MHz.

Para saída, a BRAM precisa suportar uma porta de leitura e outra de escrita
com fases opostas, ou equivalente validado pela síntese. Não declarar a
solução aprovada até simulação RTL, inferência de BRAM, análise de timing e
simulação funcional pós-route confirmarem o comportamento.

## Referências locais

- `rtl/conv2x2/conv-i16-h16-t16-o4-m08-std.sv`: atribuições de endereço,
  captura de dados e FSMs.
- `rtl/mem/mem.sv`: modelo de memória usado pelo testbench.
- `rtl/conv2x2/testbench.sv` e
  `fpga_zcu104/conv-i16-h16-t16-o4-m08-std/tb/tb_power.sv`: estímulo e
  verificações funcionais do piloto.
