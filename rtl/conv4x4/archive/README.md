# Archived 4x4 RTL and synthesis material

The active convolution RTL files at the root of `rtl/conv4x4/` are limited to:

- the three `conv-tcn16-...-trunc-frac6-column.sv` files;
- WPN16 i60/prefetch24 column RTLs with 8, 16, and 32 multipliers.

The standard TCN16 column RTL is archived directly in this directory. Earlier
TCN16 truncation variants are grouped under `tcn16/`; earlier WPN16
prefetch, pipeline, and operand-isolation variants are grouped under `wpn16/`.
The original parameterized controller remains `conv.sv` in this directory,
and the older TCN16 frac8 sources remain under `tcn16-frac8/`.

Synthesis configurations and all preserved run artifacts are under
[`synthesis/`](synthesis/). Moving material here does not imply that its
results are comparable to the currently selected RTL without checking the
source revision and run configuration recorded in each campaign.
