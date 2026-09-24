#!/usr/bin/env bash
set -euo pipefail

mode=${1:-}
if [[ "$mode" == "funcsim" ]]; then
  [[ $# -eq 3 ]] || {
    printf 'usage: %s funcsim <run-name> <simlib-dir>\n' "$0" >&2
    exit 2
  }
elif [[ $# -ne 2 || ( "$mode" != "rtl" && "$mode" != "rtl-fault" && "$mode" != "implementation" && "$mode" != "audit" && "$mode" != "power" ) ]]; then
  printf 'usage: %s <rtl|rtl-fault|implementation|audit|power> <run-name>\n' "$0" >&2
  exit 2
fi
run_name=$2
simlib_dir=${3:-}
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
bench_dir=$(cd -- "$wrapper_dir/.." && pwd)
repo_root=$(cd -- "$bench_dir/../../../.." && pwd)
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
  task_cmd="'$script_dir/run_xpm_rtl.sh' '$run_name' > '$log' 2>&1"
elif [[ "$mode" == "rtl-fault" ]]; then
  task_cmd="'$script_dir/run_xpm_rtl.sh' '$run_name' fault > '$log' 2>&1"
elif [[ "$mode" == "implementation" ]]; then
  task_cmd="vivado -mode batch -source '$script_dir/synth_impl.tcl' -tclargs '$run_name' > '$log' 2>&1"
elif [[ "$mode" == "funcsim" ]]; then
  task_cmd="SIMLIB_DIR='$simlib_dir' bash '$script_dir/run_funcsim_xcelium.sh' '$run_name' > '$log' 2>&1"
elif [[ "$mode" == "power" ]]; then
  task_cmd="vivado -mode batch -source '$script_dir/power_funcsim_saif.tcl' -tclargs '$run_name' > '$log' 2>&1"
else
  audit_dir="$run_dir/audit"
  mkdir -p "$audit_dir"
  dcp="${AUDIT_DCP:-$wrapper_dir/reports/route_317/design_routed.dcp}"
  task_cmd="vivado -mode batch -source '$script_dir/audit_routed.tcl' -tclargs '$dcp' '$audit_dir' > '$log' 2>&1"
fi
cmd="source /usr/share/Modules/init/bash && module purge && module use /soft64/modulefiles && module load xilinx/vivado/2023.2 cadence/xcelium/2303 && cd '$wrapper_dir/data' && python3 '$script_dir/generate_memory_images.py' --pack-data '$repo_root/rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv' --out-dir '$wrapper_dir/data' && $task_cmd"
tmux new-session -d -s "$session" -c "$wrapper_dir/data" bash -lc "$cmd"
printf 'TMUX_SESSION=%s\nLOG=%s\n' "$session" "$log"
