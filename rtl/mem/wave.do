onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/ram/clk
add wave -noupdate /tb/ram/reset
add wave -noupdate /tb/ram/chip_en
add wave -noupdate /tb/ram/wr_en
add wave -noupdate -radix decimal /tb/ram/address
add wave -noupdate -radix decimal /tb/ram/data_in
add wave -noupdate -radix decimal /tb/ram/data_out
add wave -noupdate -radix decimal /tb/ram/data_valid
add wave -noupdate -radix decimal /tb/ram/data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
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
WaveRestoreZoom {0 ns} {126 ns}
