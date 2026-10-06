# ASIC synthesis results

All ASIC configurations and results live in this directory. Results for the
parameterized source `rtl/conv3x3/archive/conv.sv` are grouped under `conv/`,
whose directory name matches the source basename. Each campaign directory keeps
its configuration, scripts, and any generated logical, simulation, and power
artifacts together. A prepared directory without generated reports is not
evidence that the flow completed.

The executed campaigns under `conv/` use the archived generic
`rtl/conv3x3/archive/conv.sv`:

- `ifn9-06mac/`: the original IFN9 6-multiplier baseline.
- `asic-sweep-20261003-ifn9-m06/`, `asic-sweep-20261003-ifn9-m12/`,
  `asic-sweep-20261003-ifn9-m18/`, and `asic-sweep-20261003-tcn9-m05/`:
  the October 3 multiplier sweep. These are results for the archived generic
  source configured by the corresponding mux/parameter files, not results for
  the newer streaming-column RTL files.

The consolidated sweep directories retain the run configuration, Genus and
Xcelium logs, power evaluation, reports, and mapped gate-level netlist. Large
intermediate databases, work directories, and SDF files were not copied.
The sweep outputs came from source commit `3f716f82e608298562365a3c64d637fb8b182fb8`.
The original `rtl/conv3x3/conv.sv` and the current archived source have the same
SHA-256 (`310af7ac4fb15528dbcd3e048f994bb26d56e39796aeaa9c73baeb18ceb99de1`);
the copied `list-file.txt` uses the current archive path for future reruns.

Use `scripts/prepare_asic_sweep.py` to create missing sweep configurations
directly under this tree, and `scripts/run_asic_sweep.sh` to execute them. The
runner stores its campaign summary under `synthesis/campaigns/` by default and
copies each Xcelium console log to the corresponding configuration's
`sim/asic_sweep_<run-id>.log`, including failed runs.

## IFN9 stream-column power flow (2026-10-05)

The full ASIC flow (Genus synthesis, nominal-SDF Xcelium simulation, and Joules
power) has now been completed for the five IFN9 streaming-column configurations
that were missing results. The campaign table, methodology, run limitations,
source hashes, and links to the per-configuration evidence are in
[`campaigns/ifn9-stream-column-asic-power-20261005.md`](campaigns/ifn9-stream-column-asic-power-20261005.md).

The sixth active IFN9 configuration, `conv-ifn9-i40-h27-t36-o9-m18-stream12-prefetch15-rowconst6-trunc-column`, already had a complete flow; its evidence remains in that configuration's `FLOW_STATUS.md`.
