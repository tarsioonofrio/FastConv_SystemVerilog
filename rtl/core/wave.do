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
add wave -noupdate -radix decimal /tb/dut/output_map
add wave -noupdate -radix decimal -childformat {{{/tb/dut/register_weight[35]} -radix decimal} {{/tb/dut/register_weight[34]} -radix decimal} {{/tb/dut/register_weight[33]} -radix decimal} {{/tb/dut/register_weight[32]} -radix decimal} {{/tb/dut/register_weight[31]} -radix decimal} {{/tb/dut/register_weight[30]} -radix decimal} {{/tb/dut/register_weight[29]} -radix decimal} {{/tb/dut/register_weight[28]} -radix decimal} {{/tb/dut/register_weight[27]} -radix decimal} {{/tb/dut/register_weight[26]} -radix decimal} {{/tb/dut/register_weight[25]} -radix decimal} {{/tb/dut/register_weight[24]} -radix decimal} {{/tb/dut/register_weight[23]} -radix decimal} {{/tb/dut/register_weight[22]} -radix decimal} {{/tb/dut/register_weight[21]} -radix decimal} {{/tb/dut/register_weight[20]} -radix decimal} {{/tb/dut/register_weight[19]} -radix decimal} {{/tb/dut/register_weight[18]} -radix decimal} {{/tb/dut/register_weight[17]} -radix decimal} {{/tb/dut/register_weight[16]} -radix decimal} {{/tb/dut/register_weight[15]} -radix decimal} {{/tb/dut/register_weight[14]} -radix decimal} {{/tb/dut/register_weight[13]} -radix decimal} {{/tb/dut/register_weight[12]} -radix decimal} {{/tb/dut/register_weight[11]} -radix decimal} {{/tb/dut/register_weight[10]} -radix decimal} {{/tb/dut/register_weight[9]} -radix decimal} {{/tb/dut/register_weight[8]} -radix decimal} {{/tb/dut/register_weight[7]} -radix decimal} {{/tb/dut/register_weight[6]} -radix decimal} {{/tb/dut/register_weight[5]} -radix decimal} {{/tb/dut/register_weight[4]} -radix decimal} {{/tb/dut/register_weight[3]} -radix decimal} {{/tb/dut/register_weight[2]} -radix decimal} {{/tb/dut/register_weight[1]} -radix decimal} {{/tb/dut/register_weight[0]} -radix decimal}} -expand -subitemconfig {{/tb/dut/register_weight[35]} {-height 16 -radix decimal} {/tb/dut/register_weight[34]} {-height 16 -radix decimal} {/tb/dut/register_weight[33]} {-height 16 -radix decimal} {/tb/dut/register_weight[32]} {-height 16 -radix decimal} {/tb/dut/register_weight[31]} {-height 16 -radix decimal} {/tb/dut/register_weight[30]} {-height 16 -radix decimal} {/tb/dut/register_weight[29]} {-height 16 -radix decimal} {/tb/dut/register_weight[28]} {-height 16 -radix decimal} {/tb/dut/register_weight[27]} {-height 16 -radix decimal} {/tb/dut/register_weight[26]} {-height 16 -radix decimal} {/tb/dut/register_weight[25]} {-height 16 -radix decimal} {/tb/dut/register_weight[24]} {-height 16 -radix decimal} {/tb/dut/register_weight[23]} {-height 16 -radix decimal} {/tb/dut/register_weight[22]} {-height 16 -radix decimal} {/tb/dut/register_weight[21]} {-height 16 -radix decimal} {/tb/dut/register_weight[20]} {-height 16 -radix decimal} {/tb/dut/register_weight[19]} {-height 16 -radix decimal} {/tb/dut/register_weight[18]} {-height 16 -radix decimal} {/tb/dut/register_weight[17]} {-height 16 -radix decimal} {/tb/dut/register_weight[16]} {-height 16 -radix decimal} {/tb/dut/register_weight[15]} {-height 16 -radix decimal} {/tb/dut/register_weight[14]} {-height 16 -radix decimal} {/tb/dut/register_weight[13]} {-height 16 -radix decimal} {/tb/dut/register_weight[12]} {-height 16 -radix decimal} {/tb/dut/register_weight[11]} {-height 16 -radix decimal} {/tb/dut/register_weight[10]} {-height 16 -radix decimal} {/tb/dut/register_weight[9]} {-height 16 -radix decimal} {/tb/dut/register_weight[8]} {-height 16 -radix decimal} {/tb/dut/register_weight[7]} {-height 16 -radix decimal} {/tb/dut/register_weight[6]} {-height 16 -radix decimal} {/tb/dut/register_weight[5]} {-height 16 -radix decimal} {/tb/dut/register_weight[4]} {-height 16 -radix decimal} {/tb/dut/register_weight[3]} {-height 16 -radix decimal} {/tb/dut/register_weight[2]} {-height 16 -radix decimal} {/tb/dut/register_weight[1]} {-height 16 -radix decimal} {/tb/dut/register_weight[0]} {-height 16 -radix decimal}} /tb/dut/register_weight
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
add wave -noupdate /tb/dut/count_to_serial
add wave -noupdate -radix decimal /tb/dut/inputMAP
add wave -noupdate -radix decimal /tb/dut/weights
add wave -noupdate -radix decimal /tb/dut/outputMAP
add wave -noupdate /tb/dut/data_valid
add wave -noupdate /tb/dut/start
add wave -noupdate /tb/dut/current_st_conv
add wave -noupdate /tb/dut/next_st_conv
add wave -noupdate /tb/dut/count_to_parallel
add wave -noupdate -radix decimal -childformat {{{/tb/dut/registers[35]} -radix decimal} {{/tb/dut/registers[34]} -radix decimal} {{/tb/dut/registers[33]} -radix decimal} {{/tb/dut/registers[32]} -radix decimal} {{/tb/dut/registers[31]} -radix decimal} {{/tb/dut/registers[30]} -radix decimal} {{/tb/dut/registers[29]} -radix decimal} {{/tb/dut/registers[28]} -radix decimal} {{/tb/dut/registers[27]} -radix decimal} {{/tb/dut/registers[26]} -radix decimal} {{/tb/dut/registers[25]} -radix decimal} {{/tb/dut/registers[24]} -radix decimal} {{/tb/dut/registers[23]} -radix decimal} {{/tb/dut/registers[22]} -radix decimal} {{/tb/dut/registers[21]} -radix decimal} {{/tb/dut/registers[20]} -radix decimal} {{/tb/dut/registers[19]} -radix decimal} {{/tb/dut/registers[18]} -radix decimal} {{/tb/dut/registers[17]} -radix decimal} {{/tb/dut/registers[16]} -radix decimal} {{/tb/dut/registers[15]} -radix decimal} {{/tb/dut/registers[14]} -radix decimal} {{/tb/dut/registers[13]} -radix decimal} {{/tb/dut/registers[12]} -radix decimal} {{/tb/dut/registers[11]} -radix decimal} {{/tb/dut/registers[10]} -radix decimal} {{/tb/dut/registers[9]} -radix decimal} {{/tb/dut/registers[8]} -radix decimal} {{/tb/dut/registers[7]} -radix decimal} {{/tb/dut/registers[6]} -radix decimal} {{/tb/dut/registers[5]} -radix decimal} {{/tb/dut/registers[4]} -radix decimal} {{/tb/dut/registers[3]} -radix decimal} {{/tb/dut/registers[2]} -radix decimal} {{/tb/dut/registers[1]} -radix decimal} {{/tb/dut/registers[0]} -radix decimal}} -expand -subitemconfig {{/tb/dut/registers[35]} {-height 16 -radix decimal} {/tb/dut/registers[34]} {-height 16 -radix decimal} {/tb/dut/registers[33]} {-height 16 -radix decimal} {/tb/dut/registers[32]} {-height 16 -radix decimal} {/tb/dut/registers[31]} {-height 16 -radix decimal} {/tb/dut/registers[30]} {-height 16 -radix decimal} {/tb/dut/registers[29]} {-height 16 -radix decimal} {/tb/dut/registers[28]} {-height 16 -radix decimal} {/tb/dut/registers[27]} {-height 16 -radix decimal} {/tb/dut/registers[26]} {-height 16 -radix decimal} {/tb/dut/registers[25]} {-height 16 -radix decimal} {/tb/dut/registers[24]} {-height 16 -radix decimal} {/tb/dut/registers[23]} {-height 16 -radix decimal} {/tb/dut/registers[22]} {-height 16 -radix decimal} {/tb/dut/registers[21]} {-height 16 -radix decimal} {/tb/dut/registers[20]} {-height 16 -radix decimal} {/tb/dut/registers[19]} {-height 16 -radix decimal} {/tb/dut/registers[18]} {-height 16 -radix decimal} {/tb/dut/registers[17]} {-height 16 -radix decimal} {/tb/dut/registers[16]} {-height 16 -radix decimal} {/tb/dut/registers[15]} {-height 16 -radix decimal} {/tb/dut/registers[14]} {-height 16 -radix decimal} {/tb/dut/registers[13]} {-height 16 -radix decimal} {/tb/dut/registers[12]} {-height 16 -radix decimal} {/tb/dut/registers[11]} {-height 16 -radix decimal} {/tb/dut/registers[10]} {-height 16 -radix decimal} {/tb/dut/registers[9]} {-height 16 -radix decimal} {/tb/dut/registers[8]} {-height 16 -radix decimal} {/tb/dut/registers[7]} {-height 16 -radix decimal} {/tb/dut/registers[6]} {-height 16 -radix decimal} {/tb/dut/registers[5]} {-height 16 -radix decimal} {/tb/dut/registers[4]} {-height 16 -radix decimal} {/tb/dut/registers[3]} {-height 16 -radix decimal} {/tb/dut/registers[2]} {-height 16 -radix decimal} {/tb/dut/registers[1]} {-height 16 -radix decimal} {/tb/dut/registers[0]} {-height 16 -radix decimal}} /tb/dut/registers
add wave -noupdate -radix decimal /tb/dut/prod_c
add wave -noupdate -radix decimal /tb/dut/prod_a
add wave -noupdate -radix decimal -childformat {{{/tb/dut/product[27]} -radix decimal} {{/tb/dut/product[26]} -radix decimal} {{/tb/dut/product[25]} -radix decimal} {{/tb/dut/product[24]} -radix decimal} {{/tb/dut/product[23]} -radix decimal} {{/tb/dut/product[22]} -radix decimal} {{/tb/dut/product[21]} -radix decimal} {{/tb/dut/product[20]} -radix decimal} {{/tb/dut/product[19]} -radix decimal} {{/tb/dut/product[18]} -radix decimal} {{/tb/dut/product[17]} -radix decimal} {{/tb/dut/product[16]} -radix decimal} {{/tb/dut/product[15]} -radix decimal} {{/tb/dut/product[14]} -radix decimal} {{/tb/dut/product[13]} -radix decimal} {{/tb/dut/product[12]} -radix decimal} {{/tb/dut/product[11]} -radix decimal} {{/tb/dut/product[10]} -radix decimal} {{/tb/dut/product[9]} -radix decimal} {{/tb/dut/product[8]} -radix decimal} {{/tb/dut/product[7]} -radix decimal} {{/tb/dut/product[6]} -radix decimal} {{/tb/dut/product[5]} -radix decimal} {{/tb/dut/product[4]} -radix decimal} {{/tb/dut/product[3]} -radix decimal} {{/tb/dut/product[2]} -radix decimal} {{/tb/dut/product[1]} -radix decimal} {{/tb/dut/product[0]} -radix decimal}} -subitemconfig {{/tb/dut/product[27]} {-height 16 -radix decimal} {/tb/dut/product[26]} {-height 16 -radix decimal} {/tb/dut/product[25]} {-height 16 -radix decimal} {/tb/dut/product[24]} {-height 16 -radix decimal} {/tb/dut/product[23]} {-height 16 -radix decimal} {/tb/dut/product[22]} {-height 16 -radix decimal} {/tb/dut/product[21]} {-height 16 -radix decimal} {/tb/dut/product[20]} {-height 16 -radix decimal} {/tb/dut/product[19]} {-height 16 -radix decimal} {/tb/dut/product[18]} {-height 16 -radix decimal} {/tb/dut/product[17]} {-height 16 -radix decimal} {/tb/dut/product[16]} {-height 16 -radix decimal} {/tb/dut/product[15]} {-height 16 -radix decimal} {/tb/dut/product[14]} {-height 16 -radix decimal} {/tb/dut/product[13]} {-height 16 -radix decimal} {/tb/dut/product[12]} {-height 16 -radix decimal} {/tb/dut/product[11]} {-height 16 -radix decimal} {/tb/dut/product[10]} {-height 16 -radix decimal} {/tb/dut/product[9]} {-height 16 -radix decimal} {/tb/dut/product[8]} {-height 16 -radix decimal} {/tb/dut/product[7]} {-height 16 -radix decimal} {/tb/dut/product[6]} {-height 16 -radix decimal} {/tb/dut/product[5]} {-height 16 -radix decimal} {/tb/dut/product[4]} {-height 16 -radix decimal} {/tb/dut/product[3]} {-height 16 -radix decimal} {/tb/dut/product[2]} {-height 16 -radix decimal} {/tb/dut/product[1]} {-height 16 -radix decimal} {/tb/dut/product[0]} {-height 16 -radix decimal}} /tb/dut/product
add wave -noupdate -radix decimal /tb/dut/idx
add wave -noupdate /tb/dut/s_debug
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {728 ns} 0}
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
WaveRestoreZoom {583 ns} {814 ns}
