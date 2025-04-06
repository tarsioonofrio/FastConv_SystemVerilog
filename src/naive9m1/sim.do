if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

vlog -work work  pack_conv.sv
vlog -work work  -svinputport=relaxed mac_op.sv
vlog -work work  -svinputport=relaxed naive_conv.sv
vlog -work work  -svinputport=relaxed tb_naive_conv.sv

vsim -voptargs=+acc -t ns work.tb


set StdArithNoWarnings 1
set StdVitalGlitchNoWarnings 1

do wave.do

run 1250 ns

