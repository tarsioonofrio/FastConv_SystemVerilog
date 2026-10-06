# ASIC power results: 4x4 i54 streaming-column (2026-10-05)

This campaign completes the ASIC power flow for the six i54/prefetch18
streaming-column RTLs: TCN16 with 6, 12, and 18 MACs, and WPN16 with 8, 16,
and 32 MACs. The RTL is from commit
`8f3b20a677e349bb72122a903b742a959dae3e76`, run on `paxos.inf.pucrs.br` in an
isolated checkout. Genus was 21.12-s068_1 and Xcelium was 23.03-s003. The
nominal clock constraint is 2.000 ns (500 MHz); power is Joules' TT, 0.90 V,
25 C estimate with PLE interconnect. These are tool estimates, not physical
measurements.

## Results

| Architecture | MACs | Cells | Cell area (um2) | Net area (um2) | Total area (um2) | Setup slack (ps) | Job cycles | Job time (us) | Dynamic (mW) | Leakage (mW) | Total (mW) | Dynamic energy (nJ/job) | Total energy (nJ/job) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| TCN16 | 6 | 58,116 | 64,935.612 | 25,381.071 | 90,316.683 | 232 | 7,691 | 15.382 | 7.63423 | 0.349532 | 7.98376 | 117.430 | 122.806 |
| TCN16 | 12 | 62,760 | 70,205.436 | 27,808.875 | 98,014.311 | 230 | 5,963 | 11.926 | 9.78551 | 0.373918 | 10.1594 | 116.702 | 121.161 |
| TCN16 | 18 | 70,567 | 78,934.590 | 32,082.720 | 111,017.310 | 214 | 5,387 | 10.774 | 10.84948 | 0.415885 | 11.2654 | 116.892 | 121.373 |
| WPN16 | 8 | 20,912 | 26,515.944 | 10,222.074 | 36,738.018 | 216 | 8,843 | 17.686 | 7.87445 | 0.111141 | 7.98559 | 139.268 | 141.233 |
| WPN16 | 16 | 27,805 | 34,271.874 | 13,801.189 | 48,073.063 | 225 | 6,539 | 13.078 | 10.78740 | 0.147140 | 10.9345 | 141.078 | 143.001 |
| WPN16 | 32 | 37,019 | 47,205.522 | 18,785.534 | 65,991.056 | 226 | 5,387 | 10.774 | 12.49027 | 0.209257 | 12.6995 | 134.570 | 136.824 |

Dynamic power is the sum of the report's internal and switching components;
total power is dynamic plus leakage. Energy is average power multiplied by the
accepted `p_start`-to-`p_end` execution interval (`mW * us = nJ`). The nominal
setup path is MET in all six reports. The listed slack is the report's
worst-path slack; the endpoint is `p_output_data_write` for every row. This is
the constrained path reported by the flow, not a claim that unconstrained
interface paths have been characterized.

## Functional and SDF validation

All six post-synthesis timing simulations completed with the stream-column
testbench reporting a pass and 8,100 valid output writes. The measured job
interval uses a 2.000 ns clock and is recorded in each configuration's
`sim/execution_time.txt`. SDF annotation completed with zero errors in all
cases. Xcelium did emit `SDFNET` warnings for `RECREM` timing checks that are
not present in the standard-cell models; the counts were 2,967, 3,533, 3,971,
2,615, 3,325, and 5,940 respectively in table order. These warnings are
retained in each `sim/sdf_log.log`, rather than hidden or treated as errors.

The first m6 attempt stopped before synthesis because the noninteractive shell
did not initialize the Modules environment. It was rerun after correcting the
environment, using the final commit above; the final Genus, Xcelium, and Joules
artifacts are the successful rerun. The two earlier startup errors remain in
that configuration's `flow.log` for provenance.

## RTL provenance

| Configuration | RTL SHA-256 |
|---|---|
| `conv-tcn16-i54-h15-t12-o16-m06-stream12-prefetch18-rowconst6-trunc-column` | `441bcaeaea0f41179a81c0373d6e94b493c1e31ff1eeee1a050a3420cb6bc806` |
| `conv-tcn16-i54-h21-t24-o16-m12-stream12-prefetch18-rowconst6-trunc-column` | `666acbafd90b145cc230e22d335696965f5c1c745b218b1e12ffb9dfdc1ba709` |
| `conv-tcn16-i54-h27-t36-o16-m18-stream12-prefetch18-rowconst6-trunc-column` | `4a9df3a0891412788a6435843839c1ab7b7213ea1d9d0bc23601d8e78150d7ea` |
| `conv-wpn16-i54-h17-t16-o16-m08-stream16-prefetch18-rowconst8-trunc-column` | `6340c2b1ac8ac5a028705b2b50e3994916cdba55c3c9e0c88e6f033e83ece669` |
| `conv-wpn16-i54-h25-t32-o16-m16-stream16-prefetch18-rowconst8-trunc-column` | `955040757807be70110eb0f3a2598f697e23058c90fc3ff721ec4210f75e8812` |
| `conv-wpn16-i54-h41-t64-o16-m32-stream16-prefetch18-rowconst8-trunc-column` | `1fbff1e39971359ad2d8cc4917b355e00372dea5e095d1cbb0f3ad63ac370da9` |

The configuration directories retain the Genus and Joules logs, timing/area
reports, mapped Verilog netlist, Xcelium console and SDF logs, and measured
execution-time records. Large SDF files, SHM databases, and simulator working
directories were not copied into the repository.
