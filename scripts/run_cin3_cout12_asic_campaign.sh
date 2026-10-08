#!/usr/bin/env bash
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

if [[ -z "${TMUX:-}" ]]; then
  echo "Run this long ASIC campaign inside tmux." >&2
  exit 2
fi

configs=(
  rtl/conv2x2/synthesis/*-cin3-cout12
  rtl/conv3x3/synthesis/*-cin3-cout12
  rtl/conv4x4/synthesis/*-cin3-cout12
)
if [[ ! -d "${configs[0]}" ]]; then
  echo "No Cin=3/Cout=12 campaign configurations found." >&2
  exit 2
fi

status_file=rtl/CIN3_COUT12_ASIC_CAMPAIGN_STATUS.tsv
printf 'config\tstarted\tfinished\texit_code\tstatus\n' > "$status_file"
failed=0

for config in "${configs[@]}"; do
  [[ -d "$config" ]] || continue
  arch="$(basename "$(dirname "$(dirname "$config")")")"
  name="$(basename "$config")"
  started="$(date --iso-8601=seconds)"
  log="$config/cin3_cout12_flow.log"
  echo "===== START $arch / $name at $started ====="

  printf 'host=%s\ncommit=%s\n' "$(hostname)" "$(git rev-parse HEAD)" > "$log"
  rc=0
  for stage in logical sim power; do
    echo "===== STAGE $stage: $arch / $name =====" | tee -a "$log"
    (cd "$ROOT/$config/$stage" && bash run.sh </dev/null) 2>&1 | tee -a "$log"
    stage_rc=${PIPESTATUS[0]}
    if (( stage_rc != 0 )); then
      rc=$stage_rc
      echo "===== FAILED STAGE $stage (exit $rc) =====" | tee -a "$log"
      break
    fi
  done
  finished="$(date --iso-8601=seconds)"
  if (( rc == 0 )); then
    result=PASS
  else
    result=FAIL
    failed=1
  fi
  printf '%s\t%s\t%s\t%d\t%s\n' \
    "$config" "$started" "$finished" "$rc" "$result" >> "$status_file"
  echo "===== END $arch / $name: $result (exit $rc) at $finished ====="
done

if (( failed )); then
  echo "One or more configurations failed; inspect $status_file and per-config logs." >&2
  exit 1
fi
echo "All Cin=3/Cout=12 power flows passed. Status: $status_file"
