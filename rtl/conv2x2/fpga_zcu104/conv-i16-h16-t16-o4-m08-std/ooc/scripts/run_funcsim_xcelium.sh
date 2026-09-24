#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  printf 'usage: %s <run-name> <compiled-unisim-dir>\n' "$0" >&2
  exit 2
fi
[[ -n "${TMUX:-}" ]] || {
  printf 'post-implementation Xcelium runs must execute inside tmux\n' >&2
  exit 1
}
command -v xrun >/dev/null || {
  printf 'xrun not found; load the approved Xcelium module first\n' >&2
  exit 127
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ooc_dir=$(cd -- "$script_dir/.." && pwd)
bench_dir=$(cd -- "$ooc_dir/.." && pwd)
repo_root=$(cd -- "$bench_dir/../../../.." && pwd)
run_name=$1
simlib_dir=$(cd -- "$2" && pwd)
run_dir="$ooc_dir/reports/$run_name"
netlist="$run_dir/design_routed_ooc_funcsim.v"
glbl="${XILINX_VIVADO:?load Vivado 2023.2 first}/data/verilog/src/glbl.v"
pack_data="$repo_root/rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv"
pack_param="$repo_root/rtl/conv2x2/pack-param/tcn4/pack_param.sv"
memory="$repo_root/rtl/mem/mem.sv"
tb="$bench_dir/reports/p3_timesim/tb_power_timing_safe.sv"

for path in "$netlist" "$glbl" "$pack_data" "$pack_param" "$memory" "$tb" "$simlib_dir/cds.lib" "$simlib_dir/hdl.var"; do
  [[ -f "$path" ]] || { printf 'required artifact missing: %s\n' "$path" >&2; exit 1; }
done

for scope in internal ports; do
  scope_dir="$run_dir/funcsim_$scope"
  mkdir -p "$scope_dir"
  cd "$scope_dir"
  xrun -64bit -sv \
    -cdslib "$simlib_dir/cds.lib" \
    -hdlvar "$simlib_dir/hdl.var" \
    -reflib unisims_ver:unisims_ver \
    -access +rwc \
    -define GATE_LEVEL \
    -define P3_TRACE_COMB_MEMORY \
    -top tb_power -top glbl \
    -timescale 1ns/1ps \
    -input "$script_dir/capture_saif_${scope}.tcl" \
    -l xrun.log \
    "$pack_param" "$pack_data" "$memory" "$netlist" "$glbl" "$tb"
  grep -F 'P3_TIMING_SAFE_RESULT' xrun.log
  grep -F 'writes=8100 expected_writes=8100 tiles=2025 golden_errors=0' xrun.log >/dev/null
  grep -F "OOC_P3F_${scope^^}_CAPTURE_ENDED" xrun.log >/dev/null
  [[ -s "activity_${scope}.saif" ]] || {
    printf 'missing SAIF capture: %s\n' "$scope_dir/activity_${scope}.saif" >&2
    exit 1
  }
done

printf 'OOC_POST_IMPL_FUNCSIM_PASS run=%s\n' "$run_name"
