# FPGA ZCU104 benchmark summary

## Reproducibility boundary

Target: `xczu7ev-ffvc1156-2-e`, reference Vivado 2023.2, top `Conv`, baseline 20-bit.
The local checkout has no Vivado binaries; the Paxos module catalog provides Vivado 2023.2. Execute the implementation there before filling post-route timing, Fmax, resource and power cells.
No timing PASS, measured power, or SAIF coverage is claimed.

## RTL evidence

- seed/jobs: `1` / `1`
- latency: `23648` cycles
- job-level II: `23648` cycles (one campaign per launch)
- tile initiation interval: `11` cycles across `2025` tile-end events
- canonical Verilator regression: PASS (2025 inverse tiles, 23675 cycles, 8100 writes, zero errors)

## Required final table

| Design | bits | target MHz | achieved MHz | timing | DSP | LUT | FF | latency cyc | II | GOPS eq. | dyn. W | total W | GOPS/W | pJ/op |
| --- | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Our Conv baseline @ 317 MHz | 20 | 317.0 | None | PENDING | None | None | None | 23648 | 23648 | None | None | None | None | None |
| WinoGen F(4,3) PNmin | 8-16 | None | None | REFERENCE | 6 | 2441 | 3587 | None | None | 9.883 | None | None | None | None |
| WinoGen F(4,3) constrained | 8-16 | None | None | REFERENCE | 48 | 8267 | 11678 | None | None | 123.824 | None | None | None | None |
| WinoGen F(4,3) PNmax | 8-16 | None | None | REFERENCE | 144 | 17472 | 18476 | None | None | 371.472 | None | None | None | None |
| WinoGen F(6,3) PNmin | 8-16 | None | None | REFERENCE | 8 | 3757 | 5703 | None | None | 12.508 | None | None | None | None |
| WinoGen F(6,3) constrained | 8-16 | None | None | REFERENCE | 128 | 31899 | 25307 | None | None | 412.02 | None | None | None | None |
| WinoGen F(6,3) PNmax | 8-16 | None | None | REFERENCE | 256 | 41093 | 40238 | None | None | 835.812 | None | None | None | None |

## Power table

| Design | freq | method | process | Dynamic W | Static W | Total W | SAIF coverage |
| --- | ---: | --- | --- | ---: | ---: | ---: | ---: |
| our core | 317 MHz | vectorless | typical | PENDING | PENDING | PENDING | N/A |
| our core | 317 MHz | SAIF post-route | typical | PENDING | PENDING | PENDING | PENDING |
| our core | 317 MHz | SAIF post-route | maximum | PENDING | PENDING | PENDING | PENDING |
| our core | Fmax | SAIF post-route | typical | PENDING | PENDING | PENDING | PENDING |

WinoGen reference is 8--16 bit; this baseline is 20 bit. WinoGen Table 1 is an IP/core comparison. The reported WinoGen Table 2 system replicas are not compared directly with one core.

Power labels are estimates from Vivado post-route, never physical-board measurements.
