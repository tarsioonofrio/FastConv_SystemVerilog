set DATA data/tcn4/sim/sim-032-3-3-normal/pack_data.sv
set PARAM pack-param/tcn4/pack_param.sv
set MUX mux-mult/tcn4/mux_mult_16.sv

if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

set file_list [list \
  "${DATA}" \
  "${PARAM}" \
  "${MUX}" \
  "../mem/mem.sv" \
  "../csa/csa_lib.sv" \
  "../multip/multip.sv" \
  "mult-matrices/tcn4/mult_matrices.sv" \
]

vlog -work work -svinputport=relaxed {*}$file_list
vlog -work work -svinputport=relaxed ./conv.sv
vlog -work work -svinputport=relaxed ./testbench.sv
vsim -voptargs=+acc=lprn -t ps work.tb

if {![batch_mode]} {
  do wave.do
  do mem.do
}

run 20000000ns
