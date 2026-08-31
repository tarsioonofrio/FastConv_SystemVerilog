set DATA ../conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv
set PARAM ../conv2x2/pack-param/tcn4/pack_param.sv
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
  "mult-matrices/tcn4/mult_matrices.sv" \
]

vlog -work work {*}$DEFINES -svinputport=relaxed {*}$file_list
vlog -work work {*}$DEFINES -svinputport=relaxed ./conv2mac.sv
vlog -work work {*}$DEFINES -svinputport=relaxed ./testbench.sv
vsim -voptargs=+acc=lprn -t ps work.tb
run 20000000ns
