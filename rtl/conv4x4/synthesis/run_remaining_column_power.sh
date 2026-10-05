#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS=(
  "$SCRIPT_DIR/conv-tcn16-i60-h15-t12-o16-m06-stream12-prefetch24-rowconst6-trunc-column"
  "$SCRIPT_DIR/conv-tcn16-i60-h21-t24-o16-m12-stream12-prefetch24-rowconst6-trunc-column"
  "$SCRIPT_DIR/conv-wpn16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8-trunc-column"
  "$SCRIPT_DIR/conv-wpn16-i60-h25-t32-o16-m16-stream16-prefetch24-rowconst8-trunc-column"
)
for config in "${CONFIGS[@]}"; do
  [[ -d "$config" ]] || { echo "Missing config: $config" >&2; exit 2; }
  printf '\n=== Full ASIC power flow: %s ===\n' "$(basename "$config")"
  (cd "$config/logical" && bash ./run.sh)
  (cd "$config/sim" && bash ./run.sh)
  (cd "$config/power" && bash ./run.sh)
  printf 'ASIC_POWER_FLOW_COMPLETE config=%s\n' "$(basename "$config")"
done
printf 'ASIC_POWER_CAMPAIGN_COMPLETE count=%d\n' "${#CONFIGS[@]}"
