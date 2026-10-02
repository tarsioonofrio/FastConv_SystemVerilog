# IFN9 m18 replica capacity - 16-bit OOC sweep

This report records the IFN9 design with 18 multiplier lanes per core, using
`NBITS=16`. The source revision is `ab5dee07d4b5247a6c20605cec2b04e9c40f5cc4`.
All runs used Vivado 2023.2, part `xczu7ev-ffvc1156-2-e`, a 317 MHz clock
(`3.154574 ns`), and the same OOC implementation flow:

```text
opt_design
place_design -directive Explore
phys_opt_design -directive Explore
route_design -directive Explore
```

## Result

The largest tested implementation with non-negative post-route WNS was 15
cores. It passed by only `+0.023 ns`; 16 cores failed by `-0.058 ns`. The
discrete refinement also showed non-monotonic results: 13 cores failed
(`-0.115 ns`), while 14 and 15 passed. Therefore, "15" is the largest verified
passing implementation in this sweep, not a guarantee that every lower core
count closes timing or that the result is robust across placement seeds.

| IFN9 m18 cores | CLB LUTs | CLB registers | DSP48E2 | BRAM tiles | WNS (ns) | 317 MHz |
| ---: | ---: | ---: | ---: | ---: | ---: | :--- |
| 1  | 5,721  | 1,841  | 18  | 0 | +0.049 | PASS |
| 2  | 11,508 | 3,794  | 36  | 0 | +0.104 | PASS |
| 4  | 22,920 | 7,604  | 72  | 0 | +0.047 | PASS |
| 6  | 34,314 | 11,798 | 108 | 0 | +0.058 | PASS |
| 8  | 45,955 | 15,192 | 144 | 0 | +0.101 | PASS |
| 10 | 57,310 | 19,002 | 180 | 0 | +0.082 | PASS |
| 12 | 68,861 | 22,219 | 216 | 0 | +0.010 | PASS |
| 13 | 74,462 | 23,933 | 234 | 0 | -0.115 | FAIL |
| 14 | 80,389 | 26,014 | 252 | 0 | +0.019 | PASS |
| 15 | 86,577 | 27,855 | 270 | 0 | +0.023 | PASS |
| 16 | 92,130 | 29,454 | 288 | 0 | -0.058 | FAIL |

The maximum verified count is limited by timing/routing, not aggregate resource
exhaustion. At 15 cores, the routed design uses 37.58% of the device's 230,400
CLB LUTs, 6.04% of its 460,800 CLB registers, and 15.63% of its 1,728 DSPs.
It uses no BRAM tiles.

## Scope and caveats

This is an OOC IP/fabric capacity result, not a complete board-level system
capacity result. Package I/O buffers are disabled; each core has an independent
logical memory boundary, and the wrapper shares clock, reset, and start. The
XDC constrains the clock only; input and output boundary delays are not modeled.
The reported timing therefore characterizes the implemented clocked paths
under this wrapper and flow.

The earlier IFN9 m06/WPN16 results in `results/23da4e19/` used 20-bit datapaths.
Do not compare their replica limits directly with this 16-bit m18 result as an
equal-width architectural comparison.

Each `ifn9_m18_<N>/` directory preserves the result and metadata, synthesis and
routed utilization, timing summary, critical paths, clock utilization, DRC,
Vivado log, and journal. `refine.log` preserves the additional N=13/14/15 run
sequence; `worktree_route_artifacts/` contains congestion diagnostics written
by Vivado outside the per-run directories.
