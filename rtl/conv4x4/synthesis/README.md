# ASIC synthesis results

All ASIC configurations and results live in this directory. Results for the
parameterized source `rtl/conv4x4/archive/conv.sv` are grouped under `conv/`,
whose directory name matches the source basename. Each campaign directory keeps
its configuration, scripts, and any generated logical, simulation, and power
artifacts together. A prepared directory without generated reports is not
evidence that the flow completed.

The `conv/asic-sweep-20261003-*` directories use the archived generic
`rtl/conv4x4/archive/conv.sv`: TCN16 at 6, 12, and 18 multipliers, and WPN16
at 8, 16, and 32 multipliers. Their mux and parameter files select each
configuration; these are not results for the dedicated streaming-column RTL.
The earlier `conv/tcn16-18mac/` flow is also retained as the original TCN16
18-multiplier baseline.

The streaming-column TCN16 m12 and m18 flows are separate and use their
matching active RTL files. Their result folders are named after those RTLs:
`conv-tcn16-i60-h21-t24-o16-m12-stream12-prefetch24-rowconst6-trunc-column/`
and
`conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-rowconst6-trunc-column/`.

The i54/prefetch18 streaming-column ASIC power campaign covers TCN16 m6/m12/m18
and WPN16 m8/m16/m32. Its results and conditions are summarized in
[`i54_column_power_results_20261005.md`](i54_column_power_results_20261005.md),
and each run's logs, mapped netlist, reports, timing simulation, and Joules
report are stored in the six configuration directories named after their RTLs.
The final runs used commit `8f3b20a677e349bb72122a903b742a959dae3e76`; the
m6 log also retains an earlier failed environment attempt before the successful
rerun at that commit.

The consolidated sweep directories retain the run configuration, Genus and
Xcelium logs, power evaluation, reports, and mapped gate-level netlist. Large
intermediate databases, work directories, and SDF files were not copied.
The generic sweep outputs came from source commit
`3f716f82e608298562365a3c64d637fb8b182fb8`; the original `rtl/conv4x4/conv.sv`
and current archived source have the same SHA-256
(`3f60b5337108e9e86ee3110aef2c405917d214076253ab78d4231e5863a80229`). The
copied `list-file.txt` files use the current archive path for future reruns.
The streaming-column m12/m18 outputs came from commit
`ab60ef63f9b71060e250520571d0af7dd1f69a59`; both recorded RTL source hashes
match the current files (`5a611bffb1c19f9b365903730b4623ba07ee11c1b3edc22fe7d099a4cf56ab60`
for m12, `e5308dffb489206c23a9e3c6ac8606c241ebe8b1d7f375bde8ba8eb0e1fe262b`
for m18).

To rerun the streaming-column TCN16 m12/m18 pair on Paxos, publish/check out
the intended commit and launch the runner from this directory inside `tmux`:

```bash
cd rtl/conv4x4/synthesis
tmux new-session -d -s tcn16_column_asic ./run_tcn16_column_asic.sh
```

Use `scripts/prepare_asic_sweep.py` to create missing sweep configurations
directly under this tree, and `scripts/run_asic_sweep.sh` to execute them. The
runner stores its campaign summary under `rtl/conv3x3/synthesis/campaigns/` by
default. Each Xcelium console log is also copied to its configuration's
`sim/asic_sweep_<run-id>.log`, including failed runs.
