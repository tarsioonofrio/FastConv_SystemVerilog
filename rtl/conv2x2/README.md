# FastConv 2x2 architectures

All 2x2 Winograd implementations now live in this directory. They share the
same external `Conv` interface and the same generated dataset, but each source
file is compiled separately because every file declares the top-level module
`Conv`.

## RTL variants

| Source | Architecture | MAC configurations |
| --- | --- | --- |
| `conv-std-i16-p32-o4-m4.sv` | Conventional transform / Hadamard / full inverse path | Parameterized (`NUM_MULT`, default 4) |
| `conv-all-i16-p16-o4-m16.sv` | Fully parallel path, all 16 Hadamard products in one cycle | Fixed 16 MACs |
| `conv-stream4-i16-p16-o4-m4.sv` | Four-MAC streaming path using the 4-word register-reduction schedule | Fixed 4 MACs |
| `conv-stream4-i16-p16-o4-m8.sv` | Eight-MAC streaming path using the 4-word schedule | Fixed 8 MACs |
| `conv-stream12-generic-i16-p24-o4-m2-4-8.sv` | Generic streaming path from the `stream12` family | `NUM_MULT = 2`, `4` or `8` |
| `conv-stream12-i16-p24-o4-m4.sv` / `conv-stream12-i16-p24-o4-m8.sv` | Fixed-MAC compatibility sources from the `stream12` family | Fixed 4 / 8 MACs |

The filename fields are structural counts, not feature-map dimensions:

- `i` is the number of registered input words;
- `p` is the number of registered product-path words, including the retained
  weight/transform/inverse-row storage used by the architecture;
- `o` is the number of registered output words;
- `m` is the number of physical MAC lanes active per Hadamard cycle.

The generic source is the only intentional exception to a single `m` value:
`conv-stream12-generic-i16-p24-o4-m2-4-8.sv` accepts `NUM_MULT` equal to 2, 4
or 8. The fixed sources use one concrete `m` value in their filename.

The generic `stream12` source supports multiple MAC counts, while the concrete
sources are named with their fixed MAC count. The `stream4` sources are
`conv-stream4-i16-p16-o4-m4.sv` and `conv-stream4-i16-p16-o4-m8.sv`, so two files that both declare
`Conv` are never compiled in the same command.

The conventional and fully-parallel variants use
`mult-matrices/tcn4/mult_matrices.sv`. The streaming variants use the distinct
row-oriented implementation in `mult-matrices/stream/tcn4/mult_matrices.sv`.
The distinction is intentional: the two matrix files have different
`Inverse`/`InverseRow` interfaces and are not interchangeable.

## Common testbench

`testbench.sv` is shared by every variant. It checks the common architectural
contract instead of inspecting a variant-specific FSM state:

- one rising `w_conv_end` event per output tile;
- all valid output writes and their golden values;
- input and output address bounds;
- the expected number of output writes;
- the `dump.vcd` waveform and optional Xcelium SHM capture.

This makes one testbench suitable for RTL and annotated gate-level simulation.
The source file is selected by the build or synthesis configuration, while the
testbench remains unchanged. `NUM_MULT` is passed only to the DUT parameter
when the selected source supports it; the fixed sources expose the same
compatibility parameter.

Run the local Verilator flows from this directory:

```bash
make run-std
make run-all16
make run-stream4-4mac
make run-stream4-8mac
make run-stream12 NUM_MULT=2
make run-stream12 NUM_MULT=4
make run-stream12 NUM_MULT=8
```

The ModelSim wrapper for the conventional implementation is:

```bash
fish test.fish
```

For a streaming RTL run, set the source explicitly before invoking the shared
script. For example:

```bash
FASTCONV_STREAM_SOURCE=conv-stream4-i16-p16-o4-m4.sv fish test-streaming.fish
FASTCONV_STREAM_SOURCE=conv-stream12-generic-i16-p24-o4-m2-4-8.sv fish test-streaming.fish
```

The row-level unit test is `streaming_row_testbench.sv`.

## Synthesis configurations

All project-local synthesis configurations are under `synthesis/`:

- `synthesis/tcn4-04mac/` — conventional 4-MAC baseline;
- `synthesis/tcn4-16mac/` — fully parallel 16-MAC architecture;
- `synthesis/stream4/tcn4-04mac/` and `tcn4-08mac/` — fixed 4-word stream;
- `synthesis/stream12/tcn4-02mac/`, `tcn4-04mac/` and `tcn4-08mac/` — generic/fixed sources from the `stream12` family.

Each configuration keeps its own `list-file.txt`, `list-define.txt`,
`top-module.txt`, logical, power and annotated-simulation scripts. The lists
refer only to the canonical files in this directory, so synthesis no longer
depends on the former top-level `conv2x2-all`, `conv2x2stream4` or
`conv2x2stream12` directories.

The previous directory layouts are preserved under `archive/` as a migration
record; they are not part of any active build or synthesis list.

The detailed register-reduction rationale remains in
[`REGISTER_REDUCTION-stream4.md`](REGISTER_REDUCTION-stream4.md).
The consolidated Conv2x2 PPA comparison, including the revalidated `stream4`
results, is in [section 13 of that document](REGISTER_REDUCTION-stream4.md#13-comparativo-geral-das-variantes-conv2x2).
