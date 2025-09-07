if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

set GIT_ROOT [exec git rev-parse --show-toplevel]

vlog -work work -svinputport=relaxed ${GIT_ROOT}/data/ifn9/data.sv
vlog -work work -svinputport=relaxed ${GIT_ROOT}/rtl/conv/fast-conv-mux/sim/ifn9-06m20b/pack_conv.sv
vlog -work work -svinputport=relaxed ${GIT_ROOT}/rtl/csa/csa_lib.sv
vlog -work work -svinputport=relaxed ${GIT_ROOT}/rtl/mux-mult/ifn9/mux_mult_int_06.sv
vlog -work work -svinputport=relaxed ${GIT_ROOT}/rtl/mult-matrices/ifn9/mult_matrices.sv
vlog -work work -svinputport=relaxed ./core.sv
vlog -work work -svinputport=relaxed ./tb_core.sv

vsim -voptargs=+acc -t ns work.tb
set StdArithNoWarnings 1
set StdVitalGlitchNoWarnings 1
do wave.do
run 1900ns
#run -all
