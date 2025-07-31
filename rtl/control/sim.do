if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

vlog -work work -svinputport=relaxed ./data-sim.sv
vlog -work work -svinputport=relaxed ./pack_conv.sv
vlog -work work -svinputport=relaxed ../conv/ifn9-06m20b/rtl/csa_lib.sv
vlog -work work -svinputport=relaxed ../conv/ifn9-06m20b/rtl/mult_matrices.sv
vlog -work work -svinputport=relaxed ../core/core.sv
vlog -work work -svinputport=relaxed ../mem/mem.sv
vlog -work work -svinputport=relaxed ./control.sv
vlog -work work -svinputport=relaxed ./tb_control.sv

vsim -voptargs=+acc -t ns work.tb
set StdArithNoWarnings 1
set StdVitalGlitchNoWarnings 1
do wave.do
run 1800ns
# run -all
