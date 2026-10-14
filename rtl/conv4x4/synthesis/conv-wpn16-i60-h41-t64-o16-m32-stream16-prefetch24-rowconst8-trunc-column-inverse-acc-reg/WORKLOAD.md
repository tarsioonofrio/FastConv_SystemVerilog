# ASIC logical synthesis configuration

RTL: `rtl/conv4x4/conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column-inverse-acc-reg.sv`.

This active configuration synthesizes the inverse-partial-register variant.
The RTL has no registered Hadamard-product bank; it registers the 16 inverse
partials and row index immediately before `InverseRowAccumulate`.

Top-level overrides: `NUM_MULT=32`, `NBITS=16`, `N_CHANNEL_IN=3`, and `N_CHANNEL_OUT=12`.

This directory is an isolated logical-synthesis configuration using the same
Genus constraints, libraries, and synthesis scripts as WPN16 m32 Cin=3/Cout=12.
The canonical 16-bit truncated Cin=3/Cout=12 dataset is included in the file
list; this directory is for logical synthesis and does not imply simulation or
power completion.
