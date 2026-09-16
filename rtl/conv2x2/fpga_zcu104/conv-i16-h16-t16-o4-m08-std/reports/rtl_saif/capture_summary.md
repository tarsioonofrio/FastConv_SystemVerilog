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
| Transições do clock | `47297` (esperado aproximadamente `47297.0`) |
| Latência do job | `23648 ciclos` |
| Jobs | `1` |
| Tile ends | `2025` |
| Tile II | `11 ciclos` |
| VCD | não gerado |

A captura é dirigida pelo protocolo: começa quando `p_start` é observado e
termina quando o testbench registra `p_end` (`jobs_completed > 0`). O limite de `200000000 ps` existe
somente como timeout de segurança e não define a duração normal da captura.

O período nominal é o operating point de 317 MHz (`3.154574 ns`). O SAIF
deve ser importado no checkpoint correspondente somente depois de verificar
que os ciclos capturados estão próximos da latência esperada de `23648` ciclos.

## Auditoria automática

- duration_matches_capture: `PASS`
- cycles_match_duration: `PASS`
- p_start_observed: `PASS`
- p_end_observed: `PASS`
- output_write_activity: `PASS`
- reset_not_active: `PASS`
- input_data_activity: `PASS`
- clock_toggle_sanity: `PASS`

O Tcl `primary_input_activity.tcl` injeta somente reset, start e sinais de
entrada. O clock permanece sob controle do XDC e os sinais de saída ficam como
observação; o Tcl completo `primary_activity.tcl` é mantido apenas para
auditoria.
