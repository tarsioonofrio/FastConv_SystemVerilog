if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

vlog -work work  ./data.sv
vlog -work work  ./rtl/pack_conv.sv
vlog -work work  -svinputport=relaxed ./rtl/mac_op9.sv
vlog -work work  -svinputport=relaxed ./rtl/naive_conv.sv
vlog -work work  -svinputport=relaxed ./testbench.sv

vsim -voptargs=+acc -t ns work.tb


set StdArithNoWarnings 1
set StdVitalGlitchNoWarnings 1

do wave.do

run -all
