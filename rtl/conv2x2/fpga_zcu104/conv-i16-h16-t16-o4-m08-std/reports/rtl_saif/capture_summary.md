# Captura RTL-SAIF a 317 MHz

| Campo | Valor |
| --- | --- |
| Frequência do clock | `317 MHz` |
| Período nominal do alvo | `3154.57 ps` |
| Período efetivo na simulação | `3154 ps` |
| Frequência efetiva na simulação | `317.058 MHz` |
| Início da captura | `44156 ps` |
| Fim da captura | `74631525 ps` |
| Duração da captura | `74587369 ps` |
| Duração no cabeçalho SAIF | `74587369 ps` |
| Ciclos capturados | `23648.500` |
| Latência do job | `23648 ciclos` |
| Jobs | `1` |
| Tile ends | `2025` |
| Tile II | `11 ciclos` |
| VCD | não gerado |

A captura é dirigida pelo protocolo: começa quando `p_start` é observado e
termina no primeiro `w_conv_end`/`p_end`. O limite de `200000000 ps` existe
somente como timeout de segurança e não define a duração normal da captura.

O período nominal é o operating point de 317 MHz (`3.154574 ns`). O SAIF
deve ser importado no checkpoint correspondente somente depois de verificar
que os ciclos capturados estão próximos da latência esperada de `23648` ciclos.
