# ASIC synthesis results

Only executed ASIC campaigns belong in this directory. Results for the
parameterized source `rtl/conv3x3/archive/conv.sv` are grouped under `conv/`,
whose directory name matches the source basename. Its subdirectories identify the
executed configuration and retain the full logical, simulation, and power
artifacts.

The executed campaign here is `conv/ifn9-06mac/`. Its `list-file.txt` points
to the archived generic `rtl/conv3x3/archive/conv.sv`, configured for the IFN9
6-multiplier baseline; it is not a result for one of the newer streaming-column RTL files.

Prepared configurations with no execution results are kept separately under
`rtl/conv3x3/asic_configs/`.
