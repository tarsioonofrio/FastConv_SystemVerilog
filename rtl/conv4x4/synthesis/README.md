# ASIC synthesis results

This directory contains the active synthesis configurations for the selected
4x4 RTL variants. The active WPN16 set is limited to the three i60/prefetch24
column RTLs at 8, 16, and 32 multipliers. For each RTL, both the original
20-bit run and the 16-bit run are retained; the `-nbits16` suffix identifies
the latter.

The active TCN16 set includes the `frac6` column RTLs at 6, 12, and 18
multipliers, evaluated with the matching `frac6-nbits20` package. Their ASIC
configuration directories use the exact RTL basenames. The standard-column
RTL is selected for future work but does not yet have a matching configuration.
Previous TCN16 synthesis campaigns, including the older truncation variants
and legacy `conv.sv` configurations, remain under `../archive/synthesis/` and
must not be presented as results for the selected `frac6` RTL.

Other archived campaigns in `../archive/synthesis/` include WPN16 i54/prefetch18,
the pipelined and operand-isolation experiments, and the legacy ASIC sweeps.
Nothing was deleted; reports and logs remain with their original configuration
directories.
