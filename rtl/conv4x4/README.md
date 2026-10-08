# FastConv 4x4 TCN16 controller

This folder contains the F(4x4, 3x3) TCN16 Winograd controller. Its external
interface is intentionally the same as the 2x2 and 3x3 controllers: the DUT
reads the generated ROM through `p_input_*` and accumulates results through the
output RAM port `p_output_*`. The only architectural differences are the
6x6 input tile, 4x4 output tile, 36 Hadamard values, and two multiplier cycles.
Package width and fractional precision depend on the selected dataset; do not
assume that every current 4x4 configuration uses the historical 20-bit,
8-fractional-bit package.

## Active RTL set

The root directory keeps the selected variants only: TCN16 standard-column,
TCN16 `frac6` rowconst-column at 6/12/18 multipliers, TCN16 pretransformed
integer-weight column at 6/12/18 multipliers, and WPN16 i60/prefetch24 at
8/16/32 multipliers. The pretransformed variants use the no-fraction
`trunc-nbits20` dataset; their weights are already floor-truncated integers,
so carrying the earlier `frac6` scaling into these RTLs would be incorrect.
Other TCN16 and WPN16 variants are preserved under `archive/` alongside their
archived synthesis configurations and reports. The active ASIC configuration
list is documented in [`synthesis/README.md`](synthesis/README.md).

The testbench instantiates the same `Memory` models used by `conv3x3` and
`conv2x2`. It starts one complete convolution, checks the output address range,
expects one valid write for every output pixel and input-channel accumulation,
and compares the final output bank against `const_feat_out`. It also emits
`dump.vcd`.

Run the focused simulation and lint with:

```bash
make -C rtl/conv4x4 run
make -C rtl/conv4x4 lint
```

The same controller can be checked against the generated WPN16 configuration
(`M=8`, 64 multiplications) without changing the testbench:

```bash
make -C rtl/conv4x4 clean
make -C rtl/conv4x4 CONFIG=wpn16 NUM_MULT=64 run
make -C rtl/conv4x4 CONFIG=wpn16 NUM_MULT=64 lint
```

The WPN16 matrix file in `mult-matrices/wpn16/` uses the current
parameterized-array interface expected by `conv.sv`; the old packed-vector
file is no longer used by this flow.

The ModelSim/QuestaSim-compatible support files are also provided:

```bash
cd rtl/conv4x4
fish ./test.fish
```

`sim.tcl` compiles the TCN16 data package, parameter/multiplexer packages,
matrix transforms, CSA/multiplier support, the shared `Memory` model, the
controller and this testbench.
