#!/usr/bin/env bash
set -u

BASE=/tmp/fastconv-nbits16-fde3bb1d/rtl/conv4x4/synthesis
CFG=${1:?configuration directory name required}
CONFIG_ROOT="$BASE/$CFG"
POWER_ROOT="$CONFIG_ROOT/power/diagnostics_hier_20261007"
SCRIPT=/tmp/fastconv-nbits16-fde3bb1d/joules_hierarchy_diag.tcl

source /usr/share/Modules/init/bash
module purge >/dev/null 2>&1 || true
module use /soft64/modulefiles
module load cadence/genus/211

export CONFIG_ROOT POWER_ROOT
genus -batch -no_gui -files "$SCRIPT" > "$POWER_ROOT/genus_hierarchy.log" 2>&1
STATUS=$?
printf '%s\n' "$STATUS" > "$POWER_ROOT/exit_status.txt"
exit "$STATUS"
