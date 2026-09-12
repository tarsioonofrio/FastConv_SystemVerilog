#!/usr/bin/env bash
set -euo pipefail

SIM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$(cd "$SIM_ROOT/.." && pwd)"
GIT_ROOT="$(git -C "$CONFIG_ROOT" rev-parse --show-toplevel)"

source /usr/share/Modules/init/bash
module purge
module use /soft64/modulefiles
module load cadence/xcelium/2303 > /dev/null 2>&1

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
    if [[ "$line" = /* ]]; then files+=("$line"); else files+=("$GIT_ROOT/$line"); fi
done < "$CONFIG_ROOT/list-file.txt"

xrun -f "$SIM_ROOT/args.txt" "${files[@]}" "$TB" "$GATE" \
    -f "$CONFIG_ROOT/list-define.txt" -define GATE_LEVEL -define XRUN -run -exit
