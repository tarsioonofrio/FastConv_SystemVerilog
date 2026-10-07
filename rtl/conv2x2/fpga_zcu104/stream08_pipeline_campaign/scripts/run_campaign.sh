#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
bench_dir=$(cd -- "$script_dir/.." && pwd)
repo_root=$(cd -- "$bench_dir/../../../../" && pwd)
common_dir="$repo_root/rtl/conv2x2/fpga_zcu104/column_power_comparison"
common_scripts="$common_dir/scripts"
reports_dir="$bench_dir/reports"
simlib_dir="$reports_dir/simlibs_unisim"
mkdir -p "$reports_dir"

for tool in vivado xrun python3; do
  command -v "$tool" >/dev/null || { printf 'tool not found: %s\n' "$tool" >&2; exit 127; }
done

run_impl() {
  local name=$1 manifest=$2
  vivado -mode batch -source "$common_scripts/synth_impl.tcl" \
    -log "$reports_dir/${name}.synth.vivado.log" \
    -journal "$reports_dir/${name}.synth.vivado.jou" \
    -tclargs "$bench_dir" "$repo_root" "$name" "$bench_dir/$manifest"
  vivado -mode batch -source "$common_scripts/power_vectorless.tcl" \
    -log "$reports_dir/${name}.vectorless.vivado.log" \
    -journal "$reports_dir/${name}.vectorless.vivado.jou" \
    -tclargs "$bench_dir" "$name"
  vivado -mode batch -source "$common_scripts/prepare_funcsim.tcl" \
    -log "$reports_dir/${name}.funcsim_prepare.vivado.log" \
    -journal "$reports_dir/${name}.funcsim_prepare.vivado.jou" \
    -tclargs "$reports_dir/$name/design_routed.dcp" \
             "$reports_dir/$name/design_routed_funcsim.v" "$simlib_dir"
}

vivado_exe=$(readlink -f "$(command -v vivado)")
vivado_root=$(cd -- "$(dirname -- "$vivado_exe")/.." && pwd)
glbl_v="$vivado_root/data/verilog/src/glbl.v"
[[ -f "$glbl_v" ]] || { printf 'cannot locate glbl.v under %s\n' "$vivado_root" >&2; exit 1; }

run_capture() {
  local name=$1 capture=$2
  local run_dir="$reports_dir/$name" capture_dir="$reports_dir/$name/$capture"
  mkdir -p "$capture_dir"
  cd "$capture_dir"
  xrun -64bit -sv -access +r -cdslib "$simlib_dir/cds.lib" \
    -hdlvar "$simlib_dir/hdl.var" -reflib "$simlib_dir/unisims_ver:unisims_ver" \
    -define GATE_LEVEL -top tb_power -top glbl -timescale 1ns/1ps \
    -input "$common_scripts/capture_${capture}_saif.tcl" -l xrun.log \
    "$repo_root/rtl/conv2x2/pack-param/tcn4/pack_param.sv" \
    "$repo_root/rtl/conv2x2/data/archive/tcn4/sim/sim-032-3-3-normal/pack_data.sv" \
    "$repo_root/rtl/mem/mem.sv" "$run_dir/design_routed_funcsim.v" \
    "$glbl_v" "$common_dir/tb/tb_power.sv"
  [[ -s "activity_${capture}.saif" ]] || { printf 'missing %s SAIF for %s\n' "$capture" "$name" >&2; exit 1; }
  grep -q 'POWER_RESULT PASS' xrun.log || { printf 'functional golden marker missing for %s/%s\n' "$name" "$capture" >&2; exit 1; }
}

run_p3f() {
  local name=$1
  run_capture "$name" dut
  run_capture "$name" top
  vivado -mode batch -source "$common_scripts/power_p3f.tcl" \
    -log "$reports_dir/${name}.p3f.vivado.log" \
    -journal "$reports_dir/${name}.p3f.vivado.jou" \
    -tclargs "$bench_dir" "$name" \
    "$reports_dir/$name/dut/activity_dut.saif" \
    "$reports_dir/$name/top/activity_top.saif"
}

cat > "$reports_dir/provenance.txt" <<EOF
commit=$(git -C "$repo_root" rev-parse HEAD)
host=$(hostname)
vivado=$(vivado -version | head -1)
xrun=$(xrun -version 2>&1 | head -1)
part=xczu7ev-ffvc1156-2-e
clock_target_mhz=317
workload=rtl/conv2x2/data/archive/tcn4/sim/sim-032-3-3-normal/pack_data.sv
EOF
workload_path=rtl/conv2x2/data/archive/tcn4/sim/sim-032-3-3-normal/pack_data.sv
workload_hash=$(sha256sum "$repo_root/$workload_path" | cut -d ' ' -f 1)
printf '%s  %s\n' "$workload_hash" "$workload_path" > "$reports_dir/workload.sha256"

run_impl rowconst4 manifests/rowconst4.txt
run_p3f rowconst4
run_impl wstream4 manifests/wstream4.txt
run_p3f wstream4
run_impl prefetch4-rowconst4 manifests/prefetch4-rowconst4.txt
run_p3f prefetch4-rowconst4
run_impl prefetch4 manifests/prefetch4.txt
run_p3f prefetch4
run_impl prefetch8-rowconst4 manifests/prefetch8-rowconst4.txt
run_p3f prefetch8-rowconst4

python3 "$script_dir/collect_results.py" --bench-dir "$bench_dir"
printf 'STREAM08_FPGA_CAMPAIGN_COMPLETE reports=%s\n' "$reports_dir"
