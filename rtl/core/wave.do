onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/p_debug
add wave -noupdate /tb/dut/p_in_ce
add wave -noupdate /tb/dut/p_in_valid
add wave -noupdate /tb/dut/p_wh_ce
add wave -noupdate /tb/dut/p_wh_valid
add wave -noupdate /tb/dut/p_out_en
add wave -noupdate /tb/dut/p_out_valid
add wave -noupdate -radix decimal /tb/dut/p_in_data
add wave -noupdate -radix decimal /tb/dut/p_out_data
add wave -noupdate /tb/dut/current_st
add wave -noupdate /tb/dut/next_st
add wave -noupdate -radix decimal -childformat {{{/tb/dut/input_map[24]} -radix decimal} {{/tb/dut/input_map[23]} -radix decimal} {{/tb/dut/input_map[22]} -radix decimal} {{/tb/dut/input_map[21]} -radix decimal} {{/tb/dut/input_map[20]} -radix decimal} {{/tb/dut/input_map[19]} -radix decimal} {{/tb/dut/input_map[18]} -radix decimal} {{/tb/dut/input_map[17]} -radix decimal} {{/tb/dut/input_map[16]} -radix decimal} {{/tb/dut/input_map[15]} -radix decimal} {{/tb/dut/input_map[14]} -radix decimal} {{/tb/dut/input_map[13]} -radix decimal} {{/tb/dut/input_map[12]} -radix decimal} {{/tb/dut/input_map[11]} -radix decimal} {{/tb/dut/input_map[10]} -radix decimal} {{/tb/dut/input_map[9]} -radix decimal} {{/tb/dut/input_map[8]} -radix decimal} {{/tb/dut/input_map[7]} -radix decimal} {{/tb/dut/input_map[6]} -radix decimal} {{/tb/dut/input_map[5]} -radix decimal} {{/tb/dut/input_map[4]} -radix decimal} {{/tb/dut/input_map[3]} -radix decimal} {{/tb/dut/input_map[2]} -radix decimal} {{/tb/dut/input_map[1]} -radix decimal} {{/tb/dut/input_map[0]} -radix decimal}} -expand -subitemconfig {{/tb/dut/input_map[24]} {-radix decimal} {/tb/dut/input_map[23]} {-radix decimal} {/tb/dut/input_map[22]} {-radix decimal} {/tb/dut/input_map[21]} {-radix decimal} {/tb/dut/input_map[20]} {-radix decimal} {/tb/dut/input_map[19]} {-radix decimal} {/tb/dut/input_map[18]} {-radix decimal} {/tb/dut/input_map[17]} {-radix decimal} {/tb/dut/input_map[16]} {-radix decimal} {/tb/dut/input_map[15]} {-radix decimal} {/tb/dut/input_map[14]} {-radix decimal} {/tb/dut/input_map[13]} {-radix decimal} {/tb/dut/input_map[12]} {-radix decimal} {/tb/dut/input_map[11]} {-radix decimal} {/tb/dut/input_map[10]} {-radix decimal} {/tb/dut/input_map[9]} {-radix decimal} {/tb/dut/input_map[8]} {-radix decimal} {/tb/dut/input_map[7]} {-radix decimal} {/tb/dut/input_map[6]} {-radix decimal} {/tb/dut/input_map[5]} {-radix decimal} {/tb/dut/input_map[4]} {-radix decimal} {/tb/dut/input_map[3]} {-radix decimal} {/tb/dut/input_map[2]} {-radix decimal} {/tb/dut/input_map[1]} {-radix decimal} {/tb/dut/input_map[0]} {-radix decimal}} /tb/dut/input_map
add wave -noupdate -radix decimal /tb/dut/output_map
add wave -noupdate -radix decimal /tb/dut/register_weight
add wave -noupdate -radix decimal /tb/dut/registers_out
add wave -noupdate /tb/dut/out_ce
add wave -noupdate /tb/dut/out_we
add wave -noupdate /tb/dut/s_end
add wave -noupdate /tb/dut/output_valid
add wave -noupdate /tb/dut/start_conv
add wave -noupdate /tb/dut/serial_in_ce
add wave -noupdate -radix decimal /tb/dut/serial_data_in
add wave -noupdate -radix decimal /tb/dut/parallel_valid_out
add wave -noupdate -radix decimal /tb/dut/parallel_data_out
add wave -noupdate -radix decimal /tb/dut/parallel_valid_in
add wave -noupdate -radix decimal /tb/dut/parallel_data_in
add wave -noupdate -radix decimal /tb/dut/serial_valid_out
add wave -noupdate -radix decimal /tb/dut/serial_data_out
add wave -noupdate /tb/dut/count_to_parallel
add wave -noupdate /tb/dut/count_to_serial
add wave -noupdate -radix decimal /tb/dut/inputMAP
add wave -noupdate -radix decimal /tb/dut/weights
add wave -noupdate -radix decimal /tb/dut/outputMAP
add wave -noupdate /tb/dut/data_valid
add wave -noupdate /tb/dut/start
add wave -noupdate /tb/dut/current_st_conv
add wave -noupdate /tb/dut/next_st_conv
add wave -noupdate -radix decimal -childformat {{{/tb/dut/registers[35]} -radix decimal} {{/tb/dut/registers[34]} -radix decimal} {{/tb/dut/registers[33]} -radix decimal} {{/tb/dut/registers[32]} -radix decimal} {{/tb/dut/registers[31]} -radix decimal} {{/tb/dut/registers[30]} -radix decimal} {{/tb/dut/registers[29]} -radix decimal} {{/tb/dut/registers[28]} -radix decimal} {{/tb/dut/registers[27]} -radix decimal} {{/tb/dut/registers[26]} -radix decimal} {{/tb/dut/registers[25]} -radix decimal} {{/tb/dut/registers[24]} -radix decimal} {{/tb/dut/registers[23]} -radix decimal} {{/tb/dut/registers[22]} -radix decimal} {{/tb/dut/registers[21]} -radix decimal} {{/tb/dut/registers[20]} -radix decimal} {{/tb/dut/registers[19]} -radix decimal} {{/tb/dut/registers[18]} -radix decimal} {{/tb/dut/registers[17]} -radix decimal} {{/tb/dut/registers[16]} -radix decimal} {{/tb/dut/registers[15]} -radix decimal} {{/tb/dut/registers[14]} -radix decimal} {{/tb/dut/registers[13]} -radix decimal} {{/tb/dut/registers[12]} -radix decimal} {{/tb/dut/registers[11]} -radix decimal} {{/tb/dut/registers[10]} -radix decimal} {{/tb/dut/registers[9]} -radix decimal} {{/tb/dut/registers[8]} -radix decimal} {{/tb/dut/registers[7]} -radix decimal} {{/tb/dut/registers[6]} -radix decimal} {{/tb/dut/registers[5]} -radix decimal} {{/tb/dut/registers[4]} -radix decimal} {{/tb/dut/registers[3]} -radix decimal} {{/tb/dut/registers[2]} -radix decimal} {{/tb/dut/registers[1]} -radix decimal} {{/tb/dut/registers[0]} -radix decimal}} -expand -subitemconfig {{/tb/dut/registers[35]} {-radix decimal} {/tb/dut/registers[34]} {-radix decimal} {/tb/dut/registers[33]} {-radix decimal} {/tb/dut/registers[32]} {-radix decimal} {/tb/dut/registers[31]} {-radix decimal} {/tb/dut/registers[30]} {-radix decimal} {/tb/dut/registers[29]} {-radix decimal} {/tb/dut/registers[28]} {-radix decimal} {/tb/dut/registers[27]} {-radix decimal} {/tb/dut/registers[26]} {-radix decimal} {/tb/dut/registers[25]} {-radix decimal} {/tb/dut/registers[24]} {-radix decimal} {/tb/dut/registers[23]} {-radix decimal} {/tb/dut/registers[22]} {-radix decimal} {/tb/dut/registers[21]} {-radix decimal} {/tb/dut/registers[20]} {-radix decimal} {/tb/dut/registers[19]} {-radix decimal} {/tb/dut/registers[18]} {-radix decimal} {/tb/dut/registers[17]} {-radix decimal} {/tb/dut/registers[16]} {-radix decimal} {/tb/dut/registers[15]} {-radix decimal} {/tb/dut/registers[14]} {-radix decimal} {/tb/dut/registers[13]} {-radix decimal} {/tb/dut/registers[12]} {-radix decimal} {/tb/dut/registers[11]} {-radix decimal} {/tb/dut/registers[10]} {-radix decimal} {/tb/dut/registers[9]} {-radix decimal} {/tb/dut/registers[8]} {-radix decimal} {/tb/dut/registers[7]} {-radix decimal} {/tb/dut/registers[6]} {-radix decimal} {/tb/dut/registers[5]} {-radix decimal} {/tb/dut/registers[4]} {-radix decimal} {/tb/dut/registers[3]} {-radix decimal} {/tb/dut/registers[2]} {-radix decimal} {/tb/dut/registers[1]} {-radix decimal} {/tb/dut/registers[0]} {-radix decimal}} /tb/dut/registers
add wave -noupdate -radix decimal /tb/dut/prod_c
add wave -noupdate -radix decimal /tb/dut/prod_a
add wave -noupdate /tb/dut/product
add wave -noupdate -radix decimal /tb/dut/idx
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {35 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 300
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
WaveRestoreZoom {649 ns} {876 ns}
