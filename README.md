# FastConv: fast-convolution accelerators in SystemVerilog (ISCAS 2027)

This repository holds the RTL, datasets, ASIC flow configurations and evidence behind

> T. O. da Silva and F. G. Moraes, "Trading Multiplications for Simpler Transforms: Area and Energy
> Efficiency of Polynomial Winograd Convolution," submitted to the *IEEE International Symposium on Circuits
> and Systems (ISCAS)*, 2027.

FastConv is a streaming 2-D convolution core (3×3 kernel, stride 1) whose datapath is a fast-convolution
algorithm: Toom-Cook (TC), Inspection Factorization (IF) or the Winograd polynomial (WP) construction.
The paper compares the algorithms on the same controller for a 3×32×32 input with 12 output channels,
synthesized in TSMC 28 nm at 500 MHz. The WP 4×4 core spends more multiplications per tile than the
Toom-Cook 4×4 core (64 against 36) but its transforms only add and shift: it has 64.6 % less standard-cell
area (36 360 against 102 775 µm²) and about one third less energy per job (411 against 614 nJ).

The default branch also carries the later work on the same controller (rounding and fractional bits,
pretransformed weights, tap-wise requantization, a direct-convolution and a TC F(2,3) reference, a
throughput sweep); see [Other studies](#other-studies-in-this-repository). The tag `dissertation` marks the
code of the author's master's dissertation.

## Layout

| Folder | Content |
|---|---|
| `rtl/conv2x2/`, `rtl/conv3x3/`, `rtl/conv4x4/` | RTL of the 2×2, 3×3 and 4×4 output tiles, their datasets (`data/<algorithm>/sim/`), generated helper modules (`mult-matrices/`, `mux-mult/`, `pack-param/`), testbenches, design history (`doc/history.md`) and reports |
| `rtl/conv*/synthesis/<configuration>/` | one folder per ASIC run: sources (`list-file.txt`), defines, top parameters, scripts and the Genus/Xcelium evidence |
| `rtl/stream-column/` | the shared streaming controller template, the generators of the algorithm modules and the stream-column testbenches |
| `rtl/mem/`, `rtl/multip/`, `rtl/csa/` | memory model, multipliers, carry-save adders |
| `rtl/conv*/archive/` | retired RTL and flow data (one paper point, `TCff`, still compiles an archived RTL) |
| `rtl/conv*/fpga_zcu104/` | FPGA (ZCU104) campaigns |
| `report/` | repository-wide tables generated from the evidence; `report/iscas2027/` maps each paper label to its RTL, dataset and configuration |
| `scripts/` | report generation, dataset metrics, layout audit, campaign helpers, `sim-config.sh` |
| `contrib/`, `synthesis/`, `notebook/` | third-party and legacy material, kept for provenance |

The rules that keep these areas consistent are in [`docs/repository-organization.md`](docs/repository-organization.md).

## Configurations

The six points of the paper, all with Cin = 3, Cout = 12 and a 32×32 input (30×30 output). "Mult." is the
number of hardware multipliers; the algorithm name gives the output tile (`n16`: 4×4, `n9`: 3×3, `n4`: 2×2).

| Paper label | Algorithm | Mult. | Word | Weight transform | Configuration (`rtl/<arch>/synthesis/`) |
|---|---|---|---|---|---|
| `WPff` | WPN16, WP 4×4 | 32 | 16 b | on chip | `conv4x4/conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column-nbits16-cin3-cout12` |
| `TCff` | TCN16, TC 4×4 | 18 | 20 b, 6 fractional weight bits | on chip | `conv4x4/conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-rowconst6-trunc-frac6-column-cin3-cout12` |
| `TCpre` | TCN16, TC 4×4 | 18 | 20 b, 6 fractional weight bits | offline | `conv4x4/conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-transformed-frac6-column-cin3-cout12` |
| `IF` | IFN9, IF 3×3 | 18 | 16 b | on chip | `conv3x3/conv-ifn9-i40-h27-t36-o9-m18-stream12-prefetch15-rowconst6-trunc-column-nbits16-cin3-cout12` |
| `TCtt` | TCN9, TC 3×3 | 5 | 16 b | on chip | `conv3x3/conv-tcn9-i40-h14-t10-o9-m05-stream10-prefetch15-rowconst5-trunc-column-nbits16-cin3-cout12` |
| `TCtw` | TCN4, TC 2×2 | 8 | 16 b | on chip | `conv2x2/conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc-column-nbits16-cin3-cout12` |

The configuration name encodes the RTL: `i` input words held, `h` weight words held, `t` words at the transform
boundary, `o` output words, `m` multipliers, `stream`/`prefetch` streaming and prefetch words, `rowconst` the
weight transform computed row by row from the raw weights (`transformed`: weights transformed offline), `trunc`
truncated transformed weights; the suffix gives word width and workload (`rtl/conv3x3/RENAMES.md`).
`report/iscas2027/paper-config-map.csv` records the SHA-256 of each RTL and dataset.

## Quick start

Without the Cadence tools (seconds per configuration): RTL simulation of each paper point against its golden
output, with the configuration's own sources, defines and parameters.

```bash
module load verilator/5.052; source /opt/rh/gcc-toolset-15/enable     # or any Verilator 5.052 + g++ 15
scripts/sim-config.sh conv4x4 conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column-nbits16-cin3-cout12
# stream-column simulation passed: tile=6x6 hadamard=8 out=4 ... cycles_to_end=21573 ...
```

Run it for the six configurations of the table above; each prints `simulation passed` and the cycle count
(the RTL testbench counts 40 cycles more than the gate-level run of the paper, a fixed start offset; the
2×2 testbench prints its count at the end of the run). A negative control must fail, for instance
`scripts/sim-config.sh <arch> <rounding configuration> -GROUND=0` reports `output golden mismatch count`.
Builds go to `work/sim-config/` (`WORK=...` to change it).

Regenerate the tables from the committed evidence (Python with pandas):

```bash
make report PYTHON=<python with pandas>   # rewrites report/*.csv and rtl/conv*/report/
make metrics                              # dataset MAE/RMSE
```

The paper rows of `report/merged.csv` and `report/area-hierarchy.csv` come out identical; the tables also
gain the configurations added after the paper.

The whole ASIC flow for one configuration, with the Cadence tools and the library (inside `tmux`):

```bash
make list-configs ARCH=conv4x4
make flow ARCH=conv4x4 CONFIG=<configuration-directory>   # synth, gate-sim, power; stops on a failed stage
make synth|gate-sim|power ARCH=conv4x4 CONFIG=<configuration-directory>   # one stage
```

`make help` lists the other targets (`make sim` for the legacy per-architecture simulations, `make sim-all`,
`make audit-layout`).

## Requirements

| Item | Version used | Notes |
|---|---|---|
| Verilator | 5.052 | RTL simulation; needs g++ 15 (`gcc-toolset-15`) |
| Python | ≥ 3.8 | `pandas` for `make report`; the root `Makefile` looks for `../fast-convolution-rtl/.venv` first |
| `fast-convolution-rtl` | | the `fast-conv` CLI generates new datasets, goldens and helper modules ([repository](https://github.com/tarsioonofrio/fast-convolution-rtl)); not needed to rerun the committed datasets |
| Cadence Genus | 21.12 | synthesis and power (`module load cadence/genus/211`) |
| Cadence Xcelium | 23.03 | gate-level simulation (`cadence/xcelium/2303`) |
| TSMC 28 nm HPC+ standard cells `tcbn28hpcplusbwp30p140` | | under NDA, not included; paths in each configuration's `scripts/mmmc_tsmc_28_bv.tcl` |
| GNU make, bash, tmux | | the EDA targets refuse to run outside `tmux` |

Per configuration: a few minutes of synthesis, gate-level simulation and power for the Cin = 3 points, and up
to about 1 GB of disk, mostly the gate-level activity database (`sim/dut.shm`, not versioned).

## Where each number of the paper comes from

The consolidated values are in `report/`; the raw evidence of each point is in its configuration folder.
Energy is power × cycles × 2 ns.

| Paper | Value | File (columns) |
|---|---|---|
| Table of designs | algorithm, multipliers, tile | the configuration names above; `report/mac-scaling.csv` for the other multiplier counts |
| ASIC table: cycles | gate-level cycles (21 533 for WPff and TCff) | `report/merged.csv` (`cycles`); raw: `<config>/sim/xrun.log` |
| ASIC table: area | standard-cell area, µm² | `report/merged.csv` (`Cell Area um^2`); raw: `<config>/logical/results/reports/Conv_area.rpt` |
| ASIC table: power | typical corner, gate-level activity, mW | `report/merged.csv` (`Subtotal`); raw: `<config>/power/power_evaluation.txt` |
| ASIC table: energy | nJ per job | `report/merged.csv` (`energy_nj`) |
| Area breakdown | area per block | `report/area-hierarchy.csv`; raw: `Conv_area.rpt` |
| Accuracy table | MAE, maximum error, R² of each dataset | `report/functional-quality.csv` (`mae`, `max_abs`, `r2_library`); `metrics.json` next to each dataset |
| Design-space figure | area, power, energy of every point | `report/pareto.csv`, `report/mac-scaling.csv`, `report/time.csv`, `report/power.csv` |
| Weight trade-off | coefficient counts; SRAM estimate | `report/weight-representation-size.md`, `report/sram-macro-wpn16-m32-estimate.md` (a model, not a flow result) |
| Abstract: −64.6 % area | WPff against TCff | `report/merged.csv`: 36 360.324 against 102 774.672 µm² |
| Abstract: energy | WPff against TCff | `report/merged.csv`: 411.32 against 614.10 nJ |
| Flow completeness | synthesis, gate-level, SDF, power done | `report/flow-status.csv` |

[`report/iscas2027/README.md`](report/iscas2027/README.md) (in Portuguese) has the full table with the precise
values, the accuracy of the six points and how each paper block maps to the evidence. SAURIA and WinoCNN, the
external baselines of the paper, live in their own repositories
([sauria](https://github.com/tarsioonofrio/sauria), [WinoCNN](https://github.com/tarsioonofrio/WinoCNN/tree/iscas2027)).

## RTL folders

Each architecture folder holds the active RTL of one output tile; the file name is the configuration name
without the workload suffix. Algorithm codes: `tcn` Toom-Cook, `ifn` Inspection Factorization, `wpn` Winograd
polynomial, `bsn` a 7-product bit-shift F(4,3), `dcn` the direct convolution written as a selection bilinear
(transforms are wiring). The streaming controller is shared: `rtl/stream-column/gen_stream_column.py` writes the
algorithm-dependent modules (weight transform row by row, inverse transform, its accumulation) from the
algorithm's `build.json`, and `gen_pretransformed_column.py` derives the pretransformed-weight variants. The
input transform comes from `mult-matrices/<algorithm>/`, generated by `fast-convolution-rtl`. The design history
of each tile, with the reasons for each controller change, is in `rtl/conv*/doc/history.md`.

## Flow, step by step

### 01: dataset and golden (`fast-convolution-rtl`)

`fast-conv sim normal --image-side 32 -i 3 -o 12 -d 0 --truncated-weight-transform --nbits 16` (seed 0,
normal inputs, Q8 quantization) writes the input, weights, golden output and `pack_data.sv` into
`rtl/conv*/data/<algorithm>/sim/<dataset>/`. The golden models the RTL arithmetic bit for bit: transformed
weights truncated (or rounded, `--rounding nearest`) with optional fractional bits, NBITS wrap-around. Each
dataset keeps `generation.json` (command, revision, SHA-256) and `metrics.json`.

### 02: RTL simulation (`scripts/sim-config.sh`, `make sim`)

Verilator compiles the configuration's `list-file.txt` and `testbench-file.txt` with its defines and the
parameters the testbench declares, then compares every output word with the golden; any mismatch ends the run
with `output golden mismatch count`.

### 03: synthesis (`<config>/logical/run.sh`)

Genus 21.12 (`syn_generic/syn_map/syn_opt`, global effort high, clock gating) at 2 ns. Constraints
(`scripts/constraints.sdc`): 500 MHz clock, false path from `reset`, input driving cell `GINVD1BWP30P140`,
output load of a `GINVMCOD8BWP30P140` pin. MMMC views: 0.81 V/125 °C/RC worst (timing), 0.90 V/25 °C/RC typical,
0.99 V/−40 °C/RC best. Outputs: mapped netlist, one SDF per view, area, timing, gates and power reports in
`logical/results/`. Area is standard-cell area, without routing; memories are outside the core.

### 04: gate-level simulation (`<config>/sim/run.sh`)

Xcelium 23.03 simulates the mapped netlist with the nominal SDF and the same testbench (`GATE_LEVEL`), checks the
golden output and records the activity in `sim/dut.shm`. `sim/xrun.log` keeps the pass line and the cycle count.

### 05: power (`<config>/power/run.sh`)

Genus reads the netlist, the typical library (0.90 V, 25 °C) and the activity of the gate-level run
(`read_stimulus` on the testbench's DUT) and writes `power/power_evaluation.txt` (leakage, internal, switching
by category).

### 06: reports (`make report`)

`scripts/report.py` collects every active configuration into `report/` and `rtl/conv*/report/`; archived
configurations are left out unless requested.

## Other studies in this repository

Later configurations, on the same controller and flow, for a study of fast convolution under quantization
(in progress): rounding and fractional bits in the transformed weights (`rowconst*-round-column-frac*-extra*`),
pretransformed weights for TC, WP and the 7-product bit-shift F(4,3) (`transformed-round-column`), tap-wise
8-bit requantization (`transformed-tapwise-column`), the direct convolution (`dcn16`) and TC F(2,3) (`tcn4`)
references, a throughput sweep with 2× and 4× the multipliers (`-mult<N>-`), and a real workload taken from
ResNet-18 (`-cin16-cout16-l10c1`, layer1.0.conv1). Their datasets are generated by `fast-convolution-rtl`.

## Notes

- **A folder is not a result.** A prepared configuration does not prove its flow finished; check its logs and
  `report/flow-status.csv`. `make audit-layout` checks the references of every `list-file.txt` without changing
  anything.
- **The configuration is the source of truth.** `list-file.txt` names exactly what the flow compiled; this
  matters for `TCff`, whose RTL sits in `rtl/conv4x4/archive/` but is still compiled by an active configuration.
- **Word widths differ.** `TCff`/`TCpre` use 20-bit words and `WEIGHT_TRANSFORM_FRAC_BITS=6` (`frac6`); the other
  points use 16-bit words. `frac6` is not added to the word width.
- **Verilator line limit.** Verilator 5.052 rejects lines above about 40 000 tokens; long `pack_data.sv` arrays
  are wrapped at 16 values per line (values unchanged).
- EDA outputs (`*.shm`, `xcelium.d/`, `fv/`, `genus.log*`, `*.db`) are not versioned.

## Limitations

- Area and power are of the core cells after logic synthesis: no place and route, no routing area, no IR drop.
  Input, weight and output memories are behavioral models outside the measured core; any SRAM figure is a
  separate estimate.
- Power is at the typical corner with the activity of one workload (random normal inputs, seed 0).
- The SDF used by the gate-level simulation comes from synthesis, not from extracted parasitics.
- SAURIA and WinoCNN have different measurement boundaries and precisions; the paper uses them as reference
  points, not as equivalent measurements.

## License

MIT License (`LICENSE`), copyright © 2024–2026 Társio Onofrio da Silva. Third-party material under `contrib/`
keeps its original terms. The standard-cell library is not distributed.
