# FastConv 4x4 streaming (TCN16)

This directory contains the isolated row-streaming implementation of the
TCN16 `F(4x4, 3x3)` controller. The legacy baseline remains in
`rtl/conv4x4/` and is not modified by this variant.

The variant uses six multipliers to process one transformed row per Hadamard
cycle (`P = K1D = 6`). The six transformed rows are consumed
over six cycles and the inverse transform accumulates one row contribution at
a time. The core datapath therefore keeps 28 sample registers (`6` for the
current transform row, `6` for the current product row and `16` output
accumulator entries), instead of materializing the 36-entry transform-domain
bank. `conv4x4stream28` names this registered-word count; it is not a bit
count.

The input streamer freezes the feature-map tile between `TRANSFER` and the
last Hadamard row, then releases the deferred horizontal shift when the
streaming core has completed the tile. This protects the input tile lifetime
without changing the baseline controller.

Run the isolated checks with:

```bash
make -C rtl/conv4x4stream28 lint
make -C rtl/conv4x4stream28 run
```

The ModelSim/QuestaSim-compatible support files are also provided:

```bash
cd rtl/conv4x4stream28
fish ./test-streaming.fish
```

The ModelSim runner reuses the baseline TCN16 data and parameters, while
compiling the streaming controller and inverse-row matrix modules.

Validation status: Verilator lint and the standalone inverse-row equivalence
test pass. The inherited end-to-end golden check currently reports mismatches
for the unmodified `rtl/conv4x4` baseline as well, so that dataset/golden
contract remains a separate issue from the streaming datapath.
