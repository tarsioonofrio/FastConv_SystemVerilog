#!/usr/bin/env fish

modelsim-set-path; or exit $status
set -l SCRIPT_DIR (dirname (status -f))
pushd "$SCRIPT_DIR" >/dev/null
vsim -c -do sim.tcl
set -l sim_status $status
popd >/dev/null
exit $sim_status
