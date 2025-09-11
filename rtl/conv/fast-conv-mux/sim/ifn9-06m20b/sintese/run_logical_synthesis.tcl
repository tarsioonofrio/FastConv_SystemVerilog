###############################################################################
# TOP
###############################################################################
set TOP_MODULE conv

set OUT_FILES "[pwd]/results"

set GIT_ROOT [exec git rev-parse --show-toplevel]

# Read file_list.txt and concatenate its contents into a variable
set file_list_path "${GIT_ROOT}/rtl/conv/fast-conv-mux/sim/ifn9-06m20b/file_list.txt"

set HDL_FILES "[pwd]/../pack_conv.sv "

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

append HDL_FILES "${GIT_ROOT}/rtl/conv/fast-conv-mux/rtl/fast_conv.sv"

set DEFINE "-define NBITS=20"

source ${GIT_ROOT}/synthesis/run_logical_synthesis.tcl
