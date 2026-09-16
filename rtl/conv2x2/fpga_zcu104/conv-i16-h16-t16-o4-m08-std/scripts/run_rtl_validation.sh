#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bench_dir="$(cd "$script_dir/.." && pwd)"
repo_root="$(cd "$script_dir/../../../../.." && pwd)"
pack_data="$repo_root/rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv"
mkdir -p "$bench_dir/reports" "$bench_dir/results"

[[ -f "$pack_data" ]] || {
  printf 'missing generated workload package: %s\n' "$pack_data" >&2
  exit 1
}

if [[ "${RUN_CANONICAL_REGRESSION:-0}" == "1" ]]; then
  echo "[rtl] canonical regression"
  make -C "$repo_root/rtl/conv2x2" run-std >"$bench_dir/reports/rtl_regression.log" 2>&1
else
  printf '%s\n' \
    'canonical regression skipped: it unconditionally enables dump.vcd;' \
    'set RUN_CANONICAL_REGRESSION=1 only when waveform generation is explicitly requested.' \
    >"$bench_dir/reports/rtl_regression.log"
fi

echo "[rtl] steady-state non-zero workload / latency probe"
tmp_dir="$(mktemp -d /tmp/fpga-zcu104-rtl.XXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT
verilator -j 0 -DSIMULATION -DNO_DUMP --top-module tb_power -Wno-fatal \
  --binary --Mdir "$tmp_dir/obj" \
  "$pack_data" \
  "$repo_root/rtl/conv2x2/pack-param/tcn4/pack_param.sv" \
  "$repo_root/rtl/mem/mem.sv" \
  "$repo_root/rtl/csa/csa_lib.sv" \
  "$repo_root/rtl/multip/multip.sv" \
  "$repo_root/rtl/conv2x2/mux-mult/tcn4/mux_mult_04.sv" \
  "$repo_root/rtl/conv2x2/mult-matrices/tcn4/mult_matrices.sv" \
  "$repo_root/rtl/conv2x2/conv-i16-h16-t16-o4-m08-std.sv" \
  "$bench_dir/tb/tb_power.sv" --build >"$bench_dir/reports/rtl_power_compile.log" 2>&1
"$tmp_dir/obj/Vtb_power" >"$bench_dir/reports/rtl_power_workload.log" 2>&1

echo "RTL validation passed; reports are under $bench_dir/reports"
