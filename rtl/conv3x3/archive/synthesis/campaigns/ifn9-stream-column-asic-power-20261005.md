# IFN9 stream-column: campanha ASIC de power — 2026-10-05

Esta campanha completa o fluxo ASIC das cinco configurações ativas IFN9 que
ainda não tinham resultados completos. O fluxo executado foi Genus → Xcelium
com netlist gate-level e SDF nominal → Joules. O sexto caso ativo, m18 com
`prefetch15`, já tinha fluxo completo e permanece documentado em sua
[`FLOW_STATUS.md`](../conv-ifn9-i40-h27-t36-o9-m18-stream12-prefetch15-rowconst6-trunc-column/FLOW_STATUS.md).

## Ambiente e protocolo

- Checkout usado na Paxos: commit `60f8542645d8a2458ca4f547fa29011bfb1746c6`.
- Host: `paxos.inf.pucrs.br`.
- Genus/Joules: `21.12-s068_1`; Xcelium: `23.03-s003`.
- SDC com período de clock de 2 ns (500 MHz); corner típico de power:
  0,90 V / 25 °C, interconnect PLE.
- Workload comum: 32×32, `Cin=3`, `Cout=3`, kernel 3×3, pacote truncado
  canônico `rtl/conv3x3/data/archive/ifn9/sim/sim-032-3-3-normal-trunc/pack_data.sv`.
- SHA-256 do pacote: `4823753ac6c6cd9d502aa8f0839629a427703e807ea75ba646d51f1a282e7dc9`.
- As cinco simulações gate-level concluíram com 8.100 escritas válidas,
  `input_clipped_beats=0`, `output_clipped_words=0` e aprovação do testbench.
  O intervalo de job é medido entre `p_start` aceito e `p_end`.
- A janela de Joules não é isolada ao job: `read_stimulus` começa em 0 ns e o
  relatório usa `PDB Frames: /stim#0/frame#0`, incluindo reset e startup. Os
  valores são estimativas médias do estímulo completo, não potência
  exclusivamente durante o job ativo nem medição física.
- O log registra leitura e anotação do SDF no escopo `tb_stream_column.dut`.
  Cada `sdf_log.log` contém 500 avisos `SDFNET` sobre timing checks ausentes
  nos modelos de biblioteca; portanto, o arquivo não demonstra cobertura total
  desses checks. O `xrun.log` também contém `FLFNOF`, apesar de em seguida
  registrar a leitura do SDF e a anotação no escopo. Não houve erro fatal e a
  simulação passou funcionalmente. Os avisos devem ser considerados ao
  interpretar os resultados; os logs completos foram preservados.

## Resultados

Dynamic é calculado como `internal + switching`; total inclui leakage. Área
total e slack vêm dos relatórios Genus. Slack abaixo é do view nominal
0,90 V / 25 °C, em ps.

| Configuração | MACs | Células | Área total (µm²) | Slack (ps) | Job (ciclos) | Dynamic (mW) | Leakage (mW) | Total (mW) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `i35-h15-t12-m06-prefetch10` | 6 | 14.072 | 23.779,881 | +224 | 11.038 | 5,50514 | 0,07300 | 5,57814 |
| `i35-h21-t24-m12-prefetch10` | 12 | 18.326 | 31.082,186 | +226 | 8.338 | 6,88116 | 0,09693 | 6,97809 |
| `i35-h27-t36-m18-prefetch10` | 18 | 25.751 | 42.621,588 | +231 | 7.438 | 8,54197 | 0,12912 | 8,67109 |
| `i40-h15-t12-m06-prefetch15` | 6 | 14.353 | 24.183,592 | +236 | 11.038 | 5,52377 | 0,07461 | 5,59838 |
| `i40-h21-t24-m12-prefetch15` | 12 | 18.410 | 31.202,674 | +227 | 8.338 | 6,90575 | 0,09804 | 7,00379 |

O sexto resultado já publicado (`i40-h27-t36-m18-prefetch15`) tem 24.561
células, área total de 40.849,800 µm², slack de +225 ps, 7.438 ciclos,
dynamic de 8,96885 mW e total de 9,09803 mW. Consulte o `FLOW_STATUS.md` da
configuração para a proveniência detalhada e a cobertura de anotação registrada
naquela campanha.

## Evidência por configuração

Cada diretório abaixo contém logs de Genus/Joules/Xcelium, `execution_time.txt`,
relatórios Genus e netlist gate-level textual. Bancos `.db` e SDF foram
mantidos localmente, mas seguem ignorados pelo Git por serem artefatos grandes.
Os logs SDF (`sim/sdf_log.log`) conservam os avisos descritos acima.

