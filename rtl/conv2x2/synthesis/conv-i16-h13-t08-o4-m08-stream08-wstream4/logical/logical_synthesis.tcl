###############################################################################
# Project-local logical synthesis flow.
#
# This file is intentionally self-contained. A synthesis configuration is
# copied below an RTL directory and only needs list-file.txt,
# list-define.txt, and top-module.txt beside logical/.
###############################################################################

# Resolve paths from the configuration, not from the process working directory.
set LOGICAL_ROOT [file normalize [file dirname [info script]]]
set CONFIG_ROOT [file normalize [file join $LOGICAL_ROOT ..]]
set GIT_ROOT [exec git -C $CONFIG_ROOT rev-parse --show-toplevel]
set OUT_FILES [file normalize [file join $LOGICAL_ROOT results]]

# The top is configurable per synthesis directory. Keep System as the default
# so an empty template remains useful for the system wrapper.
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

# Optional parameter overrides use one NAME=VALUE per line. They are useful
# for parameterized streaming cores such as NUM_MULT=2 without changing RTL.
set TOP_PARAMETERS [list]
set parameters_file [file join $CONFIG_ROOT top-parameters.txt]
if {[file exists $parameters_file]} {
    set fp_parameters [open $parameters_file r]
    while {[gets $fp_parameters line] >= 0} {
        set line_trim [string trim $line]
        if {$line_trim ne "" && ![string match "#*" $line_trim]} {
            lappend TOP_PARAMETERS $line_trim
        }
    }
    close $fp_parameters
}

# Resolve a list entry as an absolute path, accepting both repository-relative
# paths (the normal form) and paths relative to the configuration directory.
proc resolve_project_file {entry config_root git_root} {
    if {[file pathtype $entry] eq "absolute"} {
        return [file normalize $entry]
    }
    set from_config [file normalize [file join $config_root $entry]]
    if {[file exists $from_config]} {
        return $from_config
    }
    return [file normalize [file join $git_root $entry]]
}

# Read list-file.txt into a Tcl list so paths containing spaces are preserved.
set file_list_path [file join $CONFIG_ROOT list-file.txt]
set HDL_FILES [list]
if {[file exists $file_list_path]} {
    set fp [open $file_list_path r]
    while {[gets $fp line] >= 0} {
        set line_trim [string trim $line]
        if {$line_trim eq "" || [string match "#*" $line_trim]} {
            continue
        }
        lappend HDL_FILES [resolve_project_file $line_trim $CONFIG_ROOT $GIT_ROOT]
    }
    close $fp
}

# Parse either "NAME=VALUE" or the legacy "-define NAME=VALUE" spelling.
set defines_file [file join $CONFIG_ROOT list-define.txt]
set DEFINE_FLAGS [list]
if {[file exists $defines_file]} {
    set fp_def [open $defines_file r]
    while {[gets $fp_def line] >= 0} {
        set line_trim [string trim $line]
        if {$line_trim eq "" || [string match "#*" $line_trim]} {
            continue
        }
        if {[string match "-define *" $line_trim]} {
            set line_trim [string trim [string range $line_trim 8 end]]
        }
        if {$line_trim ne ""} {
            lappend DEFINE_FLAGS $line_trim
        }
    }
    close $fp_def
}

###############################################################################
# Genus configuration and synthesis body.
#
# Kept in this file deliberately: one logical synthesis entry point should be
# sufficient for a configuration.  The paths and options above are resolved
# before this body runs, so the script remains relocatable.
###############################################################################

puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Load the pdk using MMMC"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
read_mmmc [file join $CONFIG_ROOT scripts mmmc_tsmc_28_bv.tcl]

puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Configuration of the Genus"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
set_multi_cpu_usage -local_cpu 112
set_db lp_default_probability 0.5
set_db syn_global_effort high
set_db auto_ungroup none
set_db hdl_parameter_naming_style ""
set_db interconnect_mode ple
set_db hdl_error_on_latch true

puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Control Clock Gating"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
set_db lp_insert_clock_gating true

puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Load hdl files"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
if {[llength $DEFINE_FLAGS] > 0} {
    set DEFINE_STRING [join $DEFINE_FLAGS " "]
    read_hdl -define $DEFINE_STRING -sv {*}$HDL_FILES
} else {
    read_hdl -sv {*}$HDL_FILES
}

puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Elaboration"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
if {[llength $TOP_PARAMETERS] > 0} {
    elaborate ${TOP_MODULE} -parameters ${TOP_PARAMETERS}
} else {
    elaborate ${TOP_MODULE}
}
init_design

if {[info exists DEBUG_PRESERVE_CONV_DATAPATH] && $DEBUG_PRESERVE_CONV_DATAPATH} {
    puts "Debug: preserve Conv datapath observability"
    set_db delete_unloaded_insts false
    set_db optimize_constant_0_flops false
}

puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Synthesis - mapping and optimization"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
syn_generic
syn_map
syn_opt

puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Write Reports"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
file mkdir [file join $OUT_FILES reports]
file mkdir [file join $OUT_FILES gate_level]
file mkdir [file join $OUT_FILES physical_synthesis work]

report_clock_gating > [file join $OUT_FILES reports ${TOP_MODULE}_clock_gating.rpt]
report_ple > [file join $OUT_FILES reports ${TOP_MODULE}_ple.rpt]
report_gates > [file join $OUT_FILES reports ${TOP_MODULE}_gates.rpt]
report_area > [file join $OUT_FILES reports ${TOP_MODULE}_area.rpt]

set CURRENT_VIEW analysis_view_0p81v_125c_capwst_slowest
set_analysis_view -setup ${CURRENT_VIEW} -hold ${CURRENT_VIEW}
report_timing > [file join $OUT_FILES reports ${TOP_MODULE}_timing_setup_${CURRENT_VIEW}.rpt]
report_power -unit mW > [file join $OUT_FILES reports ${TOP_MODULE}_power_${CURRENT_VIEW}.rpt]

set CURRENT_VIEW analysis_view_0p90v_25c_captyp_nominal
set_analysis_view -setup ${CURRENT_VIEW} -hold ${CURRENT_VIEW}
report_timing > [file join $OUT_FILES reports ${TOP_MODULE}_timing_setup_${CURRENT_VIEW}.rpt]
report_power -unit mW > [file join $OUT_FILES reports ${TOP_MODULE}_power_${CURRENT_VIEW}.rpt]

set CURRENT_VIEW analysis_view_0p99v_m40c_capbst_fastest
set_analysis_view -setup ${CURRENT_VIEW} -hold ${CURRENT_VIEW}
report_timing > [file join $OUT_FILES reports ${TOP_MODULE}_timing_setup_${CURRENT_VIEW}.rpt]
report_power -unit mW > [file join $OUT_FILES reports ${TOP_MODULE}_power_${CURRENT_VIEW}.rpt]
report_timing -lint -verbose > [file join $OUT_FILES reports ${TOP_MODULE}_timing_setup_${CURRENT_VIEW}_verbose.rpt]
report_timing -unconstrained > [file join $OUT_FILES reports ${TOP_MODULE}_timing_setup_${CURRENT_VIEW}_verbose_unconstrained.rpt]

puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Write netlist"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
write_hdl > [file join $OUT_FILES gate_level ${TOP_MODULE}_logic_mapped.v]

set CURRENT_VIEW analysis_view_0p81v_125c_capwst_slowest
set_analysis_view -setup ${CURRENT_VIEW} -hold ${CURRENT_VIEW}
write_sdf > [file join $OUT_FILES gate_level ${TOP_MODULE}_${CURRENT_VIEW}.sdf]

set CURRENT_VIEW analysis_view_0p90v_25c_captyp_nominal
set_analysis_view -setup ${CURRENT_VIEW} -hold ${CURRENT_VIEW}
write_sdf > [file join $OUT_FILES gate_level ${TOP_MODULE}_${CURRENT_VIEW}.sdf]

set CURRENT_VIEW analysis_view_0p99v_m40c_capbst_fastest
set_analysis_view -setup ${CURRENT_VIEW} -hold ${CURRENT_VIEW}
write_sdf > [file join $OUT_FILES gate_level ${TOP_MODULE}_${CURRENT_VIEW}.sdf]

set_analysis_view -setup analysis_view_0p81v_125c_capwst_slowest \
                  -hold analysis_view_0p99v_m40c_capbst_fastest
write_design -innovus -base_name [file join $OUT_FILES physical_synthesis work data]

set CURRENT_VIEW analysis_view_0p90v_25c_captyp_nominal
set_analysis_view -setup ${CURRENT_VIEW} -hold ${CURRENT_VIEW}
write_db [file join $OUT_FILES gate_level ${TOP_MODULE}_logic_mapped.db]

exit
