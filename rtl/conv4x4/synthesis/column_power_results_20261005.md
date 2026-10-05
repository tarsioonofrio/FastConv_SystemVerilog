# 4x4 streaming column power results (2026-10-05)

This campaign completes the ASIC power flow for the remaining current 4x4
stream-column configurations with 6/12 TCN16 MACs and 8/16 WPN16 MACs. It
uses the canonical 32x32, Cin=3, Cout=3, 4x4-kernel workload and the same
stream-column testbench. Runs were performed on Paxos with Genus 21.12-s068_1
and Xcelium 23.03-s003. Synthesis/timing uses the existing 2.000 ns clock
constraint. Joules power is reported for TT, 0.90 V, 25 C, with PLE
interconnect. These are tool estimates, not physical measurements.

## Results

| Architecture | MACs | Cells | Cell area (um2) | Setup slack (ps) | Job cycles | Job time (us) | Dynamic (mW) | Leakage (mW) | Total (mW) | Dynamic energy (nJ/job) | Total energy (nJ/job) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| TCN16 | 6 | 58,608 | 65,592.450 | 231 | 7,691 | 15.382 | 7.58561 | 0.355691 | 7.94130 | 116.682 | 122.153 |
| TCN16 | 12 | 62,913 | 70,419.258 | 218 | 5,963 | 11.926 | 9.69153 | 0.374555 | 10.0661 | 115.581 | 120.048 |
| WPN16 | 8 | 21,165 | 26,858.160 | 232 | 8,843 | 17.686 | 7.74123 | 0.112691 | 7.85392 | 136.911 | 138.904 |
| WPN16 | 16 | 28,085 | 34,612.956 | 222 | 6,539 | 13.078 | 10.76924 | 0.148920 | 10.9182 | 140.840 | 142.788 |

Dynamic power is internal plus switching power. Leakage is the report's
subtotal leakage. Energy is calculated as average power multiplied by the
accepted `p_start`-to-`p_end` job duration; `mW * us = nJ`. The table's cell
area is Genus `Cell Area`; the reports also retain net area and total area.

All four setup reports are MET in the nominal TT view. The limiting reported
path is an output-delay path from `r_output_write_count_reg` to
`p_output_data_write`; the smallest slack is 218 ps for TCN16-M12. This is the
reported constrained path, not a claim that every unconstrained interface
path is characterized.

All four gate-level timing simulations completed with the stream-column
testbench passing, 8,100 valid output writes, and zero annotation errors.
Xcelium logs contain repeated `SDFNET` warnings for `RECREM` timing checks
that the cell models do not expose. The warnings are preserved in
`sim/sdf_log.log`; they are not hidden by the pass result. Full simulation and
power reports, execution-window records, and mapped structural netlists are
stored in each configuration's `sim/`, `power/`, and `logical/results/`
directories.

## Configuration folders

- `conv-tcn16-i60-h15-t12-o16-m06-stream12-prefetch24-rowconst6-trunc-column/`
- `conv-tcn16-i60-h21-t24-o16-m12-stream12-prefetch24-rowconst6-trunc-column/`
- `conv-wpn16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8-trunc-column/`
- `conv-wpn16-i60-h25-t32-o16-m16-stream16-prefetch24-rowconst8-trunc-column/`
