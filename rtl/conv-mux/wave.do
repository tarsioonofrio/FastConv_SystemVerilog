onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate -radix decimal -childformat {{{/tb/dut/w_prod_c[35]} -radix decimal} {{/tb/dut/w_prod_c[34]} -radix decimal} {{/tb/dut/w_prod_c[33]} -radix decimal} {{/tb/dut/w_prod_c[32]} -radix decimal} {{/tb/dut/w_prod_c[31]} -radix decimal} {{/tb/dut/w_prod_c[30]} -radix decimal} {{/tb/dut/w_prod_c[29]} -radix decimal} {{/tb/dut/w_prod_c[28]} -radix decimal} {{/tb/dut/w_prod_c[27]} -radix decimal} {{/tb/dut/w_prod_c[26]} -radix decimal} {{/tb/dut/w_prod_c[25]} -radix decimal} {{/tb/dut/w_prod_c[24]} -radix decimal} {{/tb/dut/w_prod_c[23]} -radix decimal} {{/tb/dut/w_prod_c[22]} -radix decimal} {{/tb/dut/w_prod_c[21]} -radix decimal} {{/tb/dut/w_prod_c[20]} -radix decimal} {{/tb/dut/w_prod_c[19]} -radix decimal} {{/tb/dut/w_prod_c[18]} -radix decimal} {{/tb/dut/w_prod_c[17]} -radix decimal} {{/tb/dut/w_prod_c[16]} -radix decimal} {{/tb/dut/w_prod_c[15]} -radix decimal} {{/tb/dut/w_prod_c[14]} -radix decimal} {{/tb/dut/w_prod_c[13]} -radix decimal} {{/tb/dut/w_prod_c[12]} -radix decimal} {{/tb/dut/w_prod_c[11]} -radix decimal} {{/tb/dut/w_prod_c[10]} -radix decimal} {{/tb/dut/w_prod_c[9]} -radix decimal} {{/tb/dut/w_prod_c[8]} -radix decimal} {{/tb/dut/w_prod_c[7]} -radix decimal} {{/tb/dut/w_prod_c[6]} -radix decimal} {{/tb/dut/w_prod_c[5]} -radix decimal} {{/tb/dut/w_prod_c[4]} -radix decimal} {{/tb/dut/w_prod_c[3]} -radix decimal} {{/tb/dut/w_prod_c[2]} -radix decimal} {{/tb/dut/w_prod_c[1]} -radix decimal} {{/tb/dut/w_prod_c[0]} -radix decimal}} -subitemconfig {{/tb/dut/w_prod_c[35]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[34]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[33]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[32]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[31]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[30]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[29]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[28]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[27]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[26]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[25]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[24]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[23]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[22]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[21]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[20]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[19]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[18]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[17]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[16]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[15]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[14]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[13]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[12]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[11]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[10]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[9]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[8]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[7]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[6]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[5]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[4]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[3]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[2]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[1]} {-height 16 -radix decimal} {/tb/dut/w_prod_c[0]} {-height 16 -radix decimal}} /tb/dut/w_prod_c
add wave -noupdate -radix decimal /tb/dut/w_prod_a
add wave -noupdate /tb/dut/r_end
add wave -noupdate /tb/dut/w_end
add wave -noupdate -radix decimal -childformat {{{/tb/dut/product[0]} -radix decimal} {{/tb/dut/product[1]} -radix decimal} {{/tb/dut/product[2]} -radix decimal} {{/tb/dut/product[3]} -radix decimal} {{/tb/dut/product[4]} -radix decimal} {{/tb/dut/product[5]} -radix decimal}} -expand -subitemconfig {{/tb/dut/product[0]} {-height 16 -radix decimal} {/tb/dut/product[1]} {-height 16 -radix decimal} {/tb/dut/product[2]} {-height 16 -radix decimal} {/tb/dut/product[3]} {-height 16 -radix decimal} {/tb/dut/product[4]} {-height 16 -radix decimal} {/tb/dut/product[5]} {-height 16 -radix decimal}} /tb/dut/product
add wave -noupdate -radix decimal -childformat {{{/tb/p_output[8]} -radix decimal} {{/tb/p_output[7]} -radix decimal} {{/tb/p_output[6]} -radix decimal} {{/tb/p_output[5]} -radix decimal} {{/tb/p_output[4]} -radix decimal} {{/tb/p_output[3]} -radix decimal} {{/tb/p_output[2]} -radix decimal} {{/tb/p_output[1]} -radix decimal} {{/tb/p_output[0]} -radix decimal}} -subitemconfig {{/tb/p_output[8]} {-height 16 -radix decimal} {/tb/p_output[7]} {-height 16 -radix decimal} {/tb/p_output[6]} {-height 16 -radix decimal} {/tb/p_output[5]} {-height 16 -radix decimal} {/tb/p_output[4]} {-height 16 -radix decimal} {/tb/p_output[3]} {-height 16 -radix decimal} {/tb/p_output[2]} {-height 16 -radix decimal} {/tb/p_output[1]} {-height 16 -radix decimal} {/tb/p_output[0]} {-height 16 -radix decimal}} /tb/p_output
add wave -noupdate -radix decimal /tb/dut/p_input
add wave -noupdate -radix decimal /tb/dut/p_weight
add wave -noupdate -radix decimal /tb/dut/p_output
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 173
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
WaveRestoreZoom {4 ns} {9 ns}
