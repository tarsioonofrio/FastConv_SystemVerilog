#!/usr/bin/env bash
set -euo pipefail

SIM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$(cd "$SIM_ROOT/.." && pwd)"
GIT_ROOT="$(git -C "$CONFIG_ROOT" rev-parse --show-toplevel)"

module purge
module load xcelium > /dev/null 2>&1

TB_ENTRY="$(awk 'NF && $1 !~ /^#/ {print $1; exit}' "$CONFIG_ROOT/testbench-file.txt")"
if [[ -z "$TB_ENTRY" ]]; then
    echo "testbench-file.txt is empty" >&2
    exit 2
fi
if [[ "$TB_ENTRY" = /* ]]; then TB="$TB_ENTRY"; else TB="$GIT_ROOT/$TB_ENTRY"; fi

TOP_MODULE="$(awk 'NF && $1 !~ /^#/ {print $1; exit}' "$CONFIG_ROOT/top-module.txt")"
TOP_MODULE="${TOP_MODULE:-system}"
GATE="$CONFIG_ROOT/logical/results/gate_level/${TOP_MODULE}_logic_mapped.v"

files=()
while IFS= read -r line; do
    line="${line##[[:space:]]}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    # The mapped gate-level top is added below.  Do not compile the RTL top
    # from list-file.txt as well, otherwise duplicate Conv definitions make
    # Xcelium elaborate the wrong hierarchy for SDF back-annotation.
    if [[ "$(basename "$line")" == "${TOP_MODULE}.sv" ]]; then
        continue
    fi
    if [[ "$line" = /* ]]; then files+=("$line"); else files+=("$GIT_ROOT/$line"); fi
done < "$CONFIG_ROOT/list-file.txt"

xrun -f "$SIM_ROOT/args.txt" "${files[@]}" "$TB" "$GATE" \
    -f "$CONFIG_ROOT/list-define.txt" -define GATE_LEVEL -define XRUN -run -exit
