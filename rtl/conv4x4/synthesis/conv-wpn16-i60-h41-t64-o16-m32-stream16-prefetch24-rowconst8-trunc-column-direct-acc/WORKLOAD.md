# ASIC logical synthesis configuration

RTL: `rtl/conv4x4/conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column-direct-acc.sv`.

Top-level overrides: `NUM_MULT=32`, `NBITS=16`, `N_CHANNEL_IN=3`, and `N_CHANNEL_OUT=12`.

This directory is an isolated logical-synthesis configuration. Its Genus
constraints, libraries, and synthesis scripts are copied from the matching
WPN16 m32 Cin=3/Cout=12 configuration. It does not contain results from the
original row architecture.
