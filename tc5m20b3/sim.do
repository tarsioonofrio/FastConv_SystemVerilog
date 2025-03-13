if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

vlog -work work  ./rtl/pack_conv.sv
vlog -work work -svinputport=relaxed ./rtl/csa_lib.sv
vlog -work work -svinputport=relaxed ./rtl/mult_matrices.sv
vlog -work work -svinputport=relaxed ./rtl/fast_conv.sv 
vlog -work work -svinputport=relaxed tb_fast_conv.sv 

vsim -voptargs=+acc -t ns work.tb

set StdArithNoWarnings 1
set StdVitalGlitchNoWarnings 1

do wave.do

run 900 ns

