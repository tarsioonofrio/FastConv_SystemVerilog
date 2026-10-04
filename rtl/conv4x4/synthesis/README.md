# ASIC synthesis results

Only executed ASIC campaigns belong in this directory. Results for the
parameterized source `rtl/conv4x4/conv.sv` are grouped under `conv/`, whose
directory name matches the source basename. Its subdirectories identify the
executed configuration and retain the full logical, simulation, and power
artifacts.

The executed campaign here is `conv/tcn16-18mac/`. Its `list-file.txt` points
to the generic `rtl/conv4x4/conv.sv`, configured for the TCN16 18-multiplier
baseline; it is not a result for one of the newer streaming-column RTL files.

Prepared configurations with no execution results are kept separately under
`rtl/conv4x4/asic_configs/`.
