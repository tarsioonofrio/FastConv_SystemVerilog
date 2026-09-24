#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  printf 'usage: %s <run-name>\n' "$0" >&2
  exit 2
fi
[[ -n "${TMUX:-}" ]] || {
  printf 'OOC power analysis must run inside tmux\n' >&2
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
  -source "$script_dir/power_saif.tcl" -tclargs "$run_name" \
  >"$run_dir/power_vivado.log" 2>&1
for corner in typical maximum; do
  [[ -s "$run_dir/power_ooc_p3f_${corner}.rpt" ]] || {
    printf 'power report missing for corner: %s\n' "$corner" >&2
    exit 1
  }
done
printf 'OOC_P3F_POWER_COMPLETE run=%s\n' "$run_name"
