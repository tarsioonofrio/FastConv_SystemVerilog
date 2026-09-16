#!/usr/bin/env bash
set -euo pipefail

# Generate behavioral/RTL SAIF for import into a post-route Vivado checkpoint.
# Verilator's native SAIF tracer is used here because XSim's RTL elaborator and
# timing elaborator both hit an internal LLVM assertion on this design. This is
# intentionally separate from timing-SDF simulation: RTL-derived SAIF is a
# supported activity source for report_power, while timing-SAIF remains an
# optional higher-fidelity experiment.
script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
bench_dir=$(cd -- "$script_dir/.." && pwd)
repo_root=$(cd -- "$bench_dir/../../../.." && pwd)
run_dir="$bench_dir/reports/rtl_saif"
pack_data="$repo_root/rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv"

for tool in verilator; do
  command -v "$tool" >/dev/null || {
    printf 'required tool not found: %s\n' "$tool" >&2
    exit 127
  }
done

[[ -f "$pack_data" ]] || {
  printf 'missing generated workload package: %s\n' "$pack_data" >&2
  exit 1
}

mkdir -p "$run_dir"
rm -rf "$run_dir/obj" "$run_dir/activity_rtl.saif"
cd "$run_dir"

mapfile -t sources < <(awk '
  /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
  { print }
' "$bench_dir/rtl_manifest.txt")
absolute_sources=()
for source in "${sources[@]}"; do
  absolute_sources+=("$repo_root/$source")
done

verilator -j 0 --binary --timing --trace-saif --trace-structs -DSAIF_CAPTURE \
  --top-module tb_power -Wno-fatal --Mdir "$run_dir/obj" \
  "${absolute_sources[@]}" "$bench_dir/tb/tb_power.sv" \
  --exe "$script_dir/verilator_saif_main.cpp" --build >verilator.log 2>&1
./obj/Vtb_power >workload.log 2>&1

# Vivado's SAIF reader expects a DESIGN header in the IEEE-1800 form. Verilator
# emits PROGRAM_NAME instead, so normalize only that header field; the signal
# activity and hierarchy remain unchanged.
sed -i 's/(PROGRAM_NAME "Verilator")/(DESIGN "tb_power")/' activity_rtl.saif
sed -i '/(DESIGN "tb_power")/a\
(DATE "2026-09-16")\
(VENDOR "Verilator")\
(PROGRAM_NAME "Verilator")\
(VERSION "5.050")' activity_rtl.saif

[[ -s activity_rtl.saif ]] || {
  printf 'RTL Verilator run completed without a non-empty activity_rtl.saif\n' >&2
  exit 1
}
printf 'RTL_SAIF_COMPLETE file=%s\n' "$run_dir/activity_rtl.saif"
