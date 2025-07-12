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
add wave -noupdate -radix decimal -childformat {{{/tb/dut/register_weight[35]} -radix decimal} {{/tb/dut/register_weight[34]} -radix decimal} {{/tb/dut/register_weight[33]} -radix decimal} {{/tb/dut/register_weight[32]} -radix decimal} {{/tb/dut/register_weight[31]} -radix decimal} {{/tb/dut/register_weight[30]} -radix decimal} {{/tb/dut/register_weight[29]} -radix decimal} {{/tb/dut/register_weight[28]} -radix decimal} {{/tb/dut/register_weight[27]} -radix decimal} {{/tb/dut/register_weight[26]} -radix decimal} {{/tb/dut/register_weight[25]} -radix decimal} {{/tb/dut/register_weight[24]} -radix decimal} {{/tb/dut/register_weight[23]} -radix decimal} {{/tb/dut/register_weight[22]} -radix decimal} {{/tb/dut/register_weight[21]} -radix decimal} {{/tb/dut/register_weight[20]} -radix decimal} {{/tb/dut/register_weight[19]} -radix decimal} {{/tb/dut/register_weight[18]} -radix decimal} {{/tb/dut/register_weight[17]} -radix decimal} {{/tb/dut/register_weight[16]} -radix decimal} {{/tb/dut/register_weight[15]} -radix decimal} {{/tb/dut/register_weight[14]} -radix decimal} {{/tb/dut/register_weight[13]} -radix decimal} {{/tb/dut/register_weight[12]} -radix decimal} {{/tb/dut/register_weight[11]} -radix decimal} {{/tb/dut/register_weight[10]} -radix decimal} {{/tb/dut/register_weight[9]} -radix decimal} {{/tb/dut/register_weight[8]} -radix decimal} {{/tb/dut/register_weight[7]} -radix decimal} {{/tb/dut/register_weight[6]} -radix decimal} {{/tb/dut/register_weight[5]} -radix decimal} {{/tb/dut/register_weight[4]} -radix decimal} {{/tb/dut/register_weight[3]} -radix decimal} {{/tb/dut/register_weight[2]} -radix decimal} {{/tb/dut/register_weight[1]} -radix decimal} {{/tb/dut/register_weight[0]} -radix decimal}} -expand -subitemconfig {{/tb/dut/register_weight[35]} {-radix decimal} {/tb/dut/register_weight[34]} {-radix decimal} {/tb/dut/register_weight[33]} {-radix decimal} {/tb/dut/register_weight[32]} {-radix decimal} {/tb/dut/register_weight[31]} {-radix decimal} {/tb/dut/register_weight[30]} {-radix decimal} {/tb/dut/register_weight[29]} {-radix decimal} {/tb/dut/register_weight[28]} {-radix decimal} {/tb/dut/register_weight[27]} {-radix decimal} {/tb/dut/register_weight[26]} {-radix decimal} {/tb/dut/register_weight[25]} {-radix decimal} {/tb/dut/register_weight[24]} {-radix decimal} {/tb/dut/register_weight[23]} {-radix decimal} {/tb/dut/register_weight[22]} {-radix decimal} {/tb/dut/register_weight[21]} {-radix decimal} {/tb/dut/register_weight[20]} {-radix decimal} {/tb/dut/register_weight[19]} {-radix decimal} {/tb/dut/register_weight[18]} {-radix decimal} {/tb/dut/register_weight[17]} {-radix decimal} {/tb/dut/register_weight[16]} {-radix decimal} {/tb/dut/register_weight[15]} {-radix decimal} {/tb/dut/register_weight[14]} {-radix decimal} {/tb/dut/register_weight[13]} {-radix decimal} {/tb/dut/register_weight[12]} {-radix decimal} {/tb/dut/register_weight[11]} {-radix decimal} {/tb/dut/register_weight[10]} {-radix decimal} {/tb/dut/register_weight[9]} {-radix decimal} {/tb/dut/register_weight[8]} {-radix decimal} {/tb/dut/register_weight[7]} {-radix decimal} {/tb/dut/register_weight[6]} {-radix decimal} {/tb/dut/register_weight[5]} {-radix decimal} {/tb/dut/register_weight[4]} {-radix decimal} {/tb/dut/register_weight[3]} {-radix decimal} {/tb/dut/register_weight[2]} {-radix decimal} {/tb/dut/register_weight[1]} {-radix decimal} {/tb/dut/register_weight[0]} {-radix decimal}} /tb/dut/register_weight
add wave -noupdate -radix decimal /tb/dut/registers_out
add wave -noupdate /tb/dut/out_ce
add wave -noupdate /tb/dut/out_we
add wave -noupdate /tb/dut/s_end
add wave -noupdate /tb/dut/start_conv
add wave -noupdate /tb/dut/serial_valid_in
add wave -noupdate /tb/dut/serial_data_in
add wave -noupdate /tb/dut/parallel_valid_out
add wave -noupdate /tb/dut/parallel_data_out
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
WaveRestoreCursors {{Cursor 1} {407 ns} 0}
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
WaveRestoreZoom {200 ns} {427 ns}
