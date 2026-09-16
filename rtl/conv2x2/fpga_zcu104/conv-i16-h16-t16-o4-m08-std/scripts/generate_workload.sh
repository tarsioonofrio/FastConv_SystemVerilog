#!/usr/bin/env bash
set -euo pipefail

# Validate and record the canonical deterministic TC2x2 workload used by this
# benchmark. The stimulus is intentionally shared with the RTL conv2x2 data
# tree; this script does not create a second variant-local copy.
script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
bench_dir=$(cd -- "$script_dir/.." && pwd)
repo_root=$(cd -- "$bench_dir/../../../.." && pwd)
stimulus="$repo_root/rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv"

[[ -f "$stimulus" ]] || {
  printf 'canonical workload package not found: %s\n' "$stimulus" >&2
  exit 127
}
sha256sum "$stimulus" >"$bench_dir/reports/workload_generation.log"
cat >>"$bench_dir/reports/workload_generation.log" <<EOF
generator=fast-conv sim normal
stimulus=$stimulus
image_side=32
channel_in=3
channel_out=3
seed=1
quant_bits=8
jobs_for_activity=1
job_model=non-reentrant; reset required between launches
EOF
printf 'CANONICAL_WORKLOAD_SELECTED package=%s seed=1\n' "$stimulus"
