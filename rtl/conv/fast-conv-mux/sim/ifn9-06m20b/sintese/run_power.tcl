set DB_FILE [file normalize [file join [pwd] "results/gate_level/conv_logic_mapped.db"]]
set SHM [file normalize [file join [pwd] "../simSDF/conv.shm"]]
set GIT_ROOT [exec git rev-parse --show-toplevel]

source ${GIT_ROOT}/synthesis/run_power.tcl
