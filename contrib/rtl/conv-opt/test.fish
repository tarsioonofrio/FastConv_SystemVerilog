#!/usr/bin/env fish

modelsim-set-path
set -l SCRIPT_DIR (dirname (status -f))

pushd "$SCRIPT_DIR" >/dev/null
echo "Running test"
vsim -c -do sim.tcl
popd >/dev/null
