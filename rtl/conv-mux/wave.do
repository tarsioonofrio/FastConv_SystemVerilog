onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate -radix decimal /tb/dut/p_input
add wave -noupdate -radix decimal /tb/dut/p_weight
add wave -noupdate -radix decimal /tb/dut/p_output
add wave -noupdate /tb/dut/current_state
add wave -noupdate /tb/dut/next_state
add wave -noupdate -radix decimal /tb/dut/r_feat
add wave -noupdate -radix decimal /tb/dut/w_prod_c
add wave -noupdate -radix decimal /tb/dut/w_prod_a
add wave -noupdate /tb/dut/r_end
add wave -noupdate /tb/dut/r_idx_in
add wave -noupdate /tb/dut/r_idx_out
add wave -noupdate -radix decimal /tb/dut/product
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {9 ns} 0} {{Cursor 2} {21 ns} 0}
quietly wave cursor active 2
configure wave -namecolwidth 173
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
WaveRestoreZoom {0 ns} {32 ns}
