# ASIC synthesis results

Only executed ASIC campaigns belong in this directory. Results for the
parameterized source `rtl/conv4x4/archive/conv.sv` are grouped under `conv/`,
whose directory name matches the source basename. Its subdirectories identify the
executed configuration and retain the full logical, simulation, and power
artifacts.

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

Prepared configurations with no execution results are kept separately under
`rtl/conv4x4/asic_configs/`.
