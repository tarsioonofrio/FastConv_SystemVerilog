# Centralized compile-time defines set directly in this script.
# Add more entries here if other packages/modules require them.

set NADDR 14
set NBITS 16
set LATENCY 1
set ROM 1
# set QUANT 8

set DATA data/ifn9/sim/sim-016-3-3-seq-new-test/pack_data.sv
set PARAM rtl/pack-param/ifn9/pack_param.sv
set MUX rtl/mux-mult/ifn9/mux_mult_06.sv
set MULT rtl/mult-matrices/ifn9/mult_matrices_csa.sv

set define_flags ""
append define_flags "+define+NADDR=$NADDR "
append define_flags "+define+NBITS=$NBITS "
append define_flags "+define+LATENCY=$LATENCY "
append define_flags "+define+ROM=$ROM "
# append define_flags "+define+QUANT=$QUANT "


file delete {*}[glob -nocomplain wlf*]
if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

# Read the file_list.txt file and execute vlog commands for each line, passing defines
set GIT_ROOT [exec git rev-parse --show-toplevel]
set file_list [list \
  "${GIT_ROOT}/${DATA}" \
  "${GIT_ROOT}/${PARAM}" \
  "${GIT_ROOT}/${MUX}" \
  "${GIT_ROOT}/rtl/csa/csa_lib.sv" \
  "${GIT_ROOT}/${MULT}" \
  "${GIT_ROOT}/rtl/mem/mem.sv" \
  "${GIT_ROOT}/rtl/multip/multip.sv" \
]

vlog -work work $define_flags -svinputport=relaxed {*}$file_list

vlog -work work +define+SIMULATION $define_flags -svinputport=relaxed ./control.sv
# vlog -work work $define_flags -svinputport=relaxed ./control.sv
vlog -work work $define_flags -svinputport=relaxed ./testbench-new.sv
# to show FSM
# vsim -voptargs=+acc -t ps -fsmdebug -coverage -debugDB work.tb
vsim -voptargs=+acc=lprn -t ps work.tb
# vsim -voptargs=+acc -t ps work.tb
set StdArithNoWarnings 1
set StdVitalGlitchNoWarnings 1
do wave.do
do mem.do

# run 31000  ns
run 400000ns
# coverage report -output report.txt -srcfile=* -assert -directive -cvg -codeAll
