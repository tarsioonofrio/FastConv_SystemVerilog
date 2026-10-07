#!/usr/bin/env bash
set -euo pipefail

root=/sim/tarsio/fastconv-exact-pipelined-d031bbaa
bench="$root/rtl/conv2x2/fpga_zcu104/stream08_pipeline_campaign"
common="$root/rtl/conv2x2/fpga_zcu104/column_power_comparison"
run=exact-pipelined
out="$bench/reports/$run"
simlib="$bench/reports/simlibs_unisim"
workload="$root/rtl/conv2x2/data/archive/tcn4/sim/sim-032-3-3-normal-exact/pack_data.sv"
rtl="$root/rtl/conv2x2/archive/m08/conv-i16-h13-t08-o4-m08-stream08-rowconst4-exact-pipelined.sv"

source /usr/share/Modules/init/bash
module purge
module use /soft64/modulefiles
module load xilinx/vivado/2023.2 cadence/xcelium/2303

for tool in vivado xrun python3 sha256sum; do
  command -v "$tool" >/dev/null || { echo "missing tool: $tool" >&2; exit 127; }
done

mkdir -p "$out/dut" "$out/top"
cat > "$out/manifest.txt" <<EOF
rtl/conv2x2/pack-param/tcn4/pack_param.sv
rtl/csa/csa_lib.sv
rtl/multip/multip.sv
rtl/conv2x2/mult-matrices/stream/tcn4/mult_matrices.sv
rtl/conv2x2/archive/m08/conv-i16-h13-t08-o4-m08-stream08-rowconst4-exact-pipelined.sv
EOF

cat > "$out/provenance.txt" <<EOF
commit=$(git -C "$root" rev-parse HEAD)
host=$(hostname)
vivado=$(vivado -version | head -1)
xrun=$(xrun -version 2>&1 | head -1)
part=xczu7ev-ffvc1156-2-e
target_clock_mhz=317
clock_period_ns=3.154574
workload=rtl/conv2x2/data/archive/tcn4/sim/sim-032-3-3-normal-exact/pack_data.sv
rtl=rtl/conv2x2/archive/m08/conv-i16-h13-t08-o4-m08-stream08-rowconst4-exact-pipelined.sv
EOF
sha256sum "$workload" "$rtl" > "$out/input_hashes.sha256"
cp "$0" "$out/run_flow.sh"

vivado -mode batch -source "$common/scripts/synth_impl.tcl" \
  -log "$out/implementation.vivado.log" -journal "$out/implementation.vivado.jou" \
  -tclargs "$bench" "$root" "$run" "$out/manifest.txt"
vivado -mode batch -source "$common/scripts/power_vectorless.tcl" \
  -log "$out/vectorless.vivado.log" -journal "$out/vectorless.vivado.jou" \
  -tclargs "$bench" "$run"
vivado -mode batch -source "$common/scripts/prepare_funcsim.tcl" \
  -log "$out/funcsim_prepare.vivado.log" -journal "$out/funcsim_prepare.vivado.jou" \
  -tclargs "$out/design_routed.dcp" "$out/design_routed_funcsim.v" "$simlib"

vivado_exe=$(readlink -f "$(command -v vivado)")
vivado_root=$(cd -- "$(dirname -- "$vivado_exe")/.." && pwd)
glbl_v="$vivado_root/data/verilog/src/glbl.v"
[[ -f "$glbl_v" ]] || { echo "cannot locate glbl.v: $glbl_v" >&2; exit 1; }

run_capture() {
  local kind=$1 dir="$out/$1"
  cd "$dir"
  xrun -64bit -sv -access +r -cdslib "$simlib/cds.lib" \
    -hdlvar "$simlib/hdl.var" -reflib "$simlib/unisims_ver:unisims_ver" \
    -define GATE_LEVEL -top tb_power -top glbl -timescale 1ns/1ps \
    -input "$common/scripts/capture_${kind}_saif.tcl" -l xrun.log \
    "$root/rtl/conv2x2/pack-param/tcn4/pack_param.sv" "$workload" \
    "$root/rtl/mem/mem.sv" "$out/design_routed_funcsim.v" "$glbl_v" \
    "$common/tb/tb_power.sv"
  [[ -s "activity_${kind}.saif" ]] || { echo "missing activity_${kind}.saif" >&2; exit 1; }
  grep -q 'POWER_RESULT PASS' xrun.log || { echo "golden PASS marker missing for $kind" >&2; exit 1; }
}

run_capture dut
run_capture top
vivado -mode batch -source "$common/scripts/power_p3f.tcl" \
  -log "$out/p3f.vivado.log" -journal "$out/p3f.vivado.jou" \
  -tclargs "$bench" "$run" "$out/dut/activity_dut.saif" "$out/top/activity_top.saif"

echo "EXACT_PIPELINED_FPGA_FLOW_COMPLETE out=$out"
