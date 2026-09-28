#!/usr/bin/env bash
set -euo pipefail

# Execute four matched scalar/column FPGA post-route power campaigns.
# Long Vivado/Xcelium work is intended to run in tmux on the Paxos.
script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
bench_dir=$(cd -- "$script_dir/.." && pwd)
repo_root=$(cd -- "$bench_dir/../../../../" && pwd)
reports_dir="$bench_dir/reports"
simlib_dir="$reports_dir/simlibs_unisim"
mkdir -p "$reports_dir"

for tool in vivado xrun; do
  command -v "$tool" >/dev/null || { printf 'tool not found: %s\n' "$tool" >&2; exit 127; }
done

run_impl() {
  local run_name=$1 manifest=$2
  vivado -mode batch -source "$script_dir/synth_impl.tcl" \
    -log "$reports_dir/${run_name}.synth.vivado.log" \
    -journal "$reports_dir/${run_name}.synth.vivado.jou" \
    -tclargs "$bench_dir" "$repo_root" "$run_name" "$bench_dir/$manifest"
  vivado -mode batch -source "$script_dir/power_vectorless.tcl" \
    -log "$reports_dir/${run_name}.vectorless.vivado.log" \
    -journal "$reports_dir/${run_name}.vectorless.vivado.jou" \
    -tclargs "$bench_dir" "$run_name"
  vivado -mode batch -source "$script_dir/prepare_funcsim.tcl" \
    -log "$reports_dir/${run_name}.funcsim_prepare.vivado.log" \
    -journal "$reports_dir/${run_name}.funcsim_prepare.vivado.jou" \
    -tclargs "$reports_dir/$run_name/design_routed.dcp" \
             "$reports_dir/$run_name/design_routed_funcsim.v" "$simlib_dir"
}

# Resolve glbl.v from the active Vivado installation without depending on a
# previously compiled simulator library.
vivado_root=$(cd -- "$(dirname -- "$(command -v vivado)")/../.." && pwd)
glbl_v="$vivado_root/data/verilog/src/glbl.v"
[[ -f "$glbl_v" ]] || { printf 'cannot locate glbl.v under %s\n' "$vivado_root" >&2; exit 1; }

run_xrun_capture() {
  local run_name=$1 mode=$2 capture_name=$3
  local run_dir="$reports_dir/$run_name"
  local capture_dir="$run_dir/$capture_name"
  mkdir -p "$capture_dir"
  cd "$capture_dir"
  local define_args=(-define GATE_LEVEL)
  if [[ "$mode" == column ]]; then define_args+=(-define COLUMN_IO); fi
  xrun -64bit -sv -access +r -cdslib "$simlib_dir/cds.lib" \
    -hdlvar "$simlib_dir/hdl.var" \
    -reflib "$simlib_dir/unisims_ver:unisims_ver" \
    "${define_args[@]}" -top tb_power -top glbl -timescale 1ns/1ps \
    -input "$script_dir/capture_${capture_name}_saif.tcl" -l xrun.log \
    "$repo_root/rtl/conv2x2/pack-param/tcn4/pack_param.sv" \
    "$repo_root/rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv" \
    "$repo_root/rtl/mem/mem.sv" "$run_dir/design_routed_funcsim.v" \
    "$glbl_v" "$bench_dir/tb/tb_power.sv"
  expected_saif="activity_${capture_name}.saif"
  [[ -s "$expected_saif" ]] || {
    printf 'missing SAIF output for %s/%s\n' "$run_name" "$capture_name" >&2
    exit 1
  }
  grep -q 'POWER_RESULT PASS' xrun.log || {
    printf 'post-route functional golden marker missing for %s/%s\n' "$run_name" "$capture_name" >&2
    exit 1
  }
}

run_p3f() {
  local run_name=$1 mode=$2
  run_xrun_capture "$run_name" "$mode" dut
  run_xrun_capture "$run_name" "$mode" top
  vivado -mode batch -source "$script_dir/power_p3f.tcl" \
    -log "$reports_dir/${run_name}.p3f.vivado.log" \
    -journal "$reports_dir/${run_name}.p3f.vivado.jou" \
    -tclargs "$bench_dir" "$run_name" \
    "$reports_dir/$run_name/dut/activity_dut.saif" \
    "$reports_dir/$run_name/top/activity_top.saif"
}

run_impl std_scalar rtl_manifest_std.txt
run_p3f std_scalar scalar
run_impl std_column rtl_manifest_std_column.txt
run_p3f std_column column
run_impl prefetch8_scalar rtl_manifest_prefetch8.txt
run_p3f prefetch8_scalar scalar
run_impl prefetch8_column rtl_manifest_prefetch8_column.txt
run_p3f prefetch8_column column

python3 "$script_dir/collect_comparison.py" --bench-dir "$bench_dir"
printf 'COLUMN_POWER_CAMPAIGN_COMPLETE reports=%s\n' "$reports_dir"
