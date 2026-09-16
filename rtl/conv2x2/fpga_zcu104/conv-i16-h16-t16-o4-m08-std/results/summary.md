# FPGA ZCU104 benchmark summary

## Reproducibility boundary

Target: `xczu7ev-ffvc1156-2-e`, reference Vivado 2023.2, top `Conv`, baseline 20-bit.
Vivado 2023.2 was executed on Paxos from the direct synchronized snapshot; local reports are a copy of those textual artifacts.
Fmax sweep bracket: `346.8965879860756`--`347.17643881154345` MHz; highest tested PASS is `346.8965879860756` MHz and lowest tested FAIL is `347.17643881154345` MHz.
Timing/resource values below are post-route estimates. The complete protocol-directed RTL-SAIF capture at 317 MHz was imported into the routed checkpoint on Paxos; P1 is hybrid SAIF/vectorless and P2 is the input/control cross-check. The prior 245 ns reports and the superseded approximately 100 MHz capture are not final inputs. Timing-SAIF remains optional because XSim hit a Vivado 2023.2 LLVM assertion.

## RTL evidence

- seed/jobs: `1` / `1`
- latency: `23648` cycles
- job initiation interval: `N/A` (non-reentrant core; reset required between launches)
- sequential job rate: one complete job every `23648` cycles when reset-delimited; this is not a pipeline II
- tile initiation interval: `11` cycles across `2025` tile-end events
- canonical Verilator regression: PASS (2025 inverse tiles, 23675 cycles, 8100 writes, zero errors)

## Required final table

| Design | bits | target MHz | achieved MHz | timing | DSP | LUT | FF | latency cyc | II | GOPS eq. | dyn. W | total W | GOPS/W | dyn. GOPS/W | pJ/op | dyn. pJ/op |
| --- | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Our Conv baseline @ 317 MHz | 20 | 317.0 | 317.0 | PASS | 8.0 | 2087.0 | 1266.0 | 23648 | N/A | 1.9544401217861977 | 0.21 | 0.803 | 2.433922941203235 | 9.306857722791419 | 410.8593509972176 | 107.44765094572314 |
| WinoGen F(4,3) PNmin | 8-16 | N/A | N/A | REFERENCE | 6 | 2441 | 3587 | N/A | N/A | 9.883 | N/A | N/A | N/A | N/A | N/A | N/A |
| WinoGen F(4,3) constrained | 8-16 | N/A | N/A | REFERENCE | 48 | 8267 | 11678 | N/A | N/A | 123.824 | N/A | N/A | N/A | N/A | N/A | N/A |
| WinoGen F(4,3) PNmax | 8-16 | N/A | N/A | REFERENCE | 144 | 17472 | 18476 | N/A | N/A | 371.472 | N/A | N/A | N/A | N/A | N/A | N/A |
| WinoGen F(6,3) PNmin | 8-16 | N/A | N/A | REFERENCE | 8 | 3757 | 5703 | N/A | N/A | 12.508 | N/A | N/A | N/A | N/A | N/A | N/A |
| WinoGen F(6,3) constrained | 8-16 | N/A | N/A | REFERENCE | 128 | 31899 | 25307 | N/A | N/A | 412.02 | N/A | N/A | N/A | N/A | N/A | N/A |
| WinoGen F(6,3) PNmax | 8-16 | N/A | N/A | REFERENCE | 256 | 41093 | 40238 | N/A | N/A | 835.812 | N/A | N/A | N/A | N/A | N/A | N/A |
| WinoGen F(4,1) PNmin, F(2,3)* | 8-16 | N/A | N/A | REFERENCE | 4 | 1689 | 2191 | N/A | N/A | 5.559 | N/A | N/A | N/A | N/A | N/A | N/A |
| WinoGen F(4,1) constrained, F(2,3)* | 8-16 | N/A | N/A | REFERENCE | 16 | 2267 | 2901 | N/A | N/A | 22.236 | N/A | N/A | N/A | N/A | N/A | N/A |
| WinoGen F(4,1) PNmax, F(2,3)* | 8-16 | N/A | N/A | REFERENCE | 64 | 4858 | 7579 | N/A | N/A | 92.868 | N/A | N/A | N/A | N/A | N/A | N/A |

## Power table

