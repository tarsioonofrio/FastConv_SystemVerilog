#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
rm -f genus.cmd* genus.log*

module purge
module load cadence/genus/211 > /dev/null 2>&1
genus -f logical_synthesis.tcl
