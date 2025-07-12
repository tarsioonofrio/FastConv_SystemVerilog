onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/serial_valid_in
add wave -noupdate /tb/dut/parallel_valid_in
add wave -noupdate /tb/dut/serial_valid_out
add wave -noupdate /tb/dut/parallel_valid_out
add wave -noupdate /tb/dut/current_st_to_serial
add wave -noupdate /tb/dut/next_st_to_serial
add wave -noupdate /tb/dut/current_st_to_parallel
add wave -noupdate /tb/dut/next_st_to_parallel
add wave -noupdate /tb/dut/count_to_serial
add wave -noupdate /tb/dut/count_to_parallel
add wave -noupdate -radix decimal -childformat {{{/tb/dut/parallel_data_out[35]} -radix decimal} {{/tb/dut/parallel_data_out[34]} -radix decimal} {{/tb/dut/parallel_data_out[33]} -radix decimal} {{/tb/dut/parallel_data_out[32]} -radix decimal} {{/tb/dut/parallel_data_out[31]} -radix decimal} {{/tb/dut/parallel_data_out[30]} -radix decimal} {{/tb/dut/parallel_data_out[29]} -radix decimal} {{/tb/dut/parallel_data_out[28]} -radix decimal} {{/tb/dut/parallel_data_out[27]} -radix decimal} {{/tb/dut/parallel_data_out[26]} -radix decimal} {{/tb/dut/parallel_data_out[25]} -radix decimal} {{/tb/dut/parallel_data_out[24]} -radix decimal} {{/tb/dut/parallel_data_out[23]} -radix decimal} {{/tb/dut/parallel_data_out[22]} -radix decimal} {{/tb/dut/parallel_data_out[21]} -radix decimal} {{/tb/dut/parallel_data_out[20]} -radix decimal} {{/tb/dut/parallel_data_out[19]} -radix decimal} {{/tb/dut/parallel_data_out[18]} -radix decimal} {{/tb/dut/parallel_data_out[17]} -radix decimal} {{/tb/dut/parallel_data_out[16]} -radix decimal} {{/tb/dut/parallel_data_out[15]} -radix decimal} {{/tb/dut/parallel_data_out[14]} -radix decimal} {{/tb/dut/parallel_data_out[13]} -radix decimal} {{/tb/dut/parallel_data_out[12]} -radix decimal} {{/tb/dut/parallel_data_out[11]} -radix decimal} {{/tb/dut/parallel_data_out[10]} -radix decimal} {{/tb/dut/parallel_data_out[9]} -radix decimal} {{/tb/dut/parallel_data_out[8]} -radix decimal} {{/tb/dut/parallel_data_out[7]} -radix decimal} {{/tb/dut/parallel_data_out[6]} -radix decimal} {{/tb/dut/parallel_data_out[5]} -radix decimal} {{/tb/dut/parallel_data_out[4]} -radix decimal} {{/tb/dut/parallel_data_out[3]} -radix decimal} {{/tb/dut/parallel_data_out[2]} -radix decimal} {{/tb/dut/parallel_data_out[1]} -radix decimal} {{/tb/dut/parallel_data_out[0]} -radix decimal}} -subitemconfig {{/tb/dut/parallel_data_out[35]} {-radix decimal} {/tb/dut/parallel_data_out[34]} {-radix decimal} {/tb/dut/parallel_data_out[33]} {-radix decimal} {/tb/dut/parallel_data_out[32]} {-radix decimal} {/tb/dut/parallel_data_out[31]} {-radix decimal} {/tb/dut/parallel_data_out[30]} {-radix decimal} {/tb/dut/parallel_data_out[29]} {-radix decimal} {/tb/dut/parallel_data_out[28]} {-radix decimal} {/tb/dut/parallel_data_out[27]} {-radix decimal} {/tb/dut/parallel_data_out[26]} {-radix decimal} {/tb/dut/parallel_data_out[25]} {-radix decimal} {/tb/dut/parallel_data_out[24]} {-radix decimal} {/tb/dut/parallel_data_out[23]} {-radix decimal} {/tb/dut/parallel_data_out[22]} {-radix decimal} {/tb/dut/parallel_data_out[21]} {-radix decimal} {/tb/dut/parallel_data_out[20]} {-radix decimal} {/tb/dut/parallel_data_out[19]} {-radix decimal} {/tb/dut/parallel_data_out[18]} {-radix decimal} {/tb/dut/parallel_data_out[17]} {-radix decimal} {/tb/dut/parallel_data_out[16]} {-radix decimal} {/tb/dut/parallel_data_out[15]} {-radix decimal} {/tb/dut/parallel_data_out[14]} {-radix decimal} {/tb/dut/parallel_data_out[13]} {-radix decimal} {/tb/dut/parallel_data_out[12]} {-radix decimal} {/tb/dut/parallel_data_out[11]} {-radix decimal} {/tb/dut/parallel_data_out[10]} {-radix decimal} {/tb/dut/parallel_data_out[9]} {-radix decimal} {/tb/dut/parallel_data_out[8]} {-radix decimal} {/tb/dut/parallel_data_out[7]} {-radix decimal} {/tb/dut/parallel_data_out[6]} {-radix decimal} {/tb/dut/parallel_data_out[5]} {-radix decimal} {/tb/dut/parallel_data_out[4]} {-radix decimal} {/tb/dut/parallel_data_out[3]} {-radix decimal} {/tb/dut/parallel_data_out[2]} {-radix decimal} {/tb/dut/parallel_data_out[1]} {-radix decimal} {/tb/dut/parallel_data_out[0]} {-radix decimal}} /tb/dut/parallel_data_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {466 ns} 0}
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
WaveRestoreZoom {420 ns} {540 ns}
