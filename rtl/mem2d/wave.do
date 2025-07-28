onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/memory/clk
add wave -noupdate /tb/memory/reset
add wave -noupdate /tb/memory/chip_en
add wave -noupdate /tb/memory/wr_en
add wave -noupdate -radix decimal /tb/memory/address
add wave -noupdate -radix decimal /tb/memory/data_in
add wave -noupdate -radix decimal /tb/memory/data_out
add wave -noupdate /tb/memory/data_valid
add wave -noupdate -radix decimal /tb/memory/data
add wave -noupdate /tb/memory/r_cycles_latency
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {16 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 229
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {52 ns} {110 ns}
