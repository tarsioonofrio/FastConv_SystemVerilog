onerror {resume}
quietly virtual signal -install /tb/dut/control { /tb/dut/control/p_read_addr[10:0]} p_read_addr2
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/control/clk
add wave -noupdate /tb/dut/control/reset
add wave -noupdate /tb/dut/control/p_start
add wave -noupdate /tb/dut/control/p_conv_end
add wave -noupdate /tb/dut/control/p_read_valid
add wave -noupdate -radix decimal /tb/dut/control/p_read_data
add wave -noupdate /tb/dut/control/p_end
add wave -noupdate /tb/dut/control/p_conv_start
add wave -noupdate /tb/dut/control/p_read_en
add wave -noupdate /tb/dut/control/p_write_en
add wave -noupdate -expand -group memory /tb/memory_read/clk
add wave -noupdate -expand -group memory /tb/memory_read/reset
add wave -noupdate -expand -group memory /tb/memory_read/chip_en
add wave -noupdate -expand -group memory /tb/memory_read/wr_en
add wave -noupdate -expand -group memory -radix hexadecimal /tb/memory_read/address
add wave -noupdate -expand -group memory /tb/memory_read/data_in
add wave -noupdate -expand -group memory -radix decimal -childformat {{{/tb/memory_read/data_out[19]} -radix decimal} {{/tb/memory_read/data_out[18]} -radix decimal} {{/tb/memory_read/data_out[17]} -radix decimal} {{/tb/memory_read/data_out[16]} -radix decimal} {{/tb/memory_read/data_out[15]} -radix decimal} {{/tb/memory_read/data_out[14]} -radix decimal} {{/tb/memory_read/data_out[13]} -radix decimal} {{/tb/memory_read/data_out[12]} -radix decimal} {{/tb/memory_read/data_out[11]} -radix decimal} {{/tb/memory_read/data_out[10]} -radix decimal} {{/tb/memory_read/data_out[9]} -radix decimal} {{/tb/memory_read/data_out[8]} -radix decimal} {{/tb/memory_read/data_out[7]} -radix decimal} {{/tb/memory_read/data_out[6]} -radix decimal} {{/tb/memory_read/data_out[5]} -radix decimal} {{/tb/memory_read/data_out[4]} -radix decimal} {{/tb/memory_read/data_out[3]} -radix decimal} {{/tb/memory_read/data_out[2]} -radix decimal} {{/tb/memory_read/data_out[1]} -radix decimal} {{/tb/memory_read/data_out[0]} -radix decimal}} -subitemconfig {{/tb/memory_read/data_out[19]} {-radix decimal} {/tb/memory_read/data_out[18]} {-radix decimal} {/tb/memory_read/data_out[17]} {-radix decimal} {/tb/memory_read/data_out[16]} {-radix decimal} {/tb/memory_read/data_out[15]} {-radix decimal} {/tb/memory_read/data_out[14]} {-radix decimal} {/tb/memory_read/data_out[13]} {-radix decimal} {/tb/memory_read/data_out[12]} {-radix decimal} {/tb/memory_read/data_out[11]} {-radix decimal} {/tb/memory_read/data_out[10]} {-radix decimal} {/tb/memory_read/data_out[9]} {-radix decimal} {/tb/memory_read/data_out[8]} {-radix decimal} {/tb/memory_read/data_out[7]} {-radix decimal} {/tb/memory_read/data_out[6]} {-radix decimal} {/tb/memory_read/data_out[5]} {-radix decimal} {/tb/memory_read/data_out[4]} {-radix decimal} {/tb/memory_read/data_out[3]} {-radix decimal} {/tb/memory_read/data_out[2]} {-radix decimal} {/tb/memory_read/data_out[1]} {-radix decimal} {/tb/memory_read/data_out[0]} {-radix decimal}} /tb/memory_read/data_out
add wave -noupdate -expand -group memory /tb/memory_read/data_valid
add wave -noupdate -expand -group memory /tb/memory_read/r_cycles_latency
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[24] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[23] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[22] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[21] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[20] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[19] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[18] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[17] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[16] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[15] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[14] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[13] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[12] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[11] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[10] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[9] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[8] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[7] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[6] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[5] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[4] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[3] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[2] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[1] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_input[0] }
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[0] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[1] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[2] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[3] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[4] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[5] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[6] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[7] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[8] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[9] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[10] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[11] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[12] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[13] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[14] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[15] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[16] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[17] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[18] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[19] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[20] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[21] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[22] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[23] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[24] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[25] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[26] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[27] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[28] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[29] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[30] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[31] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[32] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[33] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[34] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_weight[35] }
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix decimal {/tb/dut/control/\p_output[0] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_output[1] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_output[2] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_output[3] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_output[4] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_output[5] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_output[6] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_output[7] }
add wave -noupdate -radix decimal {/tb/dut/control/\p_output[8] }
add wave -noupdate -radix decimal -childformat {{{/tb/dut/control/p_write_data[19]} -radix decimal} {{/tb/dut/control/p_write_data[18]} -radix decimal} {{/tb/dut/control/p_write_data[17]} -radix decimal} {{/tb/dut/control/p_write_data[16]} -radix decimal} {{/tb/dut/control/p_write_data[15]} -radix decimal} {{/tb/dut/control/p_write_data[14]} -radix decimal} {{/tb/dut/control/p_write_data[13]} -radix decimal} {{/tb/dut/control/p_write_data[12]} -radix decimal} {{/tb/dut/control/p_write_data[11]} -radix decimal} {{/tb/dut/control/p_write_data[10]} -radix decimal} {{/tb/dut/control/p_write_data[9]} -radix decimal} {{/tb/dut/control/p_write_data[8]} -radix decimal} {{/tb/dut/control/p_write_data[7]} -radix decimal} {{/tb/dut/control/p_write_data[6]} -radix decimal} {{/tb/dut/control/p_write_data[5]} -radix decimal} {{/tb/dut/control/p_write_data[4]} -radix decimal} {{/tb/dut/control/p_write_data[3]} -radix decimal} {{/tb/dut/control/p_write_data[2]} -radix decimal} {{/tb/dut/control/p_write_data[1]} -radix decimal} {{/tb/dut/control/p_write_data[0]} -radix decimal}} -subitemconfig {{/tb/dut/control/p_write_data[19]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[18]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[17]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[16]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[15]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[14]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[13]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[12]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[11]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[10]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[9]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[8]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[7]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[6]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[5]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[4]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[3]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[2]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[1]} {-height 16 -radix decimal} {/tb/dut/control/p_write_data[0]} {-height 16 -radix decimal}} /tb/dut/control/p_write_data
add wave -noupdate /tb/dut/control/p_read_addr2
add wave -noupdate -radix decimal -childformat {{{/tb/dut/control/p_read_addr[15]} -radix decimal} {{/tb/dut/control/p_read_addr[14]} -radix decimal} {{/tb/dut/control/p_read_addr[13]} -radix decimal} {{/tb/dut/control/p_read_addr[12]} -radix decimal} {{/tb/dut/control/p_read_addr[11]} -radix decimal} {{/tb/dut/control/p_read_addr[10]} -radix decimal} {{/tb/dut/control/p_read_addr[9]} -radix decimal} {{/tb/dut/control/p_read_addr[8]} -radix decimal} {{/tb/dut/control/p_read_addr[7]} -radix decimal} {{/tb/dut/control/p_read_addr[6]} -radix decimal} {{/tb/dut/control/p_read_addr[5]} -radix decimal} {{/tb/dut/control/p_read_addr[4]} -radix decimal} {{/tb/dut/control/p_read_addr[3]} -radix decimal} {{/tb/dut/control/p_read_addr[2]} -radix decimal} {{/tb/dut/control/p_read_addr[1]} -radix decimal} {{/tb/dut/control/p_read_addr[0]} -radix decimal}} -expand -subitemconfig {{/tb/dut/control/p_read_addr[15]} {-height 16 -radix decimal} {/tb/dut/control/p_read_addr[14]} {-height 16 -radix decimal} {/tb/dut/control/p_read_addr[13]} {-height 16 -radix decimal} {/tb/dut/control/p_read_addr[12]} {-height 16 -radix decimal} {/tb/dut/control/p_read_addr[11]} {-height 16 -radix decimal} {/tb/dut/control/p_read_addr[10]} {-height 16 -radix decimal} {/tb/dut/control/p_read_addr[9]} {-height 16 -radix decimal} {/tb/dut/control/p_read_addr[8]} {-height 16 -radix decimal} {/tb/dut/control/p_read_addr[7]} {-height 16 -radix decimal} {/tb/dut/control/p_read_addr[6]} {-height 16 -radix decimal} {/tb/dut/control/p_read_addr[5]} {-height 16 -radix decimal} {/tb/dut/control/p_read_addr[4]} {-height 16 -radix decimal} {/tb/dut/control/p_read_addr[3]} {-height 16 -radix decimal} {/tb/dut/control/p_read_addr[2]} {-height 16 -radix decimal} {/tb/dut/control/p_read_addr[1]} {-height 16 -radix decimal} {/tb/dut/control/p_read_addr[0]} {-height 16 -radix decimal}} /tb/dut/control/p_read_addr
add wave -noupdate -radix decimal /tb/dut/control/r_addr_fin
add wave -noupdate -radix decimal -childformat {{{/tb/dut/control/p_write_addr[15]} -radix decimal} {{/tb/dut/control/p_write_addr[14]} -radix decimal} {{/tb/dut/control/p_write_addr[13]} -radix decimal} {{/tb/dut/control/p_write_addr[12]} -radix decimal} {{/tb/dut/control/p_write_addr[11]} -radix decimal} {{/tb/dut/control/p_write_addr[10]} -radix decimal} {{/tb/dut/control/p_write_addr[9]} -radix decimal} {{/tb/dut/control/p_write_addr[8]} -radix decimal} {{/tb/dut/control/p_write_addr[7]} -radix decimal} {{/tb/dut/control/p_write_addr[6]} -radix decimal} {{/tb/dut/control/p_write_addr[5]} -radix decimal} {{/tb/dut/control/p_write_addr[4]} -radix decimal} {{/tb/dut/control/p_write_addr[3]} -radix decimal} {{/tb/dut/control/p_write_addr[2]} -radix decimal} {{/tb/dut/control/p_write_addr[1]} -radix decimal} {{/tb/dut/control/p_write_addr[0]} -radix decimal}} -subitemconfig {{/tb/dut/control/p_write_addr[15]} {-height 16 -radix decimal} {/tb/dut/control/p_write_addr[14]} {-height 16 -radix decimal} {/tb/dut/control/p_write_addr[13]} {-height 16 -radix decimal} {/tb/dut/control/p_write_addr[12]} {-height 16 -radix decimal} {/tb/dut/control/p_write_addr[11]} {-height 16 -radix decimal} {/tb/dut/control/p_write_addr[10]} {-height 16 -radix decimal} {/tb/dut/control/p_write_addr[9]} {-height 16 -radix decimal} {/tb/dut/control/p_write_addr[8]} {-height 16 -radix decimal} {/tb/dut/control/p_write_addr[7]} {-height 16 -radix decimal} {/tb/dut/control/p_write_addr[6]} {-height 16 -radix decimal} {/tb/dut/control/p_write_addr[5]} {-height 16 -radix decimal} {/tb/dut/control/p_write_addr[4]} {-height 16 -radix decimal} {/tb/dut/control/p_write_addr[3]} {-height 16 -radix decimal} {/tb/dut/control/p_write_addr[2]} {-height 16 -radix decimal} {/tb/dut/control/p_write_addr[1]} {-height 16 -radix decimal} {/tb/dut/control/p_write_addr[0]} {-height 16 -radix decimal}} /tb/dut/control/p_write_addr
add wave -noupdate -radix decimal {/tb/dut/control/\r_feat_out[0] }
add wave -noupdate -radix decimal {/tb/dut/control/\r_feat_out[1] }
add wave -noupdate -radix decimal {/tb/dut/control/\r_feat_out[2] }
add wave -noupdate -radix decimal {/tb/dut/control/\r_feat_out[3] }
add wave -noupdate -radix decimal {/tb/dut/control/\r_feat_out[4] }
add wave -noupdate -radix decimal {/tb/dut/control/\r_feat_out[5] }
add wave -noupdate -radix decimal {/tb/dut/control/\r_feat_out[6] }
add wave -noupdate -radix decimal {/tb/dut/control/\r_feat_out[7] }
add wave -noupdate -radix decimal {/tb/dut/control/\r_feat_out[8] }
add wave -noupdate -radix decimal /tb/dut/control/r_addr_wh
add wave -noupdate -radix decimal /tb/dut/control/r_addr_fout
add wave -noupdate -radix decimal /tb/dut/control/r_count_fin
add wave -noupdate -radix decimal /tb/dut/control/r_count_fout
add wave -noupdate -radix decimal /tb/dut/control/r_count_wh
add wave -noupdate -radix decimal /tb/dut/control/r_count_fin_horizontal
add wave -noupdate -radix decimal /tb/dut/control/r_addr_bias
add wave -noupdate -radix decimal /tb/dut/control/current_st_input
add wave -noupdate -radix decimal /tb/dut/control/r_count_fout_horizontal
add wave -noupdate -radix decimal /tb/dut/control/r_count_window
add wave -noupdate /tb/dut/control/r_fin_en
add wave -noupdate /tb/dut/control/r_wh_en
add wave -noupdate /tb/dut/control/rc_gclk
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {415 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 289
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
WaveRestoreZoom {161 ns} {629 ns}
