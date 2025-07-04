if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

vlog -work work -svinputport=relaxed ../../src/ifn9-01m20b/data.sv
vlog -work work -svinputport=relaxed ../../src/ifn9-01m20b/rtl/pack_conv.sv
vlog -work work -svinputport=relaxed ./core_control.sv
vlog -work work -svinputport=relaxed ./tb_core_control.sv

vsim -voptargs=+acc -t ns work.tb

set StdArithNoWarnings 1
set StdVitalGlitchNoWarnings 1

do wave.do

#run 50ns
run -all
