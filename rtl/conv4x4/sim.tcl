# ModelSim/QuestaSim runner for the F(4x4, 3x3) controller.
# Select a generated configuration with FASTCONV_CONFIG and FASTCONV_NUM_MULT.
# Defaults preserve the original TCN16/18-MAC flow.

if {[info exists ::env(FASTCONV_CONFIG)]} {
  set CONFIG $::env(FASTCONV_CONFIG)
} else {
  set CONFIG tcn16
}
if {[info exists ::env(FASTCONV_DATASET)]} {
  set DATASET $::env(FASTCONV_DATASET)
} else {
  set DATASET sim-032-3-3-normal
}
if {[info exists ::env(FASTCONV_NUM_MULT)]} {
  set NUM_MULT $::env(FASTCONV_NUM_MULT)
} else {
  set NUM_MULT 18
}

set DATA data/${CONFIG}/sim/${DATASET}/pack_data.sv
set PARAM pack-param/${CONFIG}/pack_param.sv
set MUX mux-mult/${CONFIG}/mux_mult_${NUM_MULT}.sv
set MATRICES mult-matrices/${CONFIG}/mult_matrices.sv
set PACK_DEF ../../contrib/rtl/pack-def/pack_def.sv
set CSA ../csa/csa_lib.sv
set MULTIP ../multip/multip.sv
set MEM ../mem/mem.sv

if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

set file_list [list \
  "${DATA}" \
  "${PACK_DEF}" \
  "${PARAM}" \
  "${MUX}" \
  "${CSA}" \
  "${MULTIP}" \
  "${MATRICES}" \
  "${MEM}" \
]

vlog -work work -svinputport=relaxed {*}$file_list
vlog -work work -svinputport=relaxed ./conv.sv
vlog -work work -svinputport=relaxed ./testbench.sv

vsim -voptargs=+acc=lprn -t ps work.tb
run -all
