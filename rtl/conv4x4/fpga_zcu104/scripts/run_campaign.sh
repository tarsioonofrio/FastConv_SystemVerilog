#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  printf 'usage: %s <output-root> [tcn16|wpn16|wpn16_m16|wpn16_m32 ...]\n' "$0" >&2
  exit 2
fi

script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
fpga_dir=$(cd -- "$script_dir/.." && pwd)
repo_root=$(cd -- "$fpga_dir/../../.." && pwd)
output_root=$1
shift
if [[ $# -eq 0 ]]; then
  set -- tcn16 wpn16 wpn16_m16 wpn16_m32
fi

export STREAM_COLUMN_FPGA_CONFIG_DIR="$fpga_dir"
export STREAM_COLUMN_FPGA_XDC="$fpga_dir/constraints/zcu104_317mhz.xdc"
exec "$repo_root/rtl/stream-column/fpga_zcu104/scripts/run_all.sh" "$output_root" "$@"
