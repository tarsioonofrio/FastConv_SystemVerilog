onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate /tb/dut/p_idle
add wave -noupdate -radix binary /tb/dut/current_state
add wave -noupdate -radix decimal {/tb/dut/\p_input[0] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[1] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[2] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[3] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[4] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[5] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[6] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[7] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[8] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[9] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[10] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[11] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[12] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[13] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[14] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[15] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[16] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[17] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[18] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[19] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[20] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[21] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[22] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[23] }
add wave -noupdate -radix decimal {/tb/dut/\p_input[24] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[0] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[1] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[2] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[3] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[4] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[5] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[6] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[7] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[8] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[9] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[10] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[11] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[12] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[13] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[14] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[15] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[16] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[17] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[18] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[19] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[20] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[21] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[22] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[23] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[24] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[25] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[26] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[27] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[28] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[29] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[30] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[31] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[32] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[33] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[34] }
add wave -noupdate -radix decimal {/tb/dut/\p_weight[35] }
add wave -noupdate -radix decimal {/tb/dut/\p_output[0] }
add wave -noupdate -radix decimal {/tb/dut/\p_output[1] }
add wave -noupdate -radix decimal {/tb/dut/\p_output[2] }
add wave -noupdate -radix decimal {/tb/dut/\p_output[3] }
add wave -noupdate -radix decimal {/tb/dut/\p_output[4] }
add wave -noupdate -radix decimal {/tb/dut/\p_output[5] }
add wave -noupdate -radix decimal {/tb/dut/\p_output[6] }
add wave -noupdate -radix decimal {/tb/dut/\p_output[7] }
add wave -noupdate -radix decimal {/tb/dut/\p_output[8] }
add wave -noupdate -radix decimal {/tb/dut/\product[0] }
add wave -noupdate -radix decimal {/tb/dut/\product[1] }
add wave -noupdate -radix decimal {/tb/dut/\product[2] }
add wave -noupdate -radix decimal {/tb/dut/\product[3] }
add wave -noupdate -radix decimal {/tb/dut/\product[4] }
add wave -noupdate -radix decimal {/tb/dut/\product[5] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[0] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[1] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[2] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[3] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[4] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[5] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[6] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[7] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[8] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[9] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[10] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[11] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[12] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[13] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[14] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[15] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[16] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[17] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[18] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[19] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[20] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[21] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[22] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[23] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[24] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[25] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[26] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[27] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[28] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[29] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[30] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[31] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[32] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[33] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[34] }
add wave -noupdate -radix decimal {/tb/dut/\r_feat[35] }
add wave -noupdate -radix decimal /tb/dut/r_idx_in
add wave -noupdate -radix decimal {/tb/dut/\r_idx_out[5] }
add wave -noupdate -radix decimal {/tb/dut/\r_idx_out[3] }
add wave -noupdate -radix decimal {/tb/dut/\r_idx_out[1] }
add wave -noupdate -radix decimal {/tb/dut/\r_idx_out[0] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[0] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[1] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[2] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[3] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[4] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[5] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[6] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[7] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[8] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[9] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[10] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[11] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[12] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[13] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[14] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[15] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[16] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[17] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[18] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[19] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[20] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[24] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[25] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[26] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[30] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[31] }
add wave -noupdate -radix decimal {/tb/dut/\w_prod_c[32] }
add wave -noupdate /tb/dut/current_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {111 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 205
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
WaveRestoreZoom {0 ns} {288 ns}
