# Replica capacity results — XCZU7EV OOC

This report summarizes the Vivado 2023.2 post-route capacity sweep for the
source commit `23da4e1918bcb0afd66d7502f2b9694beb6c4f06`. All implementations
target `xczu7ev-ffvc1156-2-e` with the common 317 MHz clock constraint
(`3.154574 ns`, reported by Vivado as `3.155 ns`). The flow is OOC synthesis,
`opt_design`, `place_design -directive Explore`,
`phys_opt_design -directive Explore`, and `route_design -directive Explore`.

## Result

Under this exact OOC setup, the largest tested implementations that close the
internal clocked timing constraint are:

| Core | Largest tested PASS | WNS | Next tested count | WNS | Result at 317 MHz |
| --- | ---: | ---: | ---: | ---: | --- |
| IFN9 m06 | **20 instances** | +0.023 ns | 21 | −0.127 ns | 20 passes; 21 fails |
| WPN16 m08 | **1 instance** | +0.011 ns | 2 | −0.139 ns | 1 passes; 2 fails |

These are the largest verified PASS counts in the tested sweep, not an
architecture-independent maximum for every possible floorplan or constraint
set. In particular, the passing margins are small and should not be treated as
robust implementation margin. IFN9×18 passes by only 0.003 ns, IFN9×20 by
0.023 ns, and WPN16×1 by 0.011 ns.

## All routed points

Resource columns are routed utilization counts from `utilization.rpt`. WNS is
the post-route worst negative slack for the constrained clock path. `PASS`
means WNS ≥ 0 at the common 317 MHz target.

| Core | Instances | CLB LUTs | CLB registers | DSP48E2 | BRAM tiles | WNS (ns) | Timing |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| IFN9 m06 | 1 | 4,761 | 1,885 | 6 | 0 | +0.121 | PASS |
| IFN9 m06 | 8 | 38,545 | 15,112 | 48 | 0 | +0.023 | PASS |
| IFN9 m06 | 16 | 76,958 | 30,224 | 96 | 0 | +0.021 | PASS |
| IFN9 m06 | 18 | 86,962 | 34,002 | 108 | 0 | +0.003 | PASS |
| IFN9 m06 | 20 | 96,538 | 37,780 | 120 | 0 | +0.023 | PASS |
| IFN9 m06 | 21 | 101,513 | 39,669 | 126 | 0 | −0.127 | FAIL |
| IFN9 m06 | 22 | 106,104 | 41,558 | 132 | 0 | −0.120 | FAIL |
| IFN9 m06 | 23 | 111,556 | 43,447 | 138 | 0 | −0.008 | FAIL |
| IFN9 m06 | 24 | 116,644 | 45,347 | 144 | 0 | −0.081 | FAIL |
| WPN16 m08 | 1 | 8,678 | 2,647 | 8 | 0 | +0.011 | PASS |
| WPN16 m08 | 2 | 17,243 | 5,294 | 16 | 0 | −0.139 | FAIL |
| WPN16 m08 | 3 | 25,990 | 7,945 | 24 | 0 | −0.176 | FAIL |
| WPN16 m08 | 4 | 34,207 | 10,596 | 32 | 0 | −0.152 | FAIL |

The timing response is not strictly monotonic with replica count: for example,
IFN9×23 is closer to timing closure than ×21 or ×22, but still fails. Each
count was implemented once using the same flow; the results therefore describe
these routed implementations, not a statistical guarantee over implementation
seeds.

## Interpretation and limits

The limiting factor in this sweep is timing/physical routing, not exhaustion of
the device's aggregate LUT, register, or DSP resources. IFN9×20 uses about
41.9% of the device's 230,400 CLB LUTs, 8.2% of its 460,800 CLB registers, and
6.94% of its 1,728 DSPs. WPN16×4—already failing timing—uses about 14.8% of
LUTs, 2.3% of registers, and 1.85% of DSPs. None of the tested designs uses
BRAM.

The replica wrappers give each core distinct logical input, output, and
feedback buses to prevent Vivado from merging identical replicas. Clock,
reset, and start are shared. OOC mode omits package I/O buffers and does not
model a board-level memory subsystem. The XDC defines a clock but has no
input/output delay constraints, so input-memory and output-interface timing
are not covered by this result. The timing reports show the limiting paths are
internal register-to-register paths; examples are in each run's
`critical_paths.rpt`.

Thus, the direct answer is **20 IFN9 m06 replicas** or **1 WPN16 m08 replica**
with non-negative post-route WNS at 317 MHz in this experiment. A full system
using realistic memory/interconnect, or a more conservative timing margin,
could support fewer. Lowering the clock, changing architecture/floorplanning,
or adding pipeline stages could change the result; none was part of this sweep.

Each run directory preserves the compact result, metadata, synthesis and routed
utilization, timing summary, critical paths, clock utilization, DRC, Vivado log,
and journal.
