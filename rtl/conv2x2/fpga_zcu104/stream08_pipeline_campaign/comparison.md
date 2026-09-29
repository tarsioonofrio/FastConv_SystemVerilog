# FPGA power results: registered-pipeline stream08 variants

ZCU104 / XCZU7EV, Vivado 2023.2, 317 MHz constraint, canonical 32x32, Cin=3, Cout=3, 3x3 workload.
Power is a Vivado estimate, not a physical board measurement. P0 is post-route vectorless; P3F is post-route functional Xcelium SAIF without SDF.
Rows with negative WNS did not close timing at 317 MHz; throughput/energy at the common target are not achieved operating-point results.
The XDC requested 3.154574 ns, which Vivado rounded to 3.155 ns at 1 ps resolution (316.957 MHz). `prefetch4` is the only timing PASS and has only 0.003 ns slack, so it has effectively no timing margin.
The reported WNS is for the clocked internal paths; no input/output delay model was supplied for the external ports, so this is not an interface timing certification.
The worst path in `rowconst4`, `wstream4`, `prefetch4-rowconst4`, and `prefetch8-rowconst4` runs from `r_weight_spatial` to `r_input_weight` through the combinational weight transform (16–17 logic levels). `prefetch4` instead has a 10-level path from `r_input_weight` through the multiply/inverse datapath to `r_inverse_partial_current`.

| Variant | DSP | LUT | FF | WNS ns | 317 MHz | Cycles | Active GOPS | P0 typ D/S/T W | P3F typ D/S/T W | P3F SAIF | P3F max D/S/T W |
|---|---:|---:|---:|---:|:---:|---:|---:|---:|---:|---:|---:|
| rowconst4 | 8 | 4,256 | 1,264 | -1.329 | FAIL | 25,628 | 1.803 | 0.209/0.593/0.802 | 0.276/0.593/0.869 | 9446/9446 (High) | 0.276/0.814/1.090 |
| wstream4 | 8 | 4,326 | 1,288 | -2.255 | FAIL | 25,628 | 1.803 | 0.223/0.593/0.816 | 0.274/0.593/0.867 | 9839/9839 (High) | 0.274/0.814/1.088 |
| prefetch4-rowconst4 | 8 | 4,376 | 1,326 | -1.721 | FAIL | 21,866 | 2.114 | 0.206/0.593/0.799 | 0.330/0.593/0.923 | 9702/9702 (High) | 0.330/0.815/1.145 |
| prefetch4 | 8 | 2,078 | 1,291 | 0.003 | PASS | 21,893 | 2.111 | 0.252/0.593/0.845 | 0.316/0.593/0.909 | 5432/5435 (High) | 0.316/0.815/1.131 |
| prefetch8-rowconst4 | 8 | 4,416 | 1,457 | -1.330 | FAIL | 23,747 | 1.946 | 0.220/0.593/0.813 | 0.311/0.593/0.904 | 9927/9927 (High) | 0.311/0.815/1.125 |

P3F typical category breakdown (W):

| Variant | Clock | CLB logic | Signals | DSP | BRAM | I/O |
|---|---:|---:|---:|---:|---:|---:|
| rowconst4 | 0.015 | 0.022 | 0.043 | 0.006 | 0.000 | 0.190 |
| wstream4 | 0.017 | 0.022 | 0.038 | 0.006 | 0.000 | 0.192 |
| prefetch4-rowconst4 | 0.017 | 0.029 | 0.050 | 0.007 | 0.000 | 0.228 |
| prefetch4 | 0.013 | 0.030 | 0.040 | 0.007 | 0.000 | 0.226 |
| prefetch8-rowconst4 | 0.018 | 0.028 | 0.047 | 0.006 | 0.000 | 0.211 |

Active-job energy and power-normalized throughput at the common 317 MHz point (estimates; not achieved operating metrics when WNS is negative):

| Variant | Dynamic energy/job (uJ) | Total energy/job (uJ) | Dynamic GOPS/W | Total GOPS/W |
|---|---:|---:|---:|---:|
| rowconst4 | 22.313 | 70.255 | 6.534 | 2.075 |
| wstream4 | 22.152 | 70.093 | 6.582 | 2.080 |
| prefetch4-rowconst4 | 22.763 | 63.667 | 6.405 | 2.290 |
| prefetch4 | 21.824 | 62.778 | 6.681 | 2.322 |
| prefetch8-rowconst4 | 23.298 | 67.720 | 6.258 | 2.153 |

Worst post-route max-delay path at the 317 MHz constraint:

| Variant | Source register | Destination register | Data path delay (ns) | Logic levels |
|---|---|---|---:|---:|
| rowconst4 | `r_weight_spatial_reg[8][3]_replica_2/C` | `r_input_weight_reg[2][7]/D` | 4.756 | 17 |
| wstream4 | `r_weight_spatial_reg[6][7]/C` | `r_input_weight_reg[2][11]/D` | 5.365 | 17 |
| prefetch4-rowconst4 | `r_weight_spatial_reg[5][1]/C` | `r_input_weight_reg[1][2]/D` | 4.820 | 16 |
| prefetch4 | `r_input_weight_reg[3][14]/C` | `r_inverse_partial_current_reg[1][15]/D` | 3.033 | 10 |
| prefetch8-rowconst4 | `r_weight_spatial_reg[2][1]/C` | `r_input_weight_reg[1][6]/D` | 4.724 | 17 |
