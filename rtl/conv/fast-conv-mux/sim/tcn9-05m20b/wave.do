onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/convolucao/QUANT
add wave -noupdate /tb/convolucao/NBITS
add wave -noupdate /tb/convolucao/clk
add wave -noupdate /tb/convolucao/reset
add wave -noupdate /tb/convolucao/start
add wave -noupdate -radix decimal /tb/convolucao/inputMAP
add wave -noupdate -radix decimal /tb/convolucao/weights
add wave -noupdate -radix decimal /tb/convolucao/outputMAP
add wave -noupdate /tb/convolucao/data_valid
add wave -noupdate /tb/convolucao/current_st
add wave -noupdate /tb/convolucao/next_st
add wave -noupdate -radix decimal /tb/convolucao/registers
add wave -noupdate -radix decimal /tb/convolucao/prod_c0
add wave -noupdate -radix decimal /tb/convolucao/prod_c
add wave -noupdate -radix decimal /tb/convolucao/prod_a
add wave -noupdate -radix decimal /tb/convolucao/product
add wave -noupdate -radix decimal /tb/convolucao/idx
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {20 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {9 ns} {47 ns}
