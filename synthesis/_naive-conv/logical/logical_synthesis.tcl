###############################################################################
# TOP
###############################################################################

set TOP_MODULE conv

set OUT_FILES "[pwd]/results"

set GIT_ROOT [exec git rev-parse --show-toplevel]

set DEFINE_FLAGS ""

set HDL_FILES "../rtl/mac_op9.sv ../rtl/naive_conv.sv ../rtl/pack_conv.sv"

source ${GIT_ROOT}/synthesis/_source/logical_synthesis.tcl
