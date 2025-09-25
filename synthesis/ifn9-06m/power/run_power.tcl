set DB_FILE [file normalize [file join [pwd] "../logical/results/gate_level/system_logic_mapped.db"]]
set SHM [file normalize [file join [pwd] "../sim/dut.shm"]]
set GIT_ROOT [exec git rev-parse --show-toplevel]

source ${GIT_ROOT}/synthesis/source/run_power.tcl
