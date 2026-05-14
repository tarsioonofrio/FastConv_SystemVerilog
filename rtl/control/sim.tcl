file delete {*}[glob -nocomplain wlf*]

if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

set GIT_ROOT [exec git rev-parse --show-toplevel]

# Centralized compile-time defines set directly in this script.
# Add more entries here if other packages/modules require them.

set NADDR 14
set NBITS 16
set LATENCY 1
set ROM 1
set QUANT 8

set define_flags ""
append define_flags "+define+NADDR=$NADDR "
append define_flags "+define+NBITS=$NBITS "
append define_flags "+define+LATENCY=$LATENCY "
append define_flags "+define+ROM=$ROM "
append define_flags "+define+QUANT=$QUANT "

# Read the file_list.txt file and execute vlog commands for each line, passing defines
set file_list "list-file.txt"
set fp [open $file_list r]
while {[gets $fp line] >= 0} {
    if {[string trim $line] ne ""} {
        vlog -work work $define_flags -svinputport=relaxed ${GIT_ROOT}/$line
    }
}
close $fp


vlog -work work +define+SIMULATION $define_flags -svinputport=relaxed ./control.sv
# vlog -work work $define_flags -svinputport=relaxed ./control.sv
vlog -work work $define_flags -svinputport=relaxed ./testbench.sv
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
