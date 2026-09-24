#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  printf 'usage: %s <run-name>\n' "$0" >&2
  exit 2
fi
[[ -n "${TMUX:-}" ]] || {
  printf 'OOC implementation must run inside tmux\n' >&2
  exit 1
}
command -v vivado >/dev/null || {
  printf 'vivado not found; load the approved Vivado module first\n' >&2
  exit 127
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ooc_dir=$(cd -- "$script_dir/.." && pwd)
run_name=$1
[[ "$run_name" =~ ^[A-Za-z0-9._-]+$ ]] || {
  printf 'invalid run name: %s\n' "$run_name" >&2
  exit 2
}
run_dir="$ooc_dir/reports/$run_name"
mkdir -p "$run_dir"
vivado -mode batch -nojournal -nolog \
  -source "$script_dir/synth_impl.tcl" -tclargs "$run_name" \
  >"$run_dir/vivado.log" 2>&1
grep -F "OOC_IMPLEMENTATION_COMPLETE run=$run_name iobuf_count=0" "$run_dir/vivado.log"
