# ASIC synthesis results

This directory contains the active synthesis configurations for the selected
4x4 RTL variants. The active WPN16 set is limited to the three i60/prefetch24
column RTLs at 8, 16, and 32 multipliers. For each RTL, both the original
20-bit run and the 16-bit run are retained; the `-nbits16` suffix identifies
the latter.

The active TCN16 set has three distinct 6/12/18-MAC families:

- `rowconst4-trunc-frac6-column`, evaluated with the matching
  `trunc-frac6-nbits20` package;
- `pretransformed-column`, evaluated with the no-fraction
  `trunc-nbits20` package.
- `pretransformed-frac6-column`, evaluated with the matching
  `trunc-frac6-nbits20` package.

In the no-fraction pretransformed family, transformed weights are stored as
signed 20-bit floor-truncated integers. The `frac6` families instead preserve
six fractional bits in their transformed-weight representation. Each ASIC
configuration directory uses the exact basename of its RTL. The standard-column
RTL is selected for future work but does not yet have a matching configuration.
Previous TCN16 synthesis campaigns, including older truncation variants and
legacy `conv.sv` configurations, remain under `../archive/synthesis/` and must
not be presented as results for either active family without matching
provenance.

Other archived campaigns in `../archive/synthesis/` include WPN16 i54/prefetch18,
the pipelined and operand-isolation experiments, and the legacy ASIC sweeps.
Nothing was deleted; reports and logs remain with their original configuration
directories.
