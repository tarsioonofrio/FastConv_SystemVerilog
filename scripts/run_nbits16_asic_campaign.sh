#!/usr/bin/env bash
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
if [[ -z "${TMUX:-}" ]]; then
  echo "Run this long campaign inside tmux." >&2
  exit 2
fi

cd "$ROOT"
echo "host=$(hostname)"
echo "repo=$ROOT"
echo "commit=$(git rev-parse HEAD)"

failed=0
for arch in conv2x2 conv3x3 conv4x4; do
  mapfile -t configs < <(find "rtl/$arch/synthesis" -mindepth 1 -maxdepth 1 -type d -name '*-nbits16' -print | sort)
  for config in "${configs[@]}"; do
    [[ -d "$config" ]] || continue
    name="$(basename "$config")"
    status="$config/FLOW_STATUS_NBITS16.md"
    {
      echo "# ASIC NBITS=16 flow"
      echo
      echo "- Host: $(hostname)"
      echo "- Git commit: $(git rev-parse HEAD)"
      echo "- Started: $(date --iso-8601=seconds)"
      echo "- Configuration: $config"
    } > "$status"
    echo "START $arch/$name"

    for stage in logical sim power; do
      log="$config/$stage/nbits16_flow.log"
      if [[ ! -x "$config/$stage/run.sh" && ! -f "$config/$stage/run.sh" ]]; then
        echo "- $stage: MISSING runner" >> "$status"
        echo "FAIL $arch/$name $stage runner-missing"
        failed=1
        break
      fi
      if (cd "$config/$stage" && bash run.sh </dev/null) >"$log" 2>&1; then
        echo "- $stage: PASS ($(date --iso-8601=seconds))" >> "$status"
        echo "PASS $arch/$name $stage"
      else
        rc=$?
        echo "- $stage: FAIL (exit $rc; $(date --iso-8601=seconds))" >> "$status"
        echo "FAIL $arch/$name $stage exit=$rc"
        failed=1
        break
      fi
    done
    echo "- Finished: $(date --iso-8601=seconds)" >> "$status"
  done
done

if [[ "$failed" -ne 0 ]]; then
  echo "Campaign finished with failures; inspect FLOW_STATUS_NBITS16.md and stage logs." >&2
  exit 1
fi
echo "Campaign completed: all 24 configurations passed logical, sim, and power."
