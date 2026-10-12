#!/usr/bin/env bash
set -euo pipefail
POWER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$POWER_ROOT"
rm -f genus.cmd genus.cmd.* genus.log genus.log.*
module purge > /dev/null 2>&1
module load cadence/genus/211
genus -f power.tcl
