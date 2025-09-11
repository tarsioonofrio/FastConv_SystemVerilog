if {[file exists "genus.log"]} {
    file delete -force "genus.log"
}
if {[file exists "genus.log*"]} {
    foreach f [glob "genus.log*"] {
        file delete -force $f
    }
}
if {[file exists "genus.cmd"]} {
    file delete -force "genus.cmd"
}
if {[file exists "genus.cmd*"]} {
    foreach f [glob "genus.cmd*"] {
        file delete -force $f
    }
}

set DB_FILE [file normalize [file join [pwd] "results/gate_level/conv_logic_mapped.db"]]

set GIT_ROOT [exec git rev-parse --show-toplevel]

source ${GIT_ROOT}/synthesis/run_power.tcl
