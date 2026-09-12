###############################################################################
# ModelSim post-synthesis simulation for one project-local configuration.
###############################################################################

if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

set SIM_ROOT [file normalize [file dirname [info script]]]
set CONFIG_ROOT [file normalize [file join $SIM_ROOT ..]]
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
    # The mapped gate-level top is added below.  Exclude its RTL counterpart
    # from list-file.txt so Xcelium/ModelSim elaborate one Conv hierarchy.
    if {[file tail $line_trim] eq "${top_module}.sv"} { continue }
    vlog -work work {*}$define_flags -svinputport=relaxed \
        [resolve_project_file $line_trim $CONFIG_ROOT $GIT_ROOT]
}
close $fp

set top_file [file join $CONFIG_ROOT top-module.txt]
set top_module system
if {[file exists $top_file]} {
    set fp_top [open $top_file r]
    while {[gets $fp_top line] >= 0} {
        set line_trim [string trim $line]
        if {$line_trim ne "" && ![string match "#*" $line_trim]} {
            set top_module $line_trim
            break
        }
    }
    close $fp_top
}
set gate_file [file normalize [file join $CONFIG_ROOT logical results gate_level ${top_module}_logic_mapped.v]]
if {![file exists $gate_file]} { error "Missing mapped netlist: $gate_file" }
vlog -work work {*}$define_flags -svinputport=relaxed $gate_file

set tb_file [file join $CONFIG_ROOT testbench-file.txt]
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

vsim -voptargs=+acc -t ns work.tb
set StdArithNoWarnings 1
set StdVitalGlitchNoWarnings 1
do wave.do
run -all
