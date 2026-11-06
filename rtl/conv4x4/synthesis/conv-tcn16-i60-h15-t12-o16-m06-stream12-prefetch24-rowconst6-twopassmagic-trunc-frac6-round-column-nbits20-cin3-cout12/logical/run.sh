#!/usr/bin/env bash
set -euo pipefail
LOGICAL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$LOGICAL_ROOT"
rm -f genus.cmd genus.cmd.* genus.log genus.log.*
module purge > /dev/null 2>&1
module load cadence/genus/211
genus -f logical_synthesis.tcl