| RTL | SHA-256 do RTL | Área | Timing nominal | Simulação | SDF | Power |
| --- | --- | --- | --- | --- | --- | --- |
| [`conv-ifn9-i35-h15-t12-o9-m06-stream12-prefetch10-rowconst6-trunc-column.sv`](../../conv-ifn9-i35-h15-t12-o9-m06-stream12-prefetch10-rowconst6-trunc-column.sv) | `319cd8fe42ac8e13cf7e38bb146b092a64c5ab09097d94455ca7b33d0387b741` | [rpt](../conv-ifn9-i35-h15-t12-o9-m06-stream12-prefetch10-rowconst6-trunc-column/logical/results/reports/Conv_area.rpt) | [rpt](../conv-ifn9-i35-h15-t12-o9-m06-stream12-prefetch10-rowconst6-trunc-column/logical/results/reports/Conv_timing_setup_analysis_view_0p90v_25c_captyp_nominal.rpt) | [xrun](../conv-ifn9-i35-h15-t12-o9-m06-stream12-prefetch10-rowconst6-trunc-column/sim/xrun.log) | [SDF](../conv-ifn9-i35-h15-t12-o9-m06-stream12-prefetch10-rowconst6-trunc-column/sim/sdf_log.log) | [Joules](../conv-ifn9-i35-h15-t12-o9-m06-stream12-prefetch10-rowconst6-trunc-column/power/power_evaluation.txt) |
| [`conv-ifn9-i35-h21-t24-o9-m12-stream12-prefetch10-rowconst6-trunc-column.sv`](../../conv-ifn9-i35-h21-t24-o9-m12-stream12-prefetch10-rowconst6-trunc-column.sv) | `da4db39112368924c605d983536222b84906874c83eddeb0587c78261dfa247d` | [rpt](../conv-ifn9-i35-h21-t24-o9-m12-stream12-prefetch10-rowconst6-trunc-column/logical/results/reports/Conv_area.rpt) | [rpt](../conv-ifn9-i35-h21-t24-o9-m12-stream12-prefetch10-rowconst6-trunc-column/logical/results/reports/Conv_timing_setup_analysis_view_0p90v_25c_captyp_nominal.rpt) | [xrun](../conv-ifn9-i35-h21-t24-o9-m12-stream12-prefetch10-rowconst6-trunc-column/sim/xrun.log) | [SDF](../conv-ifn9-i35-h21-t24-o9-m12-stream12-prefetch10-rowconst6-trunc-column/sim/sdf_log.log) | [Joules](../conv-ifn9-i35-h21-t24-o9-m12-stream12-prefetch10-rowconst6-trunc-column/power/power_evaluation.txt) |
| [`conv-ifn9-i35-h27-t36-o9-m18-stream12-prefetch10-rowconst6-trunc-column.sv`](../../conv-ifn9-i35-h27-t36-o9-m18-stream12-prefetch10-rowconst6-trunc-column.sv) | `77abccda87957937cb7a85b1e8727df693fe13444da915a264cc6f765c1c0ddd` | [rpt](../conv-ifn9-i35-h27-t36-o9-m18-stream12-prefetch10-rowconst6-trunc-column/logical/results/reports/Conv_area.rpt) | [rpt](../conv-ifn9-i35-h27-t36-o9-m18-stream12-prefetch10-rowconst6-trunc-column/logical/results/reports/Conv_timing_setup_analysis_view_0p90v_25c_captyp_nominal.rpt) | [xrun](../conv-ifn9-i35-h27-t36-o9-m18-stream12-prefetch10-rowconst6-trunc-column/sim/xrun.log) | [SDF](../conv-ifn9-i35-h27-t36-o9-m18-stream12-prefetch10-rowconst6-trunc-column/sim/sdf_log.log) | [Joules](../conv-ifn9-i35-h27-t36-o9-m18-stream12-prefetch10-rowconst6-trunc-column/power/power_evaluation.txt) |
| [`conv-ifn9-i40-h15-t12-o9-m06-stream12-prefetch15-rowconst6-trunc-column.sv`](../../conv-ifn9-i40-h15-t12-o9-m06-stream12-prefetch15-rowconst6-trunc-column.sv) | `17cb6e0cfb5d7e4c51efecb55a41fd884120028438886d333b3781fabf95ae6a` | [rpt](../conv-ifn9-i40-h15-t12-o9-m06-stream12-prefetch15-rowconst6-trunc-column/logical/results/reports/Conv_area.rpt) | [rpt](../conv-ifn9-i40-h15-t12-o9-m06-stream12-prefetch15-rowconst6-trunc-column/logical/results/reports/Conv_timing_setup_analysis_view_0p90v_25c_captyp_nominal.rpt) | [xrun](../conv-ifn9-i40-h15-t12-o9-m06-stream12-prefetch15-rowconst6-trunc-column/sim/xrun.log) | [SDF](../conv-ifn9-i40-h15-t12-o9-m06-stream12-prefetch15-rowconst6-trunc-column/sim/sdf_log.log) | [Joules](../conv-ifn9-i40-h15-t12-o9-m06-stream12-prefetch15-rowconst6-trunc-column/power/power_evaluation.txt) |
| [`conv-ifn9-i40-h21-t24-o9-m12-stream12-prefetch15-rowconst6-trunc-column.sv`](../../conv-ifn9-i40-h21-t24-o9-m12-stream12-prefetch15-rowconst6-trunc-column.sv) | `90e08f58d7d9accd55be12cb23442450e0e46ab65f12e0965dd121901a15f081` | [rpt](../conv-ifn9-i40-h21-t24-o9-m12-stream12-prefetch15-rowconst6-trunc-column/logical/results/reports/Conv_area.rpt) | [rpt](../conv-ifn9-i40-h21-t24-o9-m12-stream12-prefetch15-rowconst6-trunc-column/logical/results/reports/Conv_timing_setup_analysis_view_0p90v_25c_captyp_nominal.rpt) | [xrun](../conv-ifn9-i40-h21-t24-o9-m12-stream12-prefetch15-rowconst6-trunc-column/sim/xrun.log) | [SDF](../conv-ifn9-i40-h21-t24-o9-m12-stream12-prefetch15-rowconst6-trunc-column/sim/sdf_log.log) | [Joules](../conv-ifn9-i40-h21-t24-o9-m12-stream12-prefetch15-rowconst6-trunc-column/power/power_evaluation.txt) |
