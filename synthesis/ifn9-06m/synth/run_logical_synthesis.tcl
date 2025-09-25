###############################################################################
# TOP
###############################################################################

set TOP_MODULE system

set OUT_FILES "[pwd]/results"

set GIT_ROOT [exec git rev-parse --show-toplevel]

# Read file_list.txt and concatenate its contents into a variable
set file_list_path "list-file.txt"

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

set DEFINE "-define NBITS=20"

source ${GIT_ROOT}/synthesis/source/run_logical_synthesis.tcl
