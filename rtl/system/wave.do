onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/w_conv_start
add wave -noupdate /tb/dut/w_conv_end
add wave -noupdate -radix unsigned -childformat {{{/tb/dut/w_input[24]} -radix unsigned} {{/tb/dut/w_input[23]} -radix unsigned} {{/tb/dut/w_input[22]} -radix unsigned} {{/tb/dut/w_input[21]} -radix unsigned} {{/tb/dut/w_input[20]} -radix unsigned} {{/tb/dut/w_input[19]} -radix unsigned} {{/tb/dut/w_input[18]} -radix unsigned} {{/tb/dut/w_input[17]} -radix unsigned} {{/tb/dut/w_input[16]} -radix unsigned} {{/tb/dut/w_input[15]} -radix unsigned} {{/tb/dut/w_input[14]} -radix unsigned} {{/tb/dut/w_input[13]} -radix unsigned} {{/tb/dut/w_input[12]} -radix unsigned} {{/tb/dut/w_input[11]} -radix unsigned} {{/tb/dut/w_input[10]} -radix unsigned} {{/tb/dut/w_input[9]} -radix unsigned} {{/tb/dut/w_input[8]} -radix unsigned} {{/tb/dut/w_input[7]} -radix unsigned} {{/tb/dut/w_input[6]} -radix unsigned} {{/tb/dut/w_input[5]} -radix unsigned} {{/tb/dut/w_input[4]} -radix unsigned} {{/tb/dut/w_input[3]} -radix unsigned} {{/tb/dut/w_input[2]} -radix unsigned} {{/tb/dut/w_input[1]} -radix unsigned} {{/tb/dut/w_input[0]} -radix unsigned}} -expand -subitemconfig {{/tb/dut/w_input[24]} {-radix unsigned} {/tb/dut/w_input[23]} {-radix unsigned} {/tb/dut/w_input[22]} {-radix unsigned} {/tb/dut/w_input[21]} {-radix unsigned} {/tb/dut/w_input[20]} {-radix unsigned} {/tb/dut/w_input[19]} {-radix unsigned} {/tb/dut/w_input[18]} {-radix unsigned} {/tb/dut/w_input[17]} {-radix unsigned} {/tb/dut/w_input[16]} {-radix unsigned} {/tb/dut/w_input[15]} {-radix unsigned} {/tb/dut/w_input[14]} {-radix unsigned} {/tb/dut/w_input[13]} {-radix unsigned} {/tb/dut/w_input[12]} {-radix unsigned} {/tb/dut/w_input[11]} {-radix unsigned} {/tb/dut/w_input[10]} {-radix unsigned} {/tb/dut/w_input[9]} {-radix unsigned} {/tb/dut/w_input[8]} {-radix unsigned} {/tb/dut/w_input[7]} {-radix unsigned} {/tb/dut/w_input[6]} {-radix unsigned} {/tb/dut/w_input[5]} {-radix unsigned} {/tb/dut/w_input[4]} {-radix unsigned} {/tb/dut/w_input[3]} {-radix unsigned} {/tb/dut/w_input[2]} {-radix unsigned} {/tb/dut/w_input[1]} {-radix unsigned} {/tb/dut/w_input[0]} {-radix unsigned}} /tb/dut/w_input
add wave -noupdate -radix unsigned -childformat {{{/tb/dut/w_weight[35]} -radix unsigned} {{/tb/dut/w_weight[34]} -radix unsigned} {{/tb/dut/w_weight[33]} -radix unsigned} {{/tb/dut/w_weight[32]} -radix unsigned} {{/tb/dut/w_weight[31]} -radix unsigned} {{/tb/dut/w_weight[30]} -radix unsigned} {{/tb/dut/w_weight[29]} -radix unsigned} {{/tb/dut/w_weight[28]} -radix unsigned} {{/tb/dut/w_weight[27]} -radix unsigned} {{/tb/dut/w_weight[26]} -radix unsigned} {{/tb/dut/w_weight[25]} -radix unsigned} {{/tb/dut/w_weight[24]} -radix unsigned} {{/tb/dut/w_weight[23]} -radix unsigned} {{/tb/dut/w_weight[22]} -radix unsigned} {{/tb/dut/w_weight[21]} -radix unsigned} {{/tb/dut/w_weight[20]} -radix unsigned} {{/tb/dut/w_weight[19]} -radix unsigned} {{/tb/dut/w_weight[18]} -radix unsigned} {{/tb/dut/w_weight[17]} -radix unsigned} {{/tb/dut/w_weight[16]} -radix unsigned} {{/tb/dut/w_weight[15]} -radix unsigned} {{/tb/dut/w_weight[14]} -radix unsigned} {{/tb/dut/w_weight[13]} -radix unsigned} {{/tb/dut/w_weight[12]} -radix unsigned} {{/tb/dut/w_weight[11]} -radix unsigned} {{/tb/dut/w_weight[10]} -radix unsigned} {{/tb/dut/w_weight[9]} -radix unsigned} {{/tb/dut/w_weight[8]} -radix unsigned} {{/tb/dut/w_weight[7]} -radix unsigned} {{/tb/dut/w_weight[6]} -radix unsigned} {{/tb/dut/w_weight[5]} -radix unsigned} {{/tb/dut/w_weight[4]} -radix unsigned} {{/tb/dut/w_weight[3]} -radix unsigned} {{/tb/dut/w_weight[2]} -radix unsigned} {{/tb/dut/w_weight[1]} -radix unsigned} {{/tb/dut/w_weight[0]} -radix unsigned}} -subitemconfig {{/tb/dut/w_weight[35]} {-radix unsigned} {/tb/dut/w_weight[34]} {-radix unsigned} {/tb/dut/w_weight[33]} {-radix unsigned} {/tb/dut/w_weight[32]} {-radix unsigned} {/tb/dut/w_weight[31]} {-radix unsigned} {/tb/dut/w_weight[30]} {-radix unsigned} {/tb/dut/w_weight[29]} {-radix unsigned} {/tb/dut/w_weight[28]} {-radix unsigned} {/tb/dut/w_weight[27]} {-radix unsigned} {/tb/dut/w_weight[26]} {-radix unsigned} {/tb/dut/w_weight[25]} {-radix unsigned} {/tb/dut/w_weight[24]} {-radix unsigned} {/tb/dut/w_weight[23]} {-radix unsigned} {/tb/dut/w_weight[22]} {-radix unsigned} {/tb/dut/w_weight[21]} {-radix unsigned} {/tb/dut/w_weight[20]} {-radix unsigned} {/tb/dut/w_weight[19]} {-radix unsigned} {/tb/dut/w_weight[18]} {-radix unsigned} {/tb/dut/w_weight[17]} {-radix unsigned} {/tb/dut/w_weight[16]} {-radix unsigned} {/tb/dut/w_weight[15]} {-radix unsigned} {/tb/dut/w_weight[14]} {-radix unsigned} {/tb/dut/w_weight[13]} {-radix unsigned} {/tb/dut/w_weight[12]} {-radix unsigned} {/tb/dut/w_weight[11]} {-radix unsigned} {/tb/dut/w_weight[10]} {-radix unsigned} {/tb/dut/w_weight[9]} {-radix unsigned} {/tb/dut/w_weight[8]} {-radix unsigned} {/tb/dut/w_weight[7]} {-radix unsigned} {/tb/dut/w_weight[6]} {-radix unsigned} {/tb/dut/w_weight[5]} {-radix unsigned} {/tb/dut/w_weight[4]} {-radix unsigned} {/tb/dut/w_weight[3]} {-radix unsigned} {/tb/dut/w_weight[2]} {-radix unsigned} {/tb/dut/w_weight[1]} {-radix unsigned} {/tb/dut/w_weight[0]} {-radix unsigned}} /tb/dut/w_weight
add wave -noupdate -radix unsigned /tb/dut/w_output
add wave -noupdate /tb/dut/control/clk
add wave -noupdate /tb/dut/control/reset
add wave -noupdate /tb/dut/control/p_start
add wave -noupdate /tb/dut/control/p_end
add wave -noupdate /tb/dut/control/p_conv_start
add wave -noupdate /tb/dut/control/p_conv_end
add wave -noupdate /tb/dut/control/p_input
add wave -noupdate /tb/dut/control/p_weight
add wave -noupdate /tb/dut/control/p_output
add wave -noupdate /tb/dut/control/p_read_en
add wave -noupdate /tb/dut/control/p_read_addr
add wave -noupdate /tb/dut/control/p_read_data
add wave -noupdate /tb/dut/control/p_read_valid
add wave -noupdate /tb/dut/control/p_write_en
add wave -noupdate /tb/dut/control/p_write_addr
add wave -noupdate /tb/dut/control/p_write_data
add wave -noupdate /tb/dut/control/current_st_input
add wave -noupdate /tb/dut/control/next_st_input
add wave -noupdate /tb/dut/control/current_st_output
add wave -noupdate /tb/dut/control/next_st_output
add wave -noupdate /tb/dut/control/r_en_wh
add wave -noupdate /tb/dut/control/r_en_fin
add wave -noupdate /tb/dut/control/r_count_wh
add wave -noupdate /tb/dut/control/r_count_fin
add wave -noupdate /tb/dut/control/r_count_fout
add wave -noupdate /tb/dut/control/r_addr_bias
add wave -noupdate /tb/dut/control/r_addr_wh
add wave -noupdate /tb/dut/control/r_addr_fin
add wave -noupdate /tb/dut/control/r_addr_fout
add wave -noupdate /tb/dut/control/r_count_window
add wave -noupdate /tb/dut/control/r_count_fin_horizontal
add wave -noupdate /tb/dut/control/r_count_fout_horizontal
add wave -noupdate /tb/dut/control/w_end_fin_horizontal
add wave -noupdate /tb/dut/control/w_end_fout_horizontal
add wave -noupdate /tb/dut/control/w_end_fin
add wave -noupdate /tb/dut/control/w_end_fout
add wave -noupdate /tb/dut/control/w_read_addr
add wave -noupdate /tb/dut/control/w_addr_fin
add wave -noupdate /tb/dut/control/r_feat_in
add wave -noupdate /tb/dut/control/r_weight
add wave -noupdate /tb/dut/control/r_feat_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {129 ns} 1 Red default} {{Cursor 2} {158 ns} 0}
quietly wave cursor active 2
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
WaveRestoreZoom {90 ns} {226 ns}
