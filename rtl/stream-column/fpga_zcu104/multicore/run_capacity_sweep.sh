#!/usr/bin/env bash
set -euo pipefail

if (($# < 4)); then
  printf 'usage: %s <repo-root> <output-root> <ifn9|ifn9_m18|wpn16|wpn16_nbits16> <core-count> [core-count... ]\n' "$0" >&2
  exit 2
fi

repo_root=$(cd -- "$1" && pwd)
output_root=$(mkdir -p -- "$2" && cd -- "$2" && pwd)
algorithm=$3
shift 3
case "$algorithm" in
  ifn9|ifn9_m18|wpn16|wpn16_nbits16) ;;
  *) printf 'unsupported algorithm: %s\n' "$algorithm" >&2; exit 2 ;;
esac
script="$repo_root/rtl/stream-column/fpga_zcu104/multicore/synth_replicas.tcl"
xdc="$repo_root/rtl/stream-column/fpga_zcu104/constraints/zcu104_317mhz.xdc"

for cores in "$@"; do
  if ! [[ "$cores" =~ ^[1-9][0-9]*$ ]]; then
    printf 'invalid core count: %s\n' "$cores" >&2
    exit 2
  fi
  run_dir="$output_root/${algorithm}_${cores}"
  mkdir -p -- "$run_dir"
  printf 'Starting %s with %s replicas; outputs: %s\n' "$algorithm" "$cores" "$run_dir"
  vivado -mode batch -notrace \
    -log "$run_dir/vivado.log" \
    -journal "$run_dir/vivado.jou" \
    -source "$script" \
    -tclargs "$repo_root" "$run_dir" "$algorithm" "$cores" "$xdc"
  printf 'Completed %s with %s replicas\n' "$algorithm" "$cores"
done
