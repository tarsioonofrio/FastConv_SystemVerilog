#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 || ( "$1" != "rtl" && "$1" != "implementation" ) ]]; then
  printf 'usage: %s <rtl|implementation> <run-name>\n' "$0" >&2
  exit 2
fi
mode=$1
run_name=$2
[[ "$run_name" =~ ^[A-Za-z0-9._-]+$ ]] || {
  printf 'invalid run name: %s\n' "$run_name" >&2
  exit 2
}
command -v tmux >/dev/null || {
  printf 'required tool not found: tmux\n' >&2
  exit 127
}

script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
wrapper_dir=$(cd -- "$script_dir/.." && pwd)
run_dir="$wrapper_dir/reports/$run_name"
session="fcwrap_${mode}_${run_name}"
session=${session//[^A-Za-z0-9_-]/_}
log="$run_dir/tmux.log"
mkdir -p "$run_dir"
if tmux has-session -t "$session" 2>/dev/null; then
  printf 'tmux session already exists: %s\n' "$session" >&2
  exit 1
fi

if [[ "$mode" == "rtl" ]]; then
  cmd="'$script_dir/run_xpm_rtl.sh' '$run_name' > '$log' 2>&1"
else
  cmd="vivado -mode batch -source '$script_dir/synth_impl.tcl' -tclargs '$run_name' > '$log' 2>&1"
fi
tmux new-session -d -s "$session" -c "$wrapper_dir/data" "$cmd"
printf 'TMUX_SESSION=%s\nLOG=%s\n' "$session" "$log"
