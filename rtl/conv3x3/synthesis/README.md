# ASIC synthesis results

Only executed ASIC campaigns belong in this directory. Results for the
parameterized source `rtl/conv3x3/archive/conv.sv` are grouped under `conv/`,
whose directory name matches the source basename. Its subdirectories identify the
executed configuration and retain the full logical, simulation, and power
artifacts.

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

Prepared configurations with no execution results are kept separately under
`rtl/conv3x3/asic_configs/`.
