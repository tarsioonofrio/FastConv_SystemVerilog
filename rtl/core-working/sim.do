if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

set GIT_ROOT [exec git rev-parse --show-toplevel]

vlog -work work -svinputport=relaxed ./data.sv
vlog -work work -svinputport=relaxed ./pack_conv.sv
vlog -work work -svinputport=relaxed ./csa_lib.sv
vlog -work work -svinputport=relaxed ./mux_mult_int_06.sv
vlog -work work -svinputport=relaxed ./mult_matrices.sv
vlog -work work -svinputport=relaxed ./core.sv
vlog -work work -svinputport=relaxed ./tb_core.sv

vsim -voptargs=+acc -t ns work.tb
set StdArithNoWarnings 1
set StdVitalGlitchNoWarnings 1
do wave.do
run 1900ns
#run -all
