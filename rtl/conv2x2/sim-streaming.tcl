set DATA data/tcn4/sim/sim-032-3-3-normal/pack_data.sv
set PARAM pack-param/tcn4/pack_param.sv
set SOURCE conv-stream12-generic-i16-p24-o4-m2-4-8.sv
if {[info exists ::env(FASTCONV_STREAM_SOURCE)] && $::env(FASTCONV_STREAM_SOURCE) ne ""} {
  set SOURCE $::env(FASTCONV_STREAM_SOURCE)
}
set DEFINES [list]

if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

set file_list [list \
  "${DATA}" \
  "${PARAM}" \
  "../mem/mem.sv" \
  "../csa/csa_lib.sv" \
  "../multip/multip.sv" \
  "mult-matrices/stream/tcn4/mult_matrices.sv" \
]

vlog -work work {*}$DEFINES -svinputport=relaxed {*}$file_list
vlog -work work {*}$DEFINES -svinputport=relaxed ./$SOURCE
vlog -work work {*}$DEFINES -svinputport=relaxed ./testbench.sv
vsim -voptargs=+acc=lprn -t ps work.tb
run 20000000ns
