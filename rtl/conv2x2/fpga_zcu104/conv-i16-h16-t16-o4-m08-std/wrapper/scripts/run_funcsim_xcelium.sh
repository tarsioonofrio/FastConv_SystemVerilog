#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  printf 'usage: %s <run-name>\n' "$0" >&2
  exit 2
fi
run_name=$1
[[ "$run_name" =~ ^[A-Za-z0-9._-]+$ ]] || {
  printf 'invalid run name: %s\n' "$run_name" >&2
  exit 2
}
[[ -n "${TMUX:-}" ]] || {
  printf 'post-implementation simulations must run inside tmux\n' >&2
  exit 1
}
[[ -n "${SIMLIB_DIR:-}" ]] || {
  printf 'set SIMLIB_DIR to the compiled Vivado UNISIM Xcelium libraries\n' >&2
  exit 1
}

script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
wrapper_dir=$(cd -- "$script_dir/.." && pwd)
bench_dir=$(cd -- "$wrapper_dir/.." && pwd)
repo_root=$(cd -- "$bench_dir/../../../.." && pwd)
run_dir="$wrapper_dir/reports/$run_name"
netlist="$run_dir/design_routed_funcsim.v"
glbl="$XILINX_VIVADO/data/verilog/src/glbl.v"
tb="$wrapper_dir/tb/tb_fpga_wrapper_funcsim.sv"

for tool in xrun; do
  command -v "$tool" >/dev/null || {
    printf 'required tool not found: %s\n' "$tool" >&2
    exit 127
  }
done
for artifact in "$netlist" "$glbl" "$tb" "$SIMLIB_DIR/cds.lib" "$SIMLIB_DIR/hdl.var"; do
  [[ -f "$artifact" ]] || {
    printf 'required post-implementation simulation artifact missing: %s\n' "$artifact" >&2
    exit 1
  }
done

for scope in internal ports; do
  scope_dir="$run_dir/funcsim_$scope"
  mkdir -p "$scope_dir"
  cd "$scope_dir"
  xrun -64bit -sv \
    -cdslib "$SIMLIB_DIR/cds.lib" \
    -hdlvar "$SIMLIB_DIR/hdl.var" \
    -reflib unisims_ver:unisims_ver \
    -access +rwc \
    -top tb_fpga_wrapper_funcsim \
    -top glbl \
    -timescale 1ns/1ps \
    -input "$script_dir/capture_funcsim_${scope}.tcl" \
    -l xrun.log \
    "$netlist" "$glbl" "$tb"
  grep -F 'FPGA_FUNCsim_RESULT' xrun.log >/dev/null
  grep -F 'result_valid=1 result_ok=1' xrun.log >/dev/null
  [[ -s "activity_${scope}.saif" ]] || {
    printf 'missing non-empty SAIF capture: %s\n' "$scope_dir/activity_${scope}.saif" >&2
    exit 1
  }
done

printf 'WRAPPER_POST_IMPL_FUNC_SIM_PASS run=%s\n' "$run_name"
