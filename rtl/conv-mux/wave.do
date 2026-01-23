onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/QUANT
add wave -noupdate /tb/dut/NBITS
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/p_idle
add wave -noupdate /tb/dut/p_input
add wave -noupdate /tb/dut/p_weight
add wave -noupdate /tb/dut/p_output
add wave -noupdate /tb/dut/current_state
add wave -noupdate /tb/dut/next_state
add wave -noupdate /tb/dut/r_feat
add wave -noupdate /tb/dut/w_prod_c
add wave -noupdate /tb/dut/w_prod_a
add wave -noupdate /tb/dut/r_end
add wave -noupdate /tb/dut/r_idx_in
add wave -noupdate /tb/dut/r_idx_out
add wave -noupdate /tb/dut/product
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {53981379 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1000
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {53980858 ps} {53995745 ps}
