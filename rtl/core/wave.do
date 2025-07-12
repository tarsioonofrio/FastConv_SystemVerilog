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
add wave -noupdate /tb/dut/p_out_data
add wave -noupdate /tb/dut/current_st
add wave -noupdate /tb/dut/next_st
add wave -noupdate -radix decimal /tb/dut/input_map
add wave -noupdate -radix decimal /tb/dut/output_map
add wave -noupdate -radix decimal -childformat {{{/tb/dut/register_weight[35]} -radix decimal} {{/tb/dut/register_weight[34]} -radix decimal} {{/tb/dut/register_weight[33]} -radix decimal} {{/tb/dut/register_weight[32]} -radix decimal} {{/tb/dut/register_weight[31]} -radix decimal} {{/tb/dut/register_weight[30]} -radix decimal} {{/tb/dut/register_weight[29]} -radix decimal} {{/tb/dut/register_weight[28]} -radix decimal} {{/tb/dut/register_weight[27]} -radix decimal} {{/tb/dut/register_weight[26]} -radix decimal} {{/tb/dut/register_weight[25]} -radix decimal} {{/tb/dut/register_weight[24]} -radix decimal} {{/tb/dut/register_weight[23]} -radix decimal} {{/tb/dut/register_weight[22]} -radix decimal} {{/tb/dut/register_weight[21]} -radix decimal} {{/tb/dut/register_weight[20]} -radix decimal} {{/tb/dut/register_weight[19]} -radix decimal} {{/tb/dut/register_weight[18]} -radix decimal} {{/tb/dut/register_weight[17]} -radix decimal} {{/tb/dut/register_weight[16]} -radix decimal} {{/tb/dut/register_weight[15]} -radix decimal} {{/tb/dut/register_weight[14]} -radix decimal} {{/tb/dut/register_weight[13]} -radix decimal} {{/tb/dut/register_weight[12]} -radix decimal} {{/tb/dut/register_weight[11]} -radix decimal} {{/tb/dut/register_weight[10]} -radix decimal} {{/tb/dut/register_weight[9]} -radix decimal} {{/tb/dut/register_weight[8]} -radix decimal} {{/tb/dut/register_weight[7]} -radix decimal} {{/tb/dut/register_weight[6]} -radix decimal} {{/tb/dut/register_weight[5]} -radix decimal} {{/tb/dut/register_weight[4]} -radix decimal} {{/tb/dut/register_weight[3]} -radix decimal} {{/tb/dut/register_weight[2]} -radix decimal} {{/tb/dut/register_weight[1]} -radix decimal} {{/tb/dut/register_weight[0]} -radix decimal}} -expand -subitemconfig {{/tb/dut/register_weight[35]} {-height 16 -radix decimal} {/tb/dut/register_weight[34]} {-height 16 -radix decimal} {/tb/dut/register_weight[33]} {-height 16 -radix decimal} {/tb/dut/register_weight[32]} {-height 16 -radix decimal} {/tb/dut/register_weight[31]} {-height 16 -radix decimal} {/tb/dut/register_weight[30]} {-height 16 -radix decimal} {/tb/dut/register_weight[29]} {-height 16 -radix decimal} {/tb/dut/register_weight[28]} {-height 16 -radix decimal} {/tb/dut/register_weight[27]} {-height 16 -radix decimal} {/tb/dut/register_weight[26]} {-height 16 -radix decimal} {/tb/dut/register_weight[25]} {-height 16 -radix decimal} {/tb/dut/register_weight[24]} {-height 16 -radix decimal} {/tb/dut/register_weight[23]} {-height 16 -radix decimal} {/tb/dut/register_weight[22]} {-height 16 -radix decimal} {/tb/dut/register_weight[21]} {-height 16 -radix decimal} {/tb/dut/register_weight[20]} {-height 16 -radix decimal} {/tb/dut/register_weight[19]} {-height 16 -radix decimal} {/tb/dut/register_weight[18]} {-height 16 -radix decimal} {/tb/dut/register_weight[17]} {-height 16 -radix decimal} {/tb/dut/register_weight[16]} {-height 16 -radix decimal} {/tb/dut/register_weight[15]} {-height 16 -radix decimal} {/tb/dut/register_weight[14]} {-height 16 -radix decimal} {/tb/dut/register_weight[13]} {-height 16 -radix decimal} {/tb/dut/register_weight[12]} {-height 16 -radix decimal} {/tb/dut/register_weight[11]} {-height 16 -radix decimal} {/tb/dut/register_weight[10]} {-height 16 -radix decimal} {/tb/dut/register_weight[9]} {-height 16 -radix decimal} {/tb/dut/register_weight[8]} {-height 16 -radix decimal} {/tb/dut/register_weight[7]} {-height 16 -radix decimal} {/tb/dut/register_weight[6]} {-height 16 -radix decimal} {/tb/dut/register_weight[5]} {-height 16 -radix decimal} {/tb/dut/register_weight[4]} {-height 16 -radix decimal} {/tb/dut/register_weight[3]} {-height 16 -radix decimal} {/tb/dut/register_weight[2]} {-height 16 -radix decimal} {/tb/dut/register_weight[1]} {-height 16 -radix decimal} {/tb/dut/register_weight[0]} {-height 16 -radix decimal}} /tb/dut/register_weight
add wave -noupdate -radix decimal /tb/dut/registers_out
add wave -noupdate /tb/dut/out_ce
add wave -noupdate /tb/dut/out_we
add wave -noupdate /tb/dut/s_end
add wave -noupdate /tb/dut/start_conv
add wave -noupdate /tb/dut/serial_valid_in
add wave -noupdate -radix decimal /tb/dut/serial_data_in
add wave -noupdate /tb/dut/parallel_valid_out
add wave -noupdate -radix decimal -childformat {{{/tb/dut/parallel_data_out[35]} -radix decimal} {{/tb/dut/parallel_data_out[34]} -radix decimal} {{/tb/dut/parallel_data_out[33]} -radix decimal} {{/tb/dut/parallel_data_out[32]} -radix decimal} {{/tb/dut/parallel_data_out[31]} -radix decimal} {{/tb/dut/parallel_data_out[30]} -radix decimal} {{/tb/dut/parallel_data_out[29]} -radix decimal} {{/tb/dut/parallel_data_out[28]} -radix decimal} {{/tb/dut/parallel_data_out[27]} -radix decimal} {{/tb/dut/parallel_data_out[26]} -radix decimal} {{/tb/dut/parallel_data_out[25]} -radix decimal} {{/tb/dut/parallel_data_out[24]} -radix decimal} {{/tb/dut/parallel_data_out[23]} -radix decimal} {{/tb/dut/parallel_data_out[22]} -radix decimal} {{/tb/dut/parallel_data_out[21]} -radix decimal} {{/tb/dut/parallel_data_out[20]} -radix decimal} {{/tb/dut/parallel_data_out[19]} -radix decimal} {{/tb/dut/parallel_data_out[18]} -radix decimal} {{/tb/dut/parallel_data_out[17]} -radix decimal} {{/tb/dut/parallel_data_out[16]} -radix decimal} {{/tb/dut/parallel_data_out[15]} -radix decimal} {{/tb/dut/parallel_data_out[14]} -radix decimal} {{/tb/dut/parallel_data_out[13]} -radix decimal} {{/tb/dut/parallel_data_out[12]} -radix decimal} {{/tb/dut/parallel_data_out[11]} -radix decimal} {{/tb/dut/parallel_data_out[10]} -radix decimal} {{/tb/dut/parallel_data_out[9]} -radix decimal} {{/tb/dut/parallel_data_out[8]} -radix decimal} {{/tb/dut/parallel_data_out[7]} -radix decimal} {{/tb/dut/parallel_data_out[6]} -radix decimal} {{/tb/dut/parallel_data_out[5]} -radix decimal} {{/tb/dut/parallel_data_out[4]} -radix decimal} {{/tb/dut/parallel_data_out[3]} -radix decimal} {{/tb/dut/parallel_data_out[2]} -radix decimal} {{/tb/dut/parallel_data_out[1]} -radix decimal} {{/tb/dut/parallel_data_out[0]} -radix decimal}} -subitemconfig {{/tb/dut/parallel_data_out[35]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[34]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[33]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[32]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[31]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[30]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[29]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[28]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[27]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[26]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[25]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[24]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[23]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[22]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[21]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[20]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[19]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[18]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[17]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[16]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[15]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[14]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[13]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[12]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[11]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[10]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[9]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[8]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[7]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[6]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[5]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[4]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[3]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[2]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[1]} {-height 16 -radix decimal} {/tb/dut/parallel_data_out[0]} {-height 16 -radix decimal}} /tb/dut/parallel_data_out
add wave -noupdate /tb/dut/parallel_valid_in
add wave -noupdate /tb/dut/parallel_data_in
add wave -noupdate /tb/dut/serial_valid_out
add wave -noupdate /tb/dut/serial_data_out
add wave -noupdate /tb/dut/output_valid
add wave -noupdate /tb/dut/current_st_to_serial
add wave -noupdate /tb/dut/next_st_to_serial
add wave -noupdate /tb/dut/current_st_to_parallel
add wave -noupdate /tb/dut/next_st_to_parallel
add wave -noupdate /tb/dut/count_to_serial
add wave -noupdate /tb/dut/count_to_parallel
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
WaveRestoreZoom {0 ns} {227 ns}
