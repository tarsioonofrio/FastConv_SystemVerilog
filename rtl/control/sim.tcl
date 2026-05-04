if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

vlog +define+SIMULATION control.sv
vlog tb.sv

vsim -voptargs=+acc=lprn -t ps work.tb

do wave.do

run 31000  ns
quit -f

