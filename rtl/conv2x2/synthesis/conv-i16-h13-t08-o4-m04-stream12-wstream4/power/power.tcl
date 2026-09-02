###############################################################################
# Project-local power analysis flow.
###############################################################################

set POWER_ROOT [file normalize [file dirname [info script]]]
set CONFIG_ROOT [file normalize [file join $POWER_ROOT ..]]
set GIT_ROOT [exec git -C $CONFIG_ROOT rev-parse --show-toplevel]
set TOP_MODULE system
set top_file [file join $CONFIG_ROOT top-module.txt]
if {[file exists $top_file]} {
    set fp_top [open $top_file r]
    while {[gets $fp_top line] >= 0} {
        set line_trim [string trim $line]
        if {$line_trim ne "" && ![string match "#*" $line_trim]} {
            set TOP_MODULE $line_trim
            break
        }
    }
    close $fp_top
}
set DB_FILE [file normalize [file join $CONFIG_ROOT logical results gate_level ${TOP_MODULE}_logic_mapped.db]]
set SHM [file normalize [file join $CONFIG_ROOT sim dut.shm]]

source [file join $CONFIG_ROOT scripts power.tcl]
