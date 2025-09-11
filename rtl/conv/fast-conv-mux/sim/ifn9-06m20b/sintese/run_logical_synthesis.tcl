###############################################################################
# TOP
###############################################################################
set TOP_MODULE conv

set OUT_FILES ./results

set GIT_ROOT [exec git rev-parse --show-toplevel]

set HDL_FILES "
    [pwd]/../pack_conv.sv
   	${GIT_ROOT}/data/ifn9/data.sv
   	${GIT_ROOT}/rtl/pack_param/ifn9/pack_param.sv
    ${GIT_ROOT}/rtl/pack_typedef/pack_typedef.sv
   	${GIT_ROOT}/rtl/csa/csa_lib.sv
    ${GIT_ROOT}/rtl/mux-mult/ifn9/mux_mult_state_06.sv
   	${GIT_ROOT}/rtl/mult-matrices/ifn9/mult_matrices_simplified.sv
   	${GIT_ROOT}/rtl/conv/fast-conv-mux/rtl/fast_conv.sv
"

set DEFINE "NBITS=20"

source ${GIT_ROOT}/synthesis/run_logical_synthesis.tcl
