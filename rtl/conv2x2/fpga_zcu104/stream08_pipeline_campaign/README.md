# Stream08 registered-pipeline FPGA campaign

This campaign characterizes the five stream08 variants whose transform and
inverse datapath stages were recently separated by explicit registers. It uses
the ZCU104 (`xczu7ev-ffvc1156-2-e`), Vivado 2023.2, Xcelium 23.03, a common
317 MHz constraint, and the canonical `sim-032-3-3-normal` workload.

The unchanged scalar testbench and common Vivado/Xcelium Tcl are reused from
`../column_power_comparison/`. This campaign has its own manifests, reports,
and result collector so existing scalar/column results are not overwritten.
For every variant the runner performs implementation, post-route vectorless
power at typical/maximum corners, post-route functional simulation (no SDF),
golden checking, DUT/top SAIF capture, and P3F power at both corners.

The five original candidates are `rowconst4`, `wstream4`,
`prefetch4-rowconst4`, `prefetch4`, and `prefetch8-rowconst4`. The detailed
source list for each is in `manifests/`. All long runs must be launched in
`tmux` on Paxos. Do not reuse or overwrite reports from the scalar/column
campaign.

The four-MAC truncated column variant
`prefetch8-rowconst4-trunc-column-4mac` is an additional candidate with a
dedicated manifest and runner (`scripts/run_trunc_column_4mac.sh`). It uses the
same canonical truncated workload and column-I/O testbench as the eight-MAC
truncated column version, but synthesizes the four-MAC RTL. Its reports are
stored under a separate run directory and must not overwrite either column
campaign.

The final comparison includes utilization, post-route timing at 317 MHz,
functional result/cycle checks, SAIF mapping, P0/P3F power categories, and
active-job metrics. If WNS is negative, metrics computed at 317 MHz are
common-point estimates and must not be described as an achieved operating
point. Power remains a Vivado estimate, not a board measurement.
