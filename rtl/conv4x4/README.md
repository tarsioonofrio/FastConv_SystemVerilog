# FastConv 4x4 architectures

This folder contains the F(4x4, 3x3) TCN16 Winograd controller. Its external
interface is intentionally the same as the 2x2 and 3x3 controllers: the DUT
reads the generated ROM through `p_input_*` and accumulates results through the
output RAM port `p_output_*`. The only architectural differences are the
6x6 input tile, 4x4 output tile, 36 Hadamard values, and two multiplier cycles.
Package width and fractional precision depend on the selected dataset; do not
assume that every current 4x4 configuration uses the historical 20-bit,
8-fractional-bit package.

## Current top-level RTL candidates

Every `conv-<alg>16-...sv` at the root is a selectable top. All of them share the
streaming-column controller (`../stream-column/`), and the algorithm code names
the bilinear identity behind the datapath. Each algorithm's dataset folder
(`data/<alg>/`) holds the generator of its matrices (`make_custom_build.py`) and,
for the post-ISCAS ones, a README with its origin, the prediction registered
before synthesis and the measured result.

| Code | Identity (F(4,3) per row, 6×6 input tile) | Products per row | Origin and README |
|---|---|---:|---|
| `tcn16` | Toom-Cook, fractional transforms (weights scaled by 576) | 6 | ISCAS 2027 baseline (`TCff`, `TCpre`) |
| `wpn16` | Winograd polynomial, transforms add and shift | 8 | ISCAS 2027 (`WPff`) |
| `bsn16` | bit-shift-ternary: weights with factors 1, 1/2, 1/4; input and output in -1, 0, 1 | 7 | first 7-product identity (`winograd-identities`) |
| `bsc16` | bit-shift-ternary, lowest transform cost 458 | 7 | `data/bsc16/README.md` |
| `bsh16` | bit-shift-ternary chosen by the synthesis-calibrated cost | 7 | `data/bsh16/README.md` (also the `m25-2state` variant) |
| `bso16` | `bsn16` with term signs and order chosen for low activity | 7 | `data/bso16/README.md` |
| `trn16` | ternary: every coefficient in -1, 0, 1 | 8 | `data/trn16/README.md`; best area, energy and error among the subexpression versions |
| `tro16` | `trn16` with term signs and order chosen for low activity | 8 | `data/tro16/README.md` |
| `dcn16` | direct convolution written as a selection bilinear (transforms are wiring) | 12 | `data/dcn16/README.md`; reference for the sweeps |

Suffixes after the multiplier count `m<N>`:

| Suffix | Meaning |
|---|---|
| `rowconst<K>-trunc` / `-round` | weight transform computed on chip, row by row, truncated or rounded |
| `subexpression` | separable weight transform with shared hardware (`../stream-column/gen_subexpression.py`); `subexpressionmagic` divides by an exact reciprocal |
| `transformed` | weights transformed offline (`../stream-column/gen_pretransformed_column.py`) |
| `transformed-tapwise` | offline weights with 8-bit requantization per tap |
| `m25-2state` | `bsh16` with at most 2 multiplication states and one Hadamard row split between them (`data/bsh16/gen_m25.py`) |
| `inverse-acc-reg`, `transformed-rowstream` | WPN16 m32 experiments; `transformed-rowstream` never finished its flow |

The synthesis folder name adds the precision and the workload: `frac<F>-extra<E>`
(fractional and extra bits of the transformed weights), `nbits16`, and
`cin3-cout12` (the synthetic 3×32×32 workload of the paper) or
`cin16-cout16-l<LB>c<C>` (ResNet-18 layer L, block B, conv C with real activations,
16 of its channels; `l10c1` is `layer1.0.conv1`; `-s<side>` gives the input side in
the layer sweep). `-mult<N>` marks the throughput
sweep with 2× and 4× the multipliers. The completion of each flow is in
`report/flow-status.csv`, and the exact mapping from root-level RTL to synthesis
configs is printed by `make audit-layout`.

Retired RTL is under `archive/`. A config under `synthesis/` may deliberately
reference an archived source; `list-file.txt` and `rtl-top-file.txt` are the
authoritative provenance. This distinction matters because a config directory
can contain historical results even when its source is no longer a root-level
candidate.

## Legacy `conv.sv` flow

To simulate a current RTL, use `scripts/sim-config.sh conv4x4 <configuration>` from
the repository root (README, "Quick start"). The targets below still compile the
original `archive/conv.sv` controller and are kept for history.

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
