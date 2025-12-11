if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

set GIT_ROOT [exec git rev-parse --show-toplevel]


vlog -work work -svinputport=relaxed ${GIT_ROOT}/rtl/pack-def/pack_def.sv
vlog -work work -svinputport=relaxed ${GIT_ROOT}/rtl/pack-param/ifn9/pack_param.sv
vlog -work work -svinputport=relaxed ${GIT_ROOT}/rtl/pack-typedef/pack_typedef.sv
vlog -work work -svinputport=relaxed ${GIT_ROOT}/data/ifn9/sim/sim-032/pack_data.sv
vlog -work work -svinputport=relaxed ./mem.sv
vlog -work work -svinputport=relaxed ./tb_mem.sv

vsim -voptargs=+acc -t ns work.tb

set StdArithNoWarnings 1
set StdVitalGlitchNoWarnings 1

do wave.do

run 30000ns
#run -all