| Design | freq | method | process | Dynamic W | Static W | Total W | SAIF coverage |
| --- | ---: | --- | --- | ---: | ---: | ---: | ---: |
| our core | 317 MHz | vectorless | typical | 0.251 | 0.593 | 0.844 | N/A |
| our core | 317 MHz | hybrid RTL-SAIF/vectorless | typical | 0.21 | 0.593 | 0.803 | 104/5442 (1.91%) |
| our core | 317 MHz | vectorless | maximum | 0.251 | 0.814 | 1.065 | N/A |
| our core | 317 MHz | hybrid RTL-SAIF/vectorless | maximum | 0.21 | 0.813 | 1.023 | 104/5442 (1.91%) |
| our core | 317 MHz | input/control activity + vectorless | typical | 0.211 | 0.593 | 0.804 | 40 injected inputs/controls |
| our core | 317 MHz | input/control activity + vectorless | maximum | 0.211 | 0.813 | 1.024 | 40 injected inputs/controls |

## Operation count, energy and throughput

- operation-count audit: `validated dense 2-D convolution`; the generator's 24,300-multiplication line omits input-channel accumulation
- equivalent operations per complete job: `145800`
- literal arithmetic operations per complete job: `143100`
- job time at 317 MHz: `74.59936908517349` us
- active-job equivalent compute throughput at 317 MHz: `1.9544401217861977` GOPS
- typical total energy/job from P1 hybrid power: `59.90329337539432` uJ
- equivalent throughput: `1.9544401217861977` GOPS; P1 total efficiency: `2.433922941203235` GOPS/W; P1 dynamic efficiency: `9.306857722791419` GOPS/W
- P1 total energy: `410.8593509972176` pJ/op; P1 dynamic energy: `107.44765094572314` pJ/op
GOPS uses the validated dense operation count. Energy is calculated with the 23648-cycle job time at exactly 317 MHz; P1 is the principal hybrid estimate and P2 is the input/control cross-check.

## P0/P1/P2 energy comparison

| Method | Corner | Dynamic W | Static W | Total W | Dynamic uJ/job | Total uJ/job | GOPS/W | pJ/equivalent-op |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| P0 vectorless | typical | 0.251 | 0.593 | 0.844 | 18.724441640378547 | 62.96186750788643 | 2.315687348087912 | 431.83722570566823 |
| P0 vectorless | maximum | 0.251 | 0.814 | 1.065 | 18.724441640378547 | 79.44832807570978 | 1.8351550439307023 | 544.9130869390245 |
| P1 RTL-SAIF hybrid | typical | 0.21 | 0.593 | 0.803 | 15.665867507886436 | 59.90329337539432 | 2.433922941203235 | 410.8593509972175 |
| P1 RTL-SAIF hybrid | maximum | 0.21 | 0.813 | 1.023 | 15.665867507886436 | 76.31515457413248 | 1.910498652772432 | 523.4235567498798 |
| P2 input/control activity | typical | 0.211 | 0.593 | 0.804 | 15.740466876971608 | 59.9778927444795 | 2.43089567386343 | 411.37100647791146 |
| P2 input/control activity | maximum | 0.211 | 0.813 | 1.024 | 15.740466876971608 | 76.38975394321766 | 1.9086329314318338 | 523.9352122305738 |

## Direct WinoGen F(2,3) reference

The TC2x2 core executes F(2,3). The closest WinoGen Table 1 IP is F(4,1) in supported mode F(2,3)*; its throughput model is based on expected cycles over input tiles, whereas this benchmark uses a complete validated RTL workload.

| WinoGen IP | bits | DSP | LUT | FF | equivalent GOPS |
| --- | ---: | ---: | ---: | ---: | ---: |
| WinoGen F(4,1) PNmin, F(2,3)* | 8-16 | 4 | 1689 | 2191 | 5.559 |
| WinoGen F(4,1) constrained, F(2,3)* | 8-16 | 16 | 2267 | 2901 | 22.236 |
| WinoGen F(4,1) PNmax, F(2,3)* | 8-16 | 64 | 4858 | 7579 | 92.868 |

WinoGen is 8--16 bit while this baseline is 20 bit. The WinoGen system replicas are not compared directly with this single core; a future replication sweep is the appropriate utilization-matched comparison.

Power labels are estimates from Vivado post-route, never physical-board measurements.
