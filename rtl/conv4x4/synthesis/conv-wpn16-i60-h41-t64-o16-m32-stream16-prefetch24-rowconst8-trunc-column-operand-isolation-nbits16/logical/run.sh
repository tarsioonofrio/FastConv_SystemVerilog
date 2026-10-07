#!/usr/bin/env bash
set -euo pipefail

LOGICAL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source /usr/share/Modules/init/bash
module purge
module use /soft64/modulefiles
module load cadence/genus/211 > /dev/null 2>&1
cd "$LOGICAL_ROOT"
genus -f logical_synthesis.tcl
