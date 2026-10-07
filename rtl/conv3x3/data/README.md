# 3x3 Convolution Datasets

Each `sim-032-*` directory contains a workload and should preserve the
configuration used to generate it next to its vectors. `pack_data.sv` is the
package consumed by RTL; `sim.txt` stores the original library summary;
`winocnn/params.json` describes dimensions, scale, and layout when available.

After `make metrics` or `make report`, the collector writes `metrics.json` in
each eligible dataset directory. It records:

- dimensions/configuration and quantization constants parsed from metadata;
- the complete parsed simulation summary and original `sim.txt` text;
- library metrics such as reported R2 and operation counts;
- MAE, RMSE, maximum absolute/relative error, recomputed R2, mismatch counts/rates,
  and vector-length consistency;
- SHA-256 hashes for the package and generated text artifacts.

Quality metrics compare `s.txt / 2**quant_bits` with `s_default.txt`. The
float-reference mismatch compares integer outputs in `s.txt` against
`trunc(s_default.txt * 2**quant_bits)`. The `quantized_golden_mismatch_*`
fields compare `s.txt` with `s_default_quant.txt` arithmetic-shifted right by
`quant_bits`, the direct-convolution integer reference. Library R2 and
recomputed R2 are separate metrics with different definitions.

For IFN9, the weight-transform scale is 1, so the truncated mode does not lose
numeric precision. The active 16-bit synthesis campaign uses
`ifn9/sim/sim-032-3-3-normal-trunc-nbits16/`. The exact-scaled comparison
package, `ifn9/sim/sim-032-3-3-normal-exact-nbits16/`, is retained under
`archive/ifn9/sim/`; it was generated with `--exact-scaled --nbits 16`.
`generation.json` records the command, seed, library revision, and comparison
with the equivalent truncated package. Both packages generate identical
numeric vectors; the contract flags in `pack_data.sv` differ. Keep this
metadata explicit to distinguish exact, truncated, and raw-spatial weight
modes.

Datasets not selected by the current simulation defaults or active synthesis
configurations are preserved under `data/archive/<algorithm>/sim/<dataset>/`.
The exact-scaled comparison package and legacy sequential IFN9 workload are
archived; the active dataset-metrics scan intentionally excludes
`data/archive/`.
