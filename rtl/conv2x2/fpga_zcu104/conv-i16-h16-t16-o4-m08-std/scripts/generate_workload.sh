#!/usr/bin/env bash
set -euo pipefail

# Generate the deterministic TC2x2 workload without modifying the source
# fast-convolution-rtl checkout. The generated package is local to this FPGA
# benchmark variant and is consumed by both RTL and gate-level testbenches.
script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
bench_dir=$(cd -- "$script_dir/.." && pwd)
fast_conv_root=${FAST_CONV_ROOT:-/home/tarsio/gaph/fast-convolution-rtl}
fast_conv_bin=${FAST_CONV_BIN:-$fast_conv_root/.venv/bin/fast-conv}
tmp_dir=$(mktemp -d /tmp/fastconv-workload.XXXXXX)
trap 'rm -rf "$tmp_dir"' EXIT

[[ -x "$fast_conv_bin" ]] || {
  printf 'fast-conv executable not found: %s\n' "$fast_conv_bin" >&2
  exit 127
}

cp -a "$fast_conv_root/test/2d-tcn4/config" "$tmp_dir/config"
"$fast_conv_bin" --path "$tmp_dir" sim normal \
  --image-side 32 --channel-in 3 --channel-out 3 --seed 1 \
  --name 032-3-3-normal --no-c >"$bench_dir/reports/workload_generation.log"

mkdir -p "$bench_dir/data"
cp "$tmp_dir/sim/sim-032-3-3-normal/pack_data.sv" \
  "$bench_dir/data/pack_data.sv"
cat >"$bench_dir/data/workload_metadata.txt" <<EOF
generator=fast-conv sim normal
fast_conv_root=$fast_conv_root
config=test/2d-tcn4/config
image_side=32
channel_in=3
channel_out=3
seed=1
quant_bits=8
jobs_for_activity=1
job_model=non-reentrant; reset required between launches
EOF
printf 'WORKLOAD_GENERATED package=%s seed=1\n' "$bench_dir/data/pack_data.sv"
