#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS=(
  "$SCRIPT_DIR/asic-stream-column-20261003-tcn16-m12"
  "$SCRIPT_DIR/asic-stream-column-20261003-tcn16-m18"
)

for config in "${CONFIGS[@]}"; do
  printf '\n=== ASIC flow: %s ===\n' "$(basename "$config")"
  (cd "$config/logical" && ./run.sh)
  (cd "$config/sim" && ./run.sh)
  (cd "$config/power" && ./run.sh)
  printf 'ASIC_FLOW_COMPLETE config=%s\n' "$(basename "$config")"
done

printf 'ASIC_CAMPAIGN_COMPLETE configs=%s,%s\n' \
  "$(basename "${CONFIGS[0]}")" "$(basename "${CONFIGS[1]}")"
