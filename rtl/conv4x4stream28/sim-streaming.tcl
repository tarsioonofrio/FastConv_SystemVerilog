# ModelSim runner for the isolated F(4x4, 3x3) row-streaming controller.

set DATA ../conv4x4/data/tcn16/sim/sim-032-3-3-normal/pack_data.sv
set PARAM pack-param/tcn16/pack_param.sv
set MATRICES mult-matrices/tcn16/mult_matrices.sv
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
