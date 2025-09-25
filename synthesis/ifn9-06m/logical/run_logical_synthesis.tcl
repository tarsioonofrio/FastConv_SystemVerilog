###############################################################################
# TOP
###############################################################################

set TOP_MODULE system

set OUT_FILES "[pwd]/results"

set GIT_ROOT [exec git rev-parse --show-toplevel]

# Read file_list.txt and concatenate its contents into a variable
set file_list_path "../list-file.txt"

set HDL_FILES ""

if { [file exists $file_list_path] } {
    set fp [open $file_list_path r]
    while { [gets $fp line] >= 0 } {
        set line_trim [string trim $line]
        if { $line_trim ne "" } {
            append HDL_FILES "${GIT_ROOT}/$line_trim "
        }
    }
    close $fp
}

set defines_file "../list-define.txt"
set DEFINE_FLAGS ""

if {[file exists $defines_file]} {
    set fp_def [open $defines_file r]
    while {[gets $fp_def line] >= 0} {
        set line_trim [string trim $line]
        # remove -define do início de cada linha
        set line_trim [string range $line_trim 8 end]
        if { $line_trim ne "" && [string first "=" $line_trim] > 0 } {
            set DEFINE_FLAGS "$DEFINE_FLAGS $line_trim "
        }
    }
    close $fp_def
}

append HDL_FILES "${GIT_ROOT}/rtl/system/system.sv"

source ${GIT_ROOT}/synthesis/source/run_logical_synthesis.tcl
