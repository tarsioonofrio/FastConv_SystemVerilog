#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${TMUX:-}" ]]; then
  echo "run this FPGA campaign inside tmux" >&2
  exit 2
fi

variant=${1:?usage: run_trunc_column_nbits16.sh <m08|m04> <published-commit>}
expected_commit=${2:?usage: run_trunc_column_nbits16.sh <m08|m04> <published-commit>}
script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
bench_dir=$(cd -- "$script_dir/.." && pwd)
repo_root=$(cd -- "$bench_dir/../../../../" && pwd)
common_dir="$repo_root/rtl/conv2x2/fpga_zcu104/column_power_comparison"
reports_dir="$bench_dir/reports"
workload="$repo_root/rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal-trunc-nbits16/pack_data.sv"
run_suffix=prefetch8-rowconst4-trunc-column-nbits16

case "$variant" in
  m08)
    run_name=$run_suffix
    rtl="$repo_root/rtl/conv2x2/conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc-column.sv"
    manifest="$bench_dir/manifests/prefetch8-rowconst4-trunc-column-nbits16.txt"
    completion_marker=TRUNC_COLUMN_PREFETCH8_NBITS16_FPGA_FLOW_COMPLETE
    ;;
  m04)
    run_name=$run_suffix-4mac
    rtl="$repo_root/rtl/conv2x2/conv-i24-h13-t08-o4-m04-stream08-prefetch8-rowconst4-trunc-column.sv"
    manifest="$bench_dir/manifests/prefetch8-rowconst4-trunc-column-4mac-nbits16.txt"
    completion_marker=TRUNC_COLUMN_4MAC_PREFETCH8_NBITS16_FPGA_FLOW_COMPLETE
    ;;
  *) echo "variant must be m08 or m04" >&2; exit 2 ;;
esac

out="$reports_dir/$run_name"
simlib_dir="$reports_dir/simlibs_unisim"
actual_commit=$(git -C "$repo_root" rev-parse HEAD)
[[ "$actual_commit" == "$expected_commit" ]] || {
  echo "checkout HEAD $actual_commit differs from requested commit $expected_commit" >&2
  exit 3
}
git -C "$repo_root" diff --quiet HEAD -- || {
  echo "tracked files differ from the requested published commit" >&2
  exit 4
}
[[ -f "$workload" && -f "$rtl" && -f "$manifest" ]] || {
  echo "missing NBITS=16 workload, RTL, or manifest" >&2
  exit 5
}
[[ ! -e "$out" ]] || {
  echo "refusing to overwrite existing campaign directory: $out" >&2
  exit 6
}

mkdir -p "$out/dut" "$out/top" "$simlib_dir"
source /usr/share/Modules/init/bash
module purge
module use /soft64/modulefiles
module avail >"$out/module_avail.txt" 2>&1
module load xilinx/vivado/2023.2 cadence/xcelium/2303

for tool in vivado xrun python3 sha256sum; do
  command -v "$tool" >/dev/null || { echo "missing tool: $tool" >&2; exit 127; }
done

cat >"$out/provenance.txt" <<EOF
commit=$actual_commit
host=$(hostname)
vivado=$(vivado -version | head -1)
xrun=$(xrun -version 2>&1 | head -1)
part=xczu7ev-ffvc1156-2-e
top=Conv
NBITS=16
QUANT_BITS=8
target_clock_mhz=317
clock_period_ns=3.154574
workload=rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal-trunc-nbits16/pack_data.sv
rtl=${rtl#"$repo_root/"}
manifest=${manifest#"$repo_root/"}
EOF
sha256sum "$workload" "$rtl" "$manifest" \
  "$bench_dir/constraints/zcu104_317mhz.xdc" >"$out/input_hashes.sha256"
cp "$0" "$out/run_flow.sh"

vivado -mode batch -source "$common_dir/scripts/synth_impl.tcl" \
  -log "$out/implementation.vivado.log" -journal "$out/implementation.vivado.jou" \
  -tclargs "$bench_dir" "$repo_root" "$run_name" "$manifest" NBITS=16
grep -q 'Parameter NBITS bound to:.*0000000000010000' "$out/implementation.vivado.log" || {
  echo "Vivado log does not confirm top-level NBITS=16" >&2
  exit 7
}
vivado -mode batch -source "$common_dir/scripts/power_vectorless.tcl" \
  -log "$out/vectorless.vivado.log" -journal "$out/vectorless.vivado.jou" \
  -tclargs "$bench_dir" "$run_name"
vivado -mode batch -source "$common_dir/scripts/prepare_funcsim.tcl" \
  -log "$out/funcsim_prepare.vivado.log" -journal "$out/funcsim_prepare.vivado.jou" \
  -tclargs "$out/design_routed.dcp" "$out/design_routed_funcsim.v" "$simlib_dir"

vivado_exe=$(readlink -f "$(command -v vivado)")
vivado_root=$(cd -- "$(dirname -- "$vivado_exe")/.." && pwd)
glbl_v="$vivado_root/data/verilog/src/glbl.v"
[[ -f "$glbl_v" ]] || { echo "cannot locate glbl.v: $glbl_v" >&2; exit 1; }

run_capture() {
  local kind=$1 dir="$out/$1"
  cd "$dir"
  xrun -64bit -sv -access +r -cdslib "$simlib_dir/cds.lib" \
    -hdlvar "$simlib_dir/hdl.var" -reflib "$simlib_dir/unisims_ver:unisims_ver" \
    -define GATE_LEVEL -define COLUMN_IO -define NBITS16 -top tb_power -top glbl -timescale 1ns/1ps \
    -input "$common_dir/scripts/capture_${kind}_saif.tcl" -l xrun.log \
    "$repo_root/rtl/conv2x2/pack-param/tcn4/pack_param.sv" "$workload" \
    "$repo_root/rtl/mem/mem.sv" "$out/design_routed_funcsim.v" "$glbl_v" \
    "$common_dir/tb/tb_power.sv"
  [[ -s "activity_${kind}.saif" ]] || { echo "missing activity_${kind}.saif" >&2; exit 1; }
  grep -q 'POWER_RESULT PASS' xrun.log || { echo "golden PASS marker missing for $kind" >&2; exit 1; }
}

run_capture dut
run_capture top
vivado -mode batch -source "$common_dir/scripts/power_p3f.tcl" \
  -log "$out/p3f.vivado.log" -journal "$out/p3f.vivado.jou" \
  -tclargs "$bench_dir" "$run_name" \
  "$out/dut/activity_dut.saif" "$out/top/activity_top.saif"

echo "$completion_marker out=$out"
