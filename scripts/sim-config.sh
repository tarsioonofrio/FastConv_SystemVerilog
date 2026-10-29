#!/usr/bin/env bash
# RTL simulation (Verilator) of one ASIC configuration with its own sources, defines, parameters and golden:
#   scripts/sim-config.sh <arch> <configuration-directory> [extra Verilator args, e.g. -GROUND=0]
# The build goes to $WORK/<configuration> (default work/sim-config/); success prints "simulation passed".
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCH=$1 CONFIG=$2; shift 2
C="$ROOT/rtl/$ARCH/synthesis/$CONFIG"
[[ -d "$C" ]] || { echo "no configuration $C" >&2; exit 2; }
OUT="${WORK:-$ROOT/work/sim-config}/$CONFIG"
mkdir -p "$OUT"
defs=$(sed -n 's/^-define \(.*\)/+define+\1/p' "$C/list-define.txt" | grep -v CAPTURE_SHM || true)
tbs=$(sed "s|^|$ROOT/|" "$C/testbench-file.txt")
tbtop=$(grep -h -o -E '^module +tb[a-z0-9_]*' $tbs | awk '{print $2; exit}')
# top parameters the testbench declares are passed with -G; NBITS is a define
pars=""
while IFS='=' read -r k v; do
  [[ -n "$k" && "$k" != NBITS ]] && grep -q -E "parameter[^;=]*\b$k\b" $tbs && pars+="-G$k=$v "
done < "$C/top-parameters.txt"
nbits=$(grep -E '^NBITS=' "$C/top-parameters.txt" || true)
cd "$ROOT"
verilator -j "${JOBS:-4}" -DSIMULATION --top-module "$tbtop" $pars ${nbits:++define+$nbits} $defs "$@" -Wno-fatal \
  --Mdir "$OUT/obj" --binary --exe $(cat "$C/list-file.txt" "$C/testbench-file.txt") --build > "$OUT/build.log" 2>&1 \
  || { tail -20 "$OUT/build.log" >&2; exit 1; }
cd "$OUT" && ./obj/V"$tbtop" | tee run.log | grep -E -i "passed|mismatch|fatal" | head -3
