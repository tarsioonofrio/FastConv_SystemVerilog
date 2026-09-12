###############################################################################
# RTL simulation for one project-local synthesis configuration.
###############################################################################

file delete -force {*}[glob -nocomplain wlf*]
if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

set SIM_ROOT [file normalize [file dirname [info script]]]
set CONFIG_ROOT $SIM_ROOT
set GIT_ROOT [exec git -C $CONFIG_ROOT rev-parse --show-toplevel]

proc resolve_project_file {entry config_root git_root} {
    if {[file pathtype $entry] eq "absolute"} { return [file normalize $entry] }
    set from_config [file normalize [file join $config_root $entry]]
    if {[file exists $from_config]} { return $from_config }
    return [file normalize [file join $git_root $entry]]
}

set define_flags [list]
set defines_file [file join $CONFIG_ROOT list-define.txt]
if {[file exists $defines_file]} {
    set fp_def [open $defines_file r]
    while {[gets $fp_def line] >= 0} {
        set line_trim [string trim $line]
        if {$line_trim eq "" || [string match "#*" $line_trim]} { continue }
        if {[string match "-define *" $line_trim]} {
            set line_trim [string trim [string range $line_trim 8 end]]
        }
        lappend define_flags "+define+$line_trim"
    }
    close $fp_def
}

set file_list [file join $CONFIG_ROOT list-file.txt]
set fp [open $file_list r]
while {[gets $fp line] >= 0} {
    set line_trim [string trim $line]
    if {$line_trim eq "" || [string match "#*" $line_trim]} { continue }
    vlog -work work {*}$define_flags -svinputport=relaxed \
        [resolve_project_file $line_trim $CONFIG_ROOT $GIT_ROOT]
}
close $fp

set tb_file [file join $CONFIG_ROOT testbench-file.txt]
if {![file exists $tb_file]} { error "Missing testbench-file.txt" }
set fp_tb [open $tb_file r]
set tb_path ""
while {[gets $fp_tb line] >= 0} {
    set line_trim [string trim $line]
    if {$line_trim ne "" && ![string match "#*" $line_trim]} {
        set tb_path [resolve_project_file $line_trim $CONFIG_ROOT $GIT_ROOT]
        break
    }
}
close $fp_tb
if {$tb_path eq ""} { error "testbench-file.txt is empty" }
vlog -work work {*}$define_flags -svinputport=relaxed $tb_path

set generic_flags [list]
set parameters_file [file join $CONFIG_ROOT top-parameters.txt]
if {[file exists $parameters_file]} {
    set fp_parameters [open $parameters_file r]
    while {[gets $fp_parameters line] >= 0} {
        set line_trim [string trim $line]
        if {$line_trim ne "" && ![string match "#*" $line_trim]} {
            lappend generic_flags "-g$line_trim"
        }
    }
    close $fp_parameters
}

vsim {*}$generic_flags -voptargs=+acc -t ps work.tb
set StdArithNoWarnings 1
set StdVitalGlitchNoWarnings 1
run 400000ns
quit
