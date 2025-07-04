onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/p_debug
add wave -noupdate /tb/dut/p_in_valid
add wave -noupdate /tb/dut/p_wh_valid
add wave -noupdate /tb/dut/p_out_valid
add wave -noupdate -radix decimal /tb/dut/p_in_data
add wave -noupdate -radix decimal /tb/dut/p_out_data
add wave -noupdate /tb/dut/next_st
add wave -noupdate /tb/dut/current_st
add wave -noupdate -radix decimal -childformat {{{/tb/dut/input_map[24]} -radix decimal} {{/tb/dut/input_map[23]} -radix decimal} {{/tb/dut/input_map[22]} -radix decimal} {{/tb/dut/input_map[21]} -radix decimal} {{/tb/dut/input_map[20]} -radix decimal} {{/tb/dut/input_map[19]} -radix decimal} {{/tb/dut/input_map[18]} -radix decimal} {{/tb/dut/input_map[17]} -radix decimal} {{/tb/dut/input_map[16]} -radix decimal} {{/tb/dut/input_map[15]} -radix decimal} {{/tb/dut/input_map[14]} -radix decimal} {{/tb/dut/input_map[13]} -radix decimal} {{/tb/dut/input_map[12]} -radix decimal} {{/tb/dut/input_map[11]} -radix decimal} {{/tb/dut/input_map[10]} -radix decimal} {{/tb/dut/input_map[9]} -radix decimal} {{/tb/dut/input_map[8]} -radix decimal} {{/tb/dut/input_map[7]} -radix decimal} {{/tb/dut/input_map[6]} -radix decimal} {{/tb/dut/input_map[5]} -radix decimal} {{/tb/dut/input_map[4]} -radix decimal} {{/tb/dut/input_map[3]} -radix decimal} {{/tb/dut/input_map[2]} -radix decimal} {{/tb/dut/input_map[1]} -radix decimal} {{/tb/dut/input_map[0]} -radix decimal}} -subitemconfig {{/tb/dut/input_map[24]} {-height 16 -radix decimal} {/tb/dut/input_map[23]} {-height 16 -radix decimal} {/tb/dut/input_map[22]} {-height 16 -radix decimal} {/tb/dut/input_map[21]} {-height 16 -radix decimal} {/tb/dut/input_map[20]} {-height 16 -radix decimal} {/tb/dut/input_map[19]} {-height 16 -radix decimal} {/tb/dut/input_map[18]} {-height 16 -radix decimal} {/tb/dut/input_map[17]} {-height 16 -radix decimal} {/tb/dut/input_map[16]} {-height 16 -radix decimal} {/tb/dut/input_map[15]} {-height 16 -radix decimal} {/tb/dut/input_map[14]} {-height 16 -radix decimal} {/tb/dut/input_map[13]} {-height 16 -radix decimal} {/tb/dut/input_map[12]} {-height 16 -radix decimal} {/tb/dut/input_map[11]} {-height 16 -radix decimal} {/tb/dut/input_map[10]} {-height 16 -radix decimal} {/tb/dut/input_map[9]} {-height 16 -radix decimal} {/tb/dut/input_map[8]} {-height 16 -radix decimal} {/tb/dut/input_map[7]} {-height 16 -radix decimal} {/tb/dut/input_map[6]} {-height 16 -radix decimal} {/tb/dut/input_map[5]} {-height 16 -radix decimal} {/tb/dut/input_map[4]} {-height 16 -radix decimal} {/tb/dut/input_map[3]} {-height 16 -radix decimal} {/tb/dut/input_map[2]} {-height 16 -radix decimal} {/tb/dut/input_map[1]} {-height 16 -radix decimal} {/tb/dut/input_map[0]} {-height 16 -radix decimal}} /tb/dut/input_map
add wave -noupdate -radix decimal -childformat {{{/tb/dut/output_map[8]} -radix decimal} {{/tb/dut/output_map[7]} -radix decimal} {{/tb/dut/output_map[6]} -radix decimal} {{/tb/dut/output_map[5]} -radix decimal} {{/tb/dut/output_map[4]} -radix decimal} {{/tb/dut/output_map[3]} -radix decimal} {{/tb/dut/output_map[2]} -radix decimal} {{/tb/dut/output_map[1]} -radix decimal} {{/tb/dut/output_map[0]} -radix decimal}} -subitemconfig {{/tb/dut/output_map[8]} {-height 16 -radix decimal} {/tb/dut/output_map[7]} {-height 16 -radix decimal} {/tb/dut/output_map[6]} {-height 16 -radix decimal} {/tb/dut/output_map[5]} {-height 16 -radix decimal} {/tb/dut/output_map[4]} {-height 16 -radix decimal} {/tb/dut/output_map[3]} {-height 16 -radix decimal} {/tb/dut/output_map[2]} {-height 16 -radix decimal} {/tb/dut/output_map[1]} {-height 16 -radix decimal} {/tb/dut/output_map[0]} {-height 16 -radix decimal}} /tb/dut/output_map
add wave -noupdate -radix decimal /tb/dut/parallel_out
add wave -noupdate /tb/dut/output_valid
add wave -noupdate -radix decimal /tb/dut/register_weight
add wave -noupdate -radix decimal /tb/dut/registers_in
add wave -noupdate -radix decimal /tb/dut/registers_out
add wave -noupdate /tb/dut/out_ce
add wave -noupdate /tb/dut/out_we
add wave -noupdate /tb/dut/out_valid
add wave -noupdate /tb/dut/serial_valid_in
add wave -noupdate /tb/dut/parallel_valid_in
add wave -noupdate /tb/dut/serial_valid_out
add wave -noupdate /tb/dut/parallel_valid_out
add wave -noupdate /tb/dut/count_to_serial
add wave -noupdate /tb/dut/count_to_parallel
add wave -noupdate /tb/dut/feature_out
add wave -noupdate /tb/dut/weight_out
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/p_debug
add wave -noupdate /tb/dut/p_in_valid
add wave -noupdate /tb/dut/p_wh_valid
add wave -noupdate /tb/dut/p_out_valid
add wave -noupdate -radix decimal /tb/dut/p_in_data
add wave -noupdate -radix decimal /tb/dut/p_out_data
add wave -noupdate /tb/dut/output_valid
add wave -noupdate /tb/dut/out_ce
add wave -noupdate /tb/dut/out_we
add wave -noupdate /tb/dut/out_valid
add wave -noupdate /tb/dut/serial_valid_in
add wave -noupdate /tb/dut/parallel_valid_in
add wave -noupdate /tb/dut/serial_valid_out
add wave -noupdate /tb/dut/parallel_valid_out
add wave -noupdate /tb/dut/count_to_serial
add wave -noupdate /tb/dut/count_to_parallel
add wave -noupdate /tb/dut/feature_out
add wave -noupdate /tb/dut/weight_out
add wave -noupdate /tb/dut/convolucao/clk
add wave -noupdate /tb/dut/convolucao/reset
add wave -noupdate /tb/dut/convolucao/start
add wave -noupdate -radix decimal /tb/dut/convolucao/inputMAP
add wave -noupdate -radix decimal -childformat {{{/tb/dut/convolucao/weights[35]} -radix decimal} {{/tb/dut/convolucao/weights[34]} -radix decimal} {{/tb/dut/convolucao/weights[33]} -radix decimal} {{/tb/dut/convolucao/weights[32]} -radix decimal} {{/tb/dut/convolucao/weights[31]} -radix decimal} {{/tb/dut/convolucao/weights[30]} -radix decimal} {{/tb/dut/convolucao/weights[29]} -radix decimal} {{/tb/dut/convolucao/weights[28]} -radix decimal} {{/tb/dut/convolucao/weights[27]} -radix decimal} {{/tb/dut/convolucao/weights[26]} -radix decimal} {{/tb/dut/convolucao/weights[25]} -radix decimal} {{/tb/dut/convolucao/weights[24]} -radix decimal} {{/tb/dut/convolucao/weights[23]} -radix decimal} {{/tb/dut/convolucao/weights[22]} -radix decimal} {{/tb/dut/convolucao/weights[21]} -radix decimal} {{/tb/dut/convolucao/weights[20]} -radix decimal} {{/tb/dut/convolucao/weights[19]} -radix decimal} {{/tb/dut/convolucao/weights[18]} -radix decimal} {{/tb/dut/convolucao/weights[17]} -radix decimal} {{/tb/dut/convolucao/weights[16]} -radix decimal} {{/tb/dut/convolucao/weights[15]} -radix decimal} {{/tb/dut/convolucao/weights[14]} -radix decimal} {{/tb/dut/convolucao/weights[13]} -radix decimal} {{/tb/dut/convolucao/weights[12]} -radix decimal} {{/tb/dut/convolucao/weights[11]} -radix decimal} {{/tb/dut/convolucao/weights[10]} -radix decimal} {{/tb/dut/convolucao/weights[9]} -radix decimal} {{/tb/dut/convolucao/weights[8]} -radix decimal} {{/tb/dut/convolucao/weights[7]} -radix decimal} {{/tb/dut/convolucao/weights[6]} -radix decimal} {{/tb/dut/convolucao/weights[5]} -radix decimal} {{/tb/dut/convolucao/weights[4]} -radix decimal} {{/tb/dut/convolucao/weights[3]} -radix decimal} {{/tb/dut/convolucao/weights[2]} -radix decimal} {{/tb/dut/convolucao/weights[1]} -radix decimal} {{/tb/dut/convolucao/weights[0]} -radix decimal}} -subitemconfig {{/tb/dut/convolucao/weights[35]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[34]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[33]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[32]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[31]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[30]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[29]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[28]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[27]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[26]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[25]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[24]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[23]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[22]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[21]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[20]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[19]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[18]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[17]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[16]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[15]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[14]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[13]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[12]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[11]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[10]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[9]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[8]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[7]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[6]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[5]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[4]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[3]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[2]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[1]} {-height 16 -radix decimal} {/tb/dut/convolucao/weights[0]} {-height 16 -radix decimal}} /tb/dut/convolucao/weights
add wave -noupdate -radix decimal /tb/dut/convolucao/outputMAP
add wave -noupdate /tb/dut/convolucao/data_valid
add wave -noupdate /tb/dut/convolucao/current_st
add wave -noupdate /tb/dut/convolucao/next_st
add wave -noupdate -radix decimal -childformat {{{/tb/dut/convolucao/registers[35]} -radix decimal} {{/tb/dut/convolucao/registers[34]} -radix decimal} {{/tb/dut/convolucao/registers[33]} -radix decimal} {{/tb/dut/convolucao/registers[32]} -radix decimal} {{/tb/dut/convolucao/registers[31]} -radix decimal} {{/tb/dut/convolucao/registers[30]} -radix decimal} {{/tb/dut/convolucao/registers[29]} -radix decimal} {{/tb/dut/convolucao/registers[28]} -radix decimal} {{/tb/dut/convolucao/registers[27]} -radix decimal} {{/tb/dut/convolucao/registers[26]} -radix decimal} {{/tb/dut/convolucao/registers[25]} -radix decimal} {{/tb/dut/convolucao/registers[24]} -radix decimal} {{/tb/dut/convolucao/registers[23]} -radix decimal} {{/tb/dut/convolucao/registers[22]} -radix decimal} {{/tb/dut/convolucao/registers[21]} -radix decimal} {{/tb/dut/convolucao/registers[20]} -radix decimal} {{/tb/dut/convolucao/registers[19]} -radix decimal} {{/tb/dut/convolucao/registers[18]} -radix decimal} {{/tb/dut/convolucao/registers[17]} -radix decimal} {{/tb/dut/convolucao/registers[16]} -radix decimal} {{/tb/dut/convolucao/registers[15]} -radix decimal} {{/tb/dut/convolucao/registers[14]} -radix decimal} {{/tb/dut/convolucao/registers[13]} -radix decimal} {{/tb/dut/convolucao/registers[12]} -radix decimal} {{/tb/dut/convolucao/registers[11]} -radix decimal} {{/tb/dut/convolucao/registers[10]} -radix decimal} {{/tb/dut/convolucao/registers[9]} -radix decimal} {{/tb/dut/convolucao/registers[8]} -radix decimal} {{/tb/dut/convolucao/registers[7]} -radix decimal} {{/tb/dut/convolucao/registers[6]} -radix decimal} {{/tb/dut/convolucao/registers[5]} -radix decimal} {{/tb/dut/convolucao/registers[4]} -radix decimal} {{/tb/dut/convolucao/registers[3]} -radix decimal} {{/tb/dut/convolucao/registers[2]} -radix decimal} {{/tb/dut/convolucao/registers[1]} -radix decimal} {{/tb/dut/convolucao/registers[0]} -radix decimal}} -subitemconfig {{/tb/dut/convolucao/registers[35]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[34]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[33]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[32]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[31]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[30]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[29]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[28]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[27]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[26]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[25]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[24]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[23]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[22]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[21]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[20]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[19]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[18]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[17]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[16]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[15]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[14]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[13]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[12]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[11]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[10]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[9]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[8]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[7]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[6]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[5]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[4]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[3]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[2]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[1]} {-height 16 -radix decimal} {/tb/dut/convolucao/registers[0]} {-height 16 -radix decimal}} /tb/dut/convolucao/registers
add wave -noupdate -radix decimal /tb/dut/convolucao/prod_c0
add wave -noupdate -radix decimal /tb/dut/convolucao/prod_c
add wave -noupdate -radix decimal /tb/dut/convolucao/prod_a
add wave -noupdate /tb/dut/convolucao/product
add wave -noupdate /tb/dut/convolucao/idx
add wave -noupdate /tb/dut/core_control/clk
add wave -noupdate /tb/dut/core_control/reset
add wave -noupdate /tb/dut/core_control/feature_in
add wave -noupdate /tb/dut/core_control/weight_in
add wave -noupdate /tb/dut/core_control/serial_valid_in
add wave -noupdate -radix decimal /tb/dut/core_control/serial_in
add wave -noupdate /tb/dut/core_control/feature_out
add wave -noupdate /tb/dut/core_control/weight_out
add wave -noupdate /tb/dut/core_control/parallel_valid_out
add wave -noupdate -radix decimal /tb/dut/core_control/parallel_out
add wave -noupdate /tb/dut/core_control/parallel_valid_in
add wave -noupdate -radix decimal /tb/dut/core_control/parallel_in
add wave -noupdate /tb/dut/core_control/serial_valid_out
add wave -noupdate -radix decimal /tb/dut/core_control/serial_out
add wave -noupdate /tb/dut/core_control/end_serial_out
add wave -noupdate /tb/dut/core_control/current_st_to_serial
add wave -noupdate /tb/dut/core_control/next_st_to_serial
add wave -noupdate /tb/dut/core_control/current_st_to_parallel
add wave -noupdate /tb/dut/core_control/next_st_to_parallel
add wave -noupdate -radix decimal /tb/dut/core_control/registers_out
add wave -noupdate /tb/dut/core_control/reg_feature
add wave -noupdate /tb/dut/core_control/reg_weight
add wave -noupdate /tb/dut/core_control/count_to_serial
add wave -noupdate /tb/dut/core_control/count_to_parallel
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {319 ns} 0}
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
WaveRestoreZoom {0 ns} {227 ns}
