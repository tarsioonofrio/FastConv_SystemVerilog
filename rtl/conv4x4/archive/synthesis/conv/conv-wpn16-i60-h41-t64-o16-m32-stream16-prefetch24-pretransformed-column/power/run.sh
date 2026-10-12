#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
rm -f genus.cmd* genus.log*

module purge  > /dev/null 2>&1
module load cadence/genus/211
genus -f power.tcl
