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

# Keep the capture metadata next to the SAIF and regenerate the primary-port
# activity artifacts from exactly this directed window.
python3 "$script_dir/extract_saif_activity.py" \
  "$run_dir/activity_rtl.saif" \
  --clock-period-ps 3154.0 \
  --json "$run_dir/primary_activity.json" \
  --tcl "$script_dir/primary_activity.tcl"
python3 - "$run_dir" <<'PY'
import re
import sys
from pathlib import Path

run_dir = Path(sys.argv[1])
workload = (run_dir / "workload.log").read_text(errors="replace")
capture_line = next((line for line in workload.splitlines()
                     if line.startswith("SAIF_CAPTURE ")), "")
workload_line = next((line for line in workload.splitlines()
                      if line.startswith("POWER_WORKLOAD ")), "")
values = dict(re.findall(r"(\w+)=([^\s]+)", capture_line))
job = dict(re.findall(r"(\w+)=([^\s]+)", workload_line))
duration_match = re.search(r"\(DURATION\s+(\d+)\)",
                           (run_dir / "activity_rtl.saif").read_text(errors="replace"))
duration_ps = int(duration_match.group(1)) if duration_match else None
period_ps = float(values["clock_period_ps"])
nominal_period_ps = float(values["nominal_clock_period_ps"])
captured_cycles = float(values["captured_cycles"])
summary = f"""# Captura RTL-SAIF a 317 MHz

| Campo | Valor |
| --- | --- |
| Frequência do clock | `{values.get('clock_frequency_mhz', '317')} MHz` |
| Período nominal do alvo | `{nominal_period_ps:g} ps` |
| Período efetivo na simulação | `{period_ps:g} ps` |
| Frequência efetiva na simulação | `{values.get('simulated_clock_frequency_mhz', 'N/A')} MHz` |
| Início da captura | `{values.get('capture_start_ps')} ps` |
| Fim da captura | `{values.get('capture_end_ps')} ps` |
| Duração da captura | `{values.get('capture_duration_ps')} ps` |
| Duração no cabeçalho SAIF | `{duration_ps} ps` |
| Ciclos capturados | `{captured_cycles:.3f}` |
| Latência do job | `{job.get('latency_cycles', 'N/A')} ciclos` |
| Jobs | `{job.get('jobs', 'N/A')}` |
| Tile ends | `{job.get('tile_ends', 'N/A')}` |
| Tile II | `{job.get('tile_ii_cycles', 'N/A')} ciclos` |
| VCD | não gerado |

A captura é dirigida pelo protocolo: começa quando `p_start` é observado e
termina quando o testbench registra `p_end` (`jobs_completed > 0`). O limite de `200000000 ps` existe
somente como timeout de segurança e não define a duração normal da captura.

O período nominal é o operating point de 317 MHz (`3.154574 ns`). O SAIF
deve ser importado no checkpoint correspondente somente depois de verificar
que os ciclos capturados estão próximos da latência esperada de `23648` ciclos.
"""
(run_dir / "capture_summary.md").write_text(summary)
PY
printf 'RTL_SAIF_COMPLETE file=%s\n' "$run_dir/activity_rtl.saif"
