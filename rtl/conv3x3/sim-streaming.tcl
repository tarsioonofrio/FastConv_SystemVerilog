set DATA data/ifn9/sim/sim-032-3-3-normal/pack_data.sv
set PARAM pack-param/ifn9/pack_param.sv
set MUX mux-mult/ifn9/mux_mult_06.sv
set MATRICES mult-matrices/ifn9/mult_matrices_csa.sv
set DEFINES [list +define+NADDR=14 +define+NBITS=16 +define+LATENCY=1 +define+STREAMING_CONV_TEST]

if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

set file_list [list \
  "${DATA}" \
  "${PARAM}" \
  "${MUX}" \
  "../csa/csa_lib.sv" \
  "${MATRICES}" \
  "../mem/mem.sv" \
  "../multip/multip.sv" \
]

vlog -work work {*}$DEFINES -svinputport=relaxed {*}$file_list
vlog -work work {*}$DEFINES -svinputport=relaxed ./conv.sv
vlog -work work {*}$DEFINES -svinputport=relaxed ./testbench.sv
vsim -voptargs=+acc=lprn -debugDB -t ps work.tb
run 20000000ns
