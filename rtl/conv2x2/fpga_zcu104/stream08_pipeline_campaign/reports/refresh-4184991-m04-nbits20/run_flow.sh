#!/usr/bin/env bash
set -euo pipefail

repo_root=${1:?repository snapshot root required}
bench_dir="$repo_root/rtl/conv2x2/fpga_zcu104/stream08_pipeline_campaign"
common_dir="$repo_root/rtl/conv2x2/fpga_zcu104/column_power_comparison"
reports_dir="$bench_dir/reports"
simlib_dir="$reports_dir/simlibs_unisim"
vivado=vivado
xrun=xrun
commit=4184991c425803b5bd11adc591b864e6a876b5eb
script_path=$(readlink -f "$0")

[[ -n "${TMUX:-}" ]] || { echo 'must run inside tmux' >&2; exit 2; }
source /usr/share/Modules/init/bash
module purge
module use /soft64/modulefiles
module load xilinx/vivado/2023.2 cadence/xcelium/2303

command -v "$vivado" >/dev/null
command -v "$xrun" >/dev/null
mkdir -p "$reports_dir" "$simlib_dir"
vivado_exe=$(readlink -f "$(command -v "$vivado")")
vivado_root=$(cd -- "$(dirname -- "$vivado_exe")/.." && pwd)
glbl_v="$vivado_root/data/verilog/src/glbl.v"
[[ -f "$glbl_v" ]]

run_one() {
  local variant=$1 width=$2 rtl_file=$3 manifest_file=$4 workload_file=$5
  local generic=${6:-} define16=${7:-no}
  local run_name="refresh-4184991-${variant}-nbits${width}"
  local out="$reports_dir/$run_name"
  if [[ -e "$out" ]]; then
    if [[ -s "$out/power_p3f_typical.rpt" && -s "$out/power_p3f_maximum.rpt" ]] && \
       grep -q 'POWER_RESULT PASS' "$out/dut/xrun.log" 2>/dev/null && \
       grep -q 'POWER_RESULT PASS' "$out/top/xrun.log" 2>/dev/null; then
      echo "REFRESH_FLOW_ALREADY_COMPLETE $run_name"
      return 0
    fi
    if [[ -e "$out/implementation.vivado.log" || -e "$out/design_synth.dcp" || -e "$out/design_routed.dcp" ]]; then
      echo "refuse overwrite partial implementation: $out" >&2
      return 6
    fi
    echo "RESUME_EMPTY_OUTPUT_DIRECTORY $run_name"
  fi
  mkdir -p "$out/dut" "$out/top"
  {
    echo "commit=$commit"
    echo "host=$(hostname)"
    echo "vivado=$(vivado -version | head -1)"
    echo "xrun=$(xrun -version 2>&1 | head -1)"
    echo "part=xczu7ev-ffvc1156-2-e"
    echo "target_clock_mhz=317"
    echo "clock_period_ns=3.154574"
    echo "variant=$variant"
    echo "NBITS=$width"
    echo "rtl=$rtl_file"
    echo "manifest=$manifest_file"
    echo "workload=$workload_file"
  } >"$out/provenance.txt"
  sha256sum "$repo_root/$rtl_file" "$repo_root/$manifest_file" \
    "$repo_root/$workload_file" "$bench_dir/constraints/zcu104_317mhz.xdc" \
    >"$out/input_hashes.sha256"
  cp "$script_path" "$out/run_flow.sh"

  local -a synth_args=("$bench_dir" "$repo_root" "$run_name" "$repo_root/$manifest_file")
  [[ -z "$generic" ]] || synth_args+=("$generic")
  "$vivado" -mode batch -source "$common_dir/scripts/synth_impl.tcl" \
    -log "$out/implementation.vivado.log" -journal "$out/implementation.vivado.jou" \
    -tclargs "${synth_args[@]}"
  "$vivado" -mode batch -source "$common_dir/scripts/power_vectorless.tcl" \
    -log "$out/vectorless.vivado.log" -journal "$out/vectorless.vivado.jou" \
    -tclargs "$bench_dir" "$run_name"
  "$vivado" -mode batch -source "$common_dir/scripts/prepare_funcsim.tcl" \
    -log "$out/funcsim_prepare.vivado.log" -journal "$out/funcsim_prepare.vivado.jou" \
    -tclargs "$out/design_routed.dcp" "$out/design_routed_funcsim.v" "$simlib_dir"

  local kind dir
  for kind in dut top; do
    dir="$out/$kind"
    cd "$dir"
    local -a defines=(-define GATE_LEVEL -define COLUMN_IO)
    [[ "$define16" != yes ]] || defines+=(-define NBITS16)
    "$xrun" -64bit -sv -access +r -cdslib "$simlib_dir/cds.lib" \
      -hdlvar "$simlib_dir/hdl.var" -reflib "$simlib_dir/unisims_ver:unisims_ver" \
      "${defines[@]}" -top tb_power -top glbl -timescale 1ns/1ps \
      -input "$common_dir/scripts/capture_${kind}_saif.tcl" -l xrun.log \
      "$repo_root/rtl/conv2x2/pack-param/tcn4/pack_param.sv" \
      "$repo_root/$workload_file" "$repo_root/rtl/mem/mem.sv" \
      "$out/design_routed_funcsim.v" "$glbl_v" "$common_dir/tb/tb_power.sv"
    [[ -s "activity_${kind}.saif" ]]
    grep -q 'POWER_RESULT PASS' xrun.log
  done
  "$vivado" -mode batch -source "$common_dir/scripts/power_p3f.tcl" \
    -log "$out/p3f.vivado.log" -journal "$out/p3f.vivado.jou" \
    -tclargs "$bench_dir" "$run_name" \
    "$out/dut/activity_dut.saif" "$out/top/activity_top.saif"
  echo "complete" >"$out/flow_complete"
  echo "REFRESH_FLOW_COMPLETE $run_name"
}

run_one m08 20 \
  rtl/conv2x2/conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc-column.sv \
  rtl/conv2x2/fpga_zcu104/stream08_pipeline_campaign/manifests/prefetch8-rowconst4-trunc-column.txt \
  rtl/conv2x2/data/archive/tcn4/sim/sim-032-3-3-normal-trunc/pack_data.sv
run_one m04 20 \
  rtl/conv2x2/conv-i24-h13-t08-o4-m04-stream08-prefetch8-rowconst4-trunc-column.sv \
  rtl/conv2x2/fpga_zcu104/stream08_pipeline_campaign/manifests/prefetch8-rowconst4-trunc-column-4mac.txt \
  rtl/conv2x2/data/archive/tcn4/sim/sim-032-3-3-normal-trunc/pack_data.sv
run_one m08 16 \
  rtl/conv2x2/conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc-column.sv \
  rtl/conv2x2/fpga_zcu104/stream08_pipeline_campaign/manifests/prefetch8-rowconst4-trunc-column-nbits16.txt \
  rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal-trunc-nbits16/pack_data.sv NBITS=16 yes
run_one m04 16 \
  rtl/conv2x2/conv-i24-h13-t08-o4-m04-stream08-prefetch8-rowconst4-trunc-column.sv \
  rtl/conv2x2/fpga_zcu104/stream08_pipeline_campaign/manifests/prefetch8-rowconst4-trunc-column-4mac-nbits16.txt \
  rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal-trunc-nbits16/pack_data.sv NBITS=16 yes

echo 'ALL_REFRESH_FLOWS_COMPLETE'
