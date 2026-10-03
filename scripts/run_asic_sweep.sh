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
  rtl/conv3x3/synthesis/asic-sweep-20261003-ifn9-m06
  rtl/conv3x3/synthesis/asic-sweep-20261003-ifn9-m12
  rtl/conv3x3/synthesis/asic-sweep-20261003-ifn9-m18
  rtl/conv3x3/synthesis/asic-sweep-20261003-tcn9-m05
  rtl/conv4x4/synthesis/asic-sweep-20261003-tcn16-m06
  rtl/conv4x4/synthesis/asic-sweep-20261003-tcn16-m12
  rtl/conv4x4/synthesis/asic-sweep-20261003-tcn16-m18
  rtl/conv4x4/synthesis/asic-sweep-20261003-wpn16-m08
  rtl/conv4x4/synthesis/asic-sweep-20261003-wpn16-m16
  rtl/conv4x4/synthesis/asic-sweep-20261003-wpn16-m32
)

failures=0
for relative in "${configs[@]}"; do
  config="$REPO_ROOT/$relative"
  tag="${relative##*/}"
  result="$OUT_ROOT/$tag"
  mkdir -p "$result"
  printf '\n[%s] %s\n' "$(date -Is)" "$tag" | tee -a "$OUT_ROOT/campaign.txt"

  if (cd "$config/logical" && ./run.sh) >"$result/logical.log" 2>&1; then
    printf 'logical=PASS\n' | tee -a "$result/status.txt"
  else
    rc=$?
    printf 'logical=FAIL rc=%s\n' "$rc" | tee -a "$result/status.txt" "$OUT_ROOT/campaign.txt"
    failures=$((failures + 1))
    continue
  fi

  if [[ ! -s "$config/logical/results/gate_level/conv_logic_mapped.v" ||
        ! -s "$config/logical/results/gate_level/conv_analysis_view_0p90v_25c_captyp_nominal.sdf" ]]; then
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

    printf 'sim=PASS golden=PASS valid_writes=8100\n' | tee -a "$result/status.txt"
  else
    rc=$?
    printf 'sim=FAIL rc=%s\n' "$rc" | tee -a "$result/status.txt" "$OUT_ROOT/campaign.txt"
    failures=$((failures + 1))
    continue
  fi

  if (cd "$config/power" && ./run.sh) >"$result/power.log" 2>&1; then
    printf 'power=PASS\n' | tee -a "$result/status.txt"
    cp "$config/power/power_evaluation.txt" "$result/power_evaluation.txt"
    cp "$config/logical/results/reports/conv_area.rpt" "$result/area.rpt"
    cp "$config/logical/results/reports/conv_timing_setup_analysis_view_0p90v_25c_captyp_nominal.rpt" "$result/timing_typical.rpt"
  else
    rc=$?
    printf 'power=FAIL rc=%s\n' "$rc" | tee -a "$result/status.txt" "$OUT_ROOT/campaign.txt"
    failures=$((failures + 1))
  fi
done

printf 'finished=%s\nfailures=%s\n' "$(date -Is)" "$failures" | tee -a "$OUT_ROOT/campaign.txt"
exit "$((failures > 0))"
