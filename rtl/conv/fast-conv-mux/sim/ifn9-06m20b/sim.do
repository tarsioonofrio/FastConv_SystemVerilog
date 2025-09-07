if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

set GIT_ROOT [exec git rev-parse --show-toplevel]

if {[info exists ::env(DATA)]} {
    set DATA_SV $::env(DATA)
} else {
    set DATA_SV "${GIT_ROOT}/data/ifn9/data.sv"
}
vlog -work work  $DATA_SV
vlog -work work  ./pack_conv.sv
vlog -work work -svinputport=relaxed ${GIT_ROOT}/rtl/csa/csa_lib.sv
vlog -work work -svinputport=relaxed ${GIT_ROOT}/rtl/mux-mult/ifn9/mux_mult_state_06.sv
vlog -work work -svinputport=relaxed ${GIT_ROOT}/rtl/mult-matrices/ifn9/mult_matrices_simplified.sv
vlog -work work -svinputport=relaxed ${GIT_ROOT}/rtl/conv/fast-conv-mux/rtl/fast_conv.sv
vlog -work work -svinputport=relaxed ${GIT_ROOT}/rtl/conv/testbench.sv

vsim -voptargs=+acc -t ns work.tb


set StdArithNoWarnings 1
set StdVitalGlitchNoWarnings 1

do wave.do

#run 50ns
run -all
