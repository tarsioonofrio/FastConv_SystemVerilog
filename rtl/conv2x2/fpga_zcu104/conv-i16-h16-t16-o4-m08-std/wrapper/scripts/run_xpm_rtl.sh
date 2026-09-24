#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  printf 'usage: %s <run-name> [normal|fault]\n' "$0" >&2
  exit 2
fi
run_name=$1
fault_mode=${2:-normal}
[[ "$run_name" =~ ^[A-Za-z0-9._-]+$ ]] || {
  printf 'invalid run name: %s\n' "$run_name" >&2
  exit 2
}
[[ "$fault_mode" == normal || "$fault_mode" == fault ]] || {
  printf 'invalid checker fault mode: %s\n' "$fault_mode" >&2
  exit 2
}

script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
wrapper_dir=$(cd -- "$script_dir/.." && pwd)
bench_dir=$(cd -- "$wrapper_dir/.." && pwd)
repo_root=$(cd -- "$bench_dir/../../../.." && pwd)
run_dir="$wrapper_dir/reports/$run_name"
xpm_source="${XILINX_VIVADO:-}/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv"

for tool in xrun; do
  command -v "$tool" >/dev/null || {
    printf 'required tool not found: %s\n' "$tool" >&2
    exit 127
  }
done
[[ -n "${TMUX:-}" ]] || {
  printf 'long wrapper simulations must run inside tmux\n' >&2
  exit 1
}
[[ -f "$xpm_source" ]] || {
  printf 'XPM simulation source not found: %s\n' "$xpm_source" >&2
  exit 1
}

python3 "$script_dir/generate_memory_images.py" \
  --pack-data "$repo_root/rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv" \
  --out-dir "$wrapper_dir/data" >/dev/null

mkdir -p "$run_dir"
for image in input_features.mem transformed_weights.mem output_zero.mem; do
  ln -sfn "../../data/$image" "$run_dir/$image"
done

cd "$run_dir"
xrun_args=(-64bit -sv -timescale 1ns/1ps -access +rwc)
if [[ "$fault_mode" == fault ]]; then
  xrun_args+=(-define CHECKER_FAULT_INJECT)
fi
xrun "${xrun_args[@]}" \
  -top tb_fpga_wrapper \
  -l xrun.log \
  "$xpm_source" \
  "$repo_root/rtl/conv2x2/pack-param/tcn4/pack_param.sv" \
  "$repo_root/rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv" \
  "$wrapper_dir/data/output_signature_pkg.sv" \
  "$repo_root/rtl/csa/csa_lib.sv" \
  "$repo_root/rtl/multip/multip.sv" \
  "$repo_root/rtl/conv2x2/mux-mult/tcn4/mux_mult_04.sv" \
  "$repo_root/rtl/conv2x2/mult-matrices/tcn4/mult_matrices.sv" \
  "$repo_root/rtl/conv2x2/conv-i16-h16-t16-o4-m08-std.sv" \
  "$wrapper_dir/rtl/fpga_benchmark_top.sv" \
  "$wrapper_dir/tb/tb_fpga_wrapper.sv"

grep -F 'FPGA_WRAPPER_RESULT' xrun.log
grep -F 'golden_errors=0' xrun.log >/dev/null
grep -F 'writes=8100' xrun.log >/dev/null
grep -F 'tiles=2025' xrun.log >/dev/null
grep -F 'checker_reads=2700' xrun.log >/dev/null
if [[ "$fault_mode" == fault ]]; then
  grep -F 'result_valid=1 result_ok=0' xrun.log >/dev/null
else
  grep -F 'result_valid=1 result_ok=1' xrun.log >/dev/null
fi
printf 'WRAPPER_XPM_RTL_PASS run=%s log=%s\n' "$run_name" "$run_dir/xrun.log"
