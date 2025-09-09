if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

set GIT_ROOT [exec git rev-parse --show-toplevel]

if {[info exists ::env(DATA)]} {
    set DATA_SV $::env(DATA)
} else {
    set DATA_SV "${GIT_ROOT}/data/ifn9/data.sv"
}
vlog -work work  -svinputport=relaxed $DATA_SV
vlog -work work  -svinputport=relaxed ./pack_conv.sv

# Read the file_list.txt file and execute vlog commands for each line
set file_list "${GIT_ROOT}/rtl/conv/fast-conv-mux/sim/ifn9-06m20b/file_list.txt"
set fp [open $file_list r]
while {[gets $fp path] >= 0} {
    if {[string trim $path] ne ""} {
        vlog -work work -svinputport=relaxed ${GIT_ROOT}/$path
    }
}
close $fp

vlog -work work -svinputport=relaxed ${GIT_ROOT}/rtl/conv/testbench.sv

vsim -voptargs=+acc -t ns work.tb

set StdArithNoWarnings 1
set StdVitalGlitchNoWarnings 1

do wave.do

#run 50ns
run -all
