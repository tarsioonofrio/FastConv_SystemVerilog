if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

if {[info exists ::env(DATA)]} {
    set DATA_SV $::env(DATA)
} else {
    set DATA_SV "./data.sv"
}
vlog -work work  $DATA_SV
vlog -work work  ./rtl/pack_conv.sv
vlog -work work  ./rtl/multip.sv
vlog -work work -svinputport=relaxed ./rtl/csa_lib.sv
vlog -work work -svinputport=relaxed ./rtl/mult_matrices.sv
vlog -work work -svinputport=relaxed ./rtl/fast_conv.sv
vlog -work work -svinputport=relaxed ../../testbench/tb_conv.sv

vsim -voptargs=+acc -t ns work.tb




set StdArithNoWarnings 1
set StdVitalGlitchNoWarnings 1

do wave.do

run -all
