#!/usr/bin/env bash
set -uo pipefail

REPO_ROOT="${1:-$(git rev-parse --show-toplevel)}"
OUT_ROOT="${2:?usage: run_asic_sweep.sh REPO_ROOT OUT_ROOT}"
COMMIT="$(git -C "$REPO_ROOT" rev-parse HEAD)"
mkdir -p "$OUT_ROOT"

source /usr/share/Modules/init/bash
module purge
module use /soft64/modulefiles

printf 'host=%s\ncommit=%s\nrepo=%s\nstarted=%s\n' \
  "$(hostname)" "$COMMIT" "$REPO_ROOT" "$(date -Is)" >"$OUT_ROOT/campaign.txt"

configs=(
  rtl/conv3x3/asic_configs/conv/asic-sweep-20261003-ifn9-m06
  rtl/conv3x3/asic_configs/conv/asic-sweep-20261003-ifn9-m12
  rtl/conv3x3/asic_configs/conv/asic-sweep-20261003-ifn9-m18
  rtl/conv3x3/asic_configs/conv/asic-sweep-20261003-tcn9-m05
  rtl/conv4x4/asic_configs/conv/asic-sweep-20261003-tcn16-m06
  rtl/conv4x4/asic_configs/conv/asic-sweep-20261003-tcn16-m12
  rtl/conv4x4/asic_configs/conv/asic-sweep-20261003-tcn16-m18
  rtl/conv4x4/asic_configs/conv/asic-sweep-20261003-wpn16-m08
  rtl/conv4x4/asic_configs/conv/asic-sweep-20261003-wpn16-m16
  rtl/conv4x4/asic_configs/conv/asic-sweep-20261003-wpn16-m32
)

failures=0
start_from="${ASIC_SWEEP_START_FROM:-}"
start_found=0
if [[ -z "$start_from" ]]; then
  start_found=1
fi

