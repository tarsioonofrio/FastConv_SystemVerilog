# ASIC synthesis results

This directory contains the active synthesis configurations for the selected
4x4 RTL variants. The active WPN16 set is limited to the three i60/prefetch24
column RTLs at 8, 16, and 32 multipliers. For each RTL, both the original
20-bit run and the 16-bit run are retained; the `-nbits16` suffix identifies
the latter.

The active TCN16 synthesis set has one characterized 6/12/18-MAC family:

- `rowconst6-trunc-frac6-column`, evaluated with the matching
  `trunc-frac6-nbits20` package.

The standard-column RTLs now have logical-synthesis configurations:

- `conv-tcn16-std-column`: 18 MACs, Cin=3/Cout=12, NBITS=20, frac6 weights.
- `conv-wpn16-std-column`: 32 MACs, Cin=3/Cout=12, NBITS=16, integer weights.

These two directories currently define the Genus logical synthesis stage only;
they intentionally do not imply that gate-level simulation or power has been
validated for the standard-column testbenches. All pretransformed RTL variants
and their synthesis configurations are archived under `../archive/`; they are
not part of the active architecture set. Each active ASIC configuration
directory uses the exact basename of its RTL.
Previous TCN16 synthesis campaigns, including older truncation variants and
legacy `conv.sv` configurations, remain under `../archive/synthesis/` and must
not be presented as results for an active variant without matching provenance.

Other archived campaigns in `../archive/synthesis/` include WPN16 i54/prefetch18,
the pipelined and operand-isolation experiments, and the legacy ASIC sweeps.
Nothing was deleted; reports and logs remain with their original configuration
directories.
