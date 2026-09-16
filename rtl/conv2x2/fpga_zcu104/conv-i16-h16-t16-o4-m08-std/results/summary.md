# FPGA ZCU104 benchmark summary

## Reproducibility boundary

Target: `xczu7ev-ffvc1156-2-e`, reference Vivado 2023.2, top `Conv`, baseline 20-bit.
Vivado 2023.2 was executed on Paxos from the direct synchronized snapshot; local reports are a copy of those textual artifacts.
Fmax sweep bracket: `317.0000133140005`--`349.99998250000084` MHz; highest tested PASS is `317.0000133140005` MHz and lowest tested FAIL is `349.99998250000084` MHz.
Timing/resource values below are post-route estimates. A protocol-directed RTL-SAIF capture at 317 MHz is present locally and must be imported into the routed checkpoint before hybrid power is reported; the prior 245 ns reports and the superseded approximately 100 MHz capture are not final inputs. The intended result is hybrid SAIF/vectorless power, with vectorless estimation retained for uncovered nets. Timing-SAIF remains optional because XSim hit a Vivado 2023.2 LLVM assertion.

## RTL evidence

- seed/jobs: `1` / `1`
- latency: `23648` cycles
- job initiation interval: `N/A` (non-reentrant core; reset required between launches)
- sequential job rate: one complete job every `23648` cycles when reset-delimited; this is not a pipeline II
- tile initiation interval: `11` cycles across `2025` tile-end events
- canonical Verilator regression: PASS (2025 inverse tiles, 23675 cycles, 8100 writes, zero errors)

## Required final table

| Design | bits | target MHz | achieved MHz | timing | DSP | LUT | FF | latency cyc | II | GOPS eq. | dyn. W | total W | GOPS/W | pJ/op |
| --- | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Our Conv baseline @ 317 MHz | 20 | 317.0 | 317.0 | PASS | 8.0 | 2087.0 | 1266.0 | 23648 | N/A | 1.9544401217861977 | 0.251 | 0.844 | N/A | N/A |
| WinoGen F(4,3) PNmin | 8-16 | N/A | N/A | REFERENCE | 6 | 2441 | 3587 | N/A | N/A | 9.883 | N/A | N/A | N/A | N/A |
| WinoGen F(4,3) constrained | 8-16 | N/A | N/A | REFERENCE | 48 | 8267 | 11678 | N/A | N/A | 123.824 | N/A | N/A | N/A | N/A |
| WinoGen F(4,3) PNmax | 8-16 | N/A | N/A | REFERENCE | 144 | 17472 | 18476 | N/A | N/A | 371.472 | N/A | N/A | N/A | N/A |
| WinoGen F(6,3) PNmin | 8-16 | N/A | N/A | REFERENCE | 8 | 3757 | 5703 | N/A | N/A | 12.508 | N/A | N/A | N/A | N/A |
| WinoGen F(6,3) constrained | 8-16 | N/A | N/A | REFERENCE | 128 | 31899 | 25307 | N/A | N/A | 412.02 | N/A | N/A | N/A | N/A |
| WinoGen F(6,3) PNmax | 8-16 | N/A | N/A | REFERENCE | 256 | 41093 | 40238 | N/A | N/A | 835.812 | N/A | N/A | N/A | N/A |

## Power table

| Design | freq | method | process | Dynamic W | Static W | Total W | SAIF coverage |
| --- | ---: | --- | --- | ---: | ---: | ---: | ---: |
| our core | 317 MHz | vectorless | typical | 0.251 | 0.593 | 0.844 | N/A |
| our core | 317 MHz | hybrid RTL-SAIF/vectorless | typical | PENDING | PENDING | PENDING | pending reimport |
| our core | 317 MHz | vectorless | maximum | 0.251 | 0.814 | 1.065 | N/A |
| our core | 317 MHz | hybrid RTL-SAIF/vectorless | maximum | PENDING | PENDING | PENDING | pending reimport |

## Operation count, energy and throughput

- operation-count audit: `validated dense 2-D convolution`; the generator's 24,300-multiplication line omits input-channel accumulation
- equivalent operations per complete job: `145800`
- literal arithmetic operations per complete job: `143100`
- job time at 317 MHz: `74.59936908517349` us
- sequential complete-job equivalent throughput at 317 MHz: `1.9544401217861977` GOPS
- typical total energy/job from hybrid power: `PENDING hybrid reimport` uJ
- equivalent throughput: `1.9544401217861977` GOPS; efficiency: `PENDING hybrid reimport` GOPS/W; energy: `PENDING hybrid reimport` pJ/op
GOPS is derived from the validated dense operation count. Power-derived efficiency and energy remain pending until the complete-window SAIF is imported into the routed checkpoint.

WinoGen reference is 8--16 bit; this baseline is 20 bit. WinoGen Table 1 is an IP/core comparison. The reported WinoGen Table 2 system replicas are not compared directly with one core.

Power labels are estimates from Vivado post-route, never physical-board measurements.
