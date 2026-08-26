# ModelSim/QuestaSim runner for the direct TCN16 F(4x4, 3x3) tile core.
# The 4x4 design does not use the external feature-map Memory protocol used
# by the 2x2/3x3 controllers; the testbench drives one 6x6 tile at a time.

set DATA data/tcn16/sim/sim-032-3-3-normal/pack_data.sv
set PARAM pack-param/tcn16/pack_param.sv
set MUX mux-mult/tcn16/mux_mult_18.sv
set MATRICES mult-matrices/tcn16/mult_matrices.sv
set PACK_DEF ../../contrib/rtl/pack-def/pack_def.sv
set CSA ../csa/csa_lib.sv
set MULTIP ../multip/multip.sv

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
]

vlog -work work -svinputport=relaxed {*}$file_list
vlog -work work -svinputport=relaxed ./conv.sv
vlog -work work -svinputport=relaxed ./testbench.sv

vsim -voptargs=+acc=lprn -t ps work.tb
run 100000ns