for relative in "${configs[@]}"; do
  tag="${relative##*/}"
  if (( ! start_found )); then
    if [[ "$tag" == "$start_from" ]]; then
      start_found=1
    else
      continue
    fi
  fi

  config="$REPO_ROOT/$relative"
  result="$OUT_ROOT/$tag"
  mkdir -p "$result"
  top_module="$(awk 'NF && $1 !~ /^#/ {print $1; exit}' "$config/top-module.txt")"
  top_module="${top_module:-Conv}"
  mapped_netlist="$config/logical/results/gate_level/${top_module}_logic_mapped.v"
  nominal_sdf="$config/logical/results/gate_level/${top_module}_analysis_view_0p90v_25c_captyp_nominal.sdf"
  nominal_sdf_basename="${top_module}_analysis_view_0p90v_25c_captyp_nominal.sdf"
  area_report="$config/logical/results/reports/${top_module}_area.rpt"
  timing_report="$config/logical/results/reports/${top_module}_timing_setup_analysis_view_0p90v_25c_captyp_nominal.rpt"
  printf '\n[%s] %s\n' "$(date -Is)" "$tag" | tee -a "$OUT_ROOT/campaign.txt"

  expected_num="$((10#${tag##*-m}))"
  parameters_file="$config/top-parameters.txt"
  mux_entry="$(grep -E '(^|/)mux_mult_[0-9]+\.sv$' "$config/list-file.txt" | tail -n 1)"
  mux_file="$REPO_ROOT/$mux_entry"
  configured_num="$(sed -nE 's/^NUM_MULT=([0-9]+)$/\1/p' "$parameters_file" 2>/dev/null | tail -n 1)"
  configured_state="$(sed -nE 's/^STATE_MULT=([0-9]+)$/\1/p' "$parameters_file" 2>/dev/null | tail -n 1)"
  configured_output_size="$(sed -nE 's/^CONV_OUTPUT_SIZE=([0-9]+)$/\1/p' "$parameters_file" 2>/dev/null | tail -n 1)"
  configured_input_size="$(sed -nE 's/^CONV_INPUT_SIZE=([0-9]+)$/\1/p' "$parameters_file" 2>/dev/null | tail -n 1)"
  configured_hadamard_size="$(sed -nE 's/^HADAMARD_SIZE=([0-9]+)$/\1/p' "$parameters_file" 2>/dev/null | tail -n 1)"
  mux_num="$(sed -nE 's/.*parameter int NUM_MULT = ([0-9]+);/\1/p' "$mux_file" 2>/dev/null | head -n 1)"
  mux_state="$(sed -nE 's/.*parameter int STATE_MULT = ([0-9]+);/\1/p' "$mux_file" 2>/dev/null | head -n 1)"
  case "$tag" in
    *-ifn9-*) expected_geometry="3 5 6" ;;
    *-tcn9-*) expected_geometry="3 5 5" ;;
    *-tcn16-*) expected_geometry="4 6 6" ;;
    *-wpn16-*) expected_geometry="4 6 8" ;;
    *) expected_geometry="" ;;
  esac
  configured_geometry="$configured_output_size $configured_input_size $configured_hadamard_size"
  if [[ -z "$mux_entry" || -z "$configured_num" || -z "$configured_state" ||
        "$configured_num" != "$expected_num" || "$configured_num" != "$mux_num" ||
        "$configured_state" != "$mux_state" ||
        -z "$expected_geometry" || "$configured_geometry" != "$expected_geometry" ]]; then
    printf 'configuration=FAIL_PARAMS expected_NUM_MULT=%s config_NUM_MULT=%s mux_NUM_MULT=%s config_STATE_MULT=%s mux_STATE_MULT=%s expected_geometry="%s" config_geometry="%s"\n' \
      "$expected_num" "${configured_num:-missing}" "${mux_num:-missing}" \
      "${configured_state:-missing}" "${mux_state:-missing}" "$expected_geometry" "$configured_geometry" \
      | tee -a "$result/status.txt" "$OUT_ROOT/campaign.txt"
    failures=$((failures + 1))
    continue
  fi

  if (cd "$config/logical" && ./run.sh) >"$result/logical.log" 2>&1; then
    printf 'logical=PASS\n' | tee -a "$result/status.txt"
  else
    rc=$?
    printf 'logical=FAIL rc=%s\n' "$rc" | tee -a "$result/status.txt" "$OUT_ROOT/campaign.txt"
    failures=$((failures + 1))
    continue
  fi

  if [[ ! -s "$mapped_netlist" || ! -s "$nominal_sdf" ]]; then
    printf 'logical=FAIL missing mapped netlist or nominal SDF\n' | tee -a "$result/status.txt" "$OUT_ROOT/campaign.txt"
    failures=$((failures + 1))
    continue
  fi

  if (cd "$config/sim" && ./run.sh) >"$result/sim.log" 2>&1; then
    if [[ "$tag" == *-ifn9-* || "$tag" == *-tcn9-* ]]; then
      if ! grep -Eq '^Total de erros de escrita de output: 0$' "$result/sim.log"; then
        printf 'sim=FAIL_GOLDEN missing zero-error 3x3 golden result\n' | tee -a "$result/status.txt" "$OUT_ROOT/campaign.txt"
        failures=$((failures + 1))
        continue
      fi
    else
      if ! grep -Fq '4x4 simulation passed:' "$result/sim.log"; then
        printf 'sim=FAIL_GOLDEN missing 4x4 golden PASS marker\n' | tee -a "$result/status.txt" "$OUT_ROOT/campaign.txt"
        failures=$((failures + 1))
        continue
      fi
    fi

    if ! grep -Eq 'valid_writes=8100([[:space:]]|$)' "$result/sim.log"; then
      printf 'sim=FAIL_GOLDEN expected valid_writes=8100 not found\n' | tee -a "$result/status.txt" "$OUT_ROOT/campaign.txt"
      failures=$((failures + 1))
      continue
    fi

  else
    rc=$?
    printf 'sim=FAIL rc=%s\n' "$rc" | tee -a "$result/status.txt" "$OUT_ROOT/campaign.txt"
    failures=$((failures + 1))
    continue
  fi

  if ! grep -Fq "Reading SDF file from location \"../logical/results/gate_level/$nominal_sdf_basename\"" "$result/sim.log" ||
     ! grep -Fq "Compiled SDF file:     ${nominal_sdf_basename}.X" "$result/sim.log" ||
     ! grep -Fq 'Backannotation scope:  tb.dut' "$result/sim.log" ||
     [[ ! -s "$config/sim/sdf_log.log" ]]; then
    printf 'sim=FAIL_SDF annotation evidence missing\n' | tee -a "$result/status.txt" "$OUT_ROOT/campaign.txt"
    failures=$((failures + 1))
    continue
  fi

  sdf_warnings="$(grep -Ec 'xmelab: \*W,(SDF|FLF)' "$result/sim.log" || true)"
  printf 'sim=PASS golden=PASS valid_writes=8100 sdf_compiled=PASS sdf_warnings=%s\n' "$sdf_warnings" \
    | tee -a "$result/status.txt" "$OUT_ROOT/campaign.txt"

  if (cd "$config/power" && ./run.sh) >"$result/power.log" 2>&1; then
    printf 'power=PASS\n' | tee -a "$result/status.txt"
    cp "$config/power/power_evaluation.txt" "$result/power_evaluation.txt"
    cp "$area_report" "$result/area.rpt"
    cp "$timing_report" "$result/timing_typical.rpt"
  else
    rc=$?
    printf 'power=FAIL rc=%s\n' "$rc" | tee -a "$result/status.txt" "$OUT_ROOT/campaign.txt"
    failures=$((failures + 1))
  fi
done

if (( ! start_found )); then
  printf 'error=start tag not found: %s\n' "$start_from" | tee -a "$OUT_ROOT/campaign.txt"
  failures=$((failures + 1))
fi

printf 'finished=%s\nfailures=%s\n' "$(date -Is)" "$failures" | tee -a "$OUT_ROOT/campaign.txt"
exit "$((failures > 0))"
