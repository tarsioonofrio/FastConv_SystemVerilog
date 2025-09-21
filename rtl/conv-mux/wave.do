onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk
add wave -noupdate /tb/dut/reset
add wave -noupdate /tb/dut/p_start
add wave -noupdate /tb/dut/p_end
add wave -noupdate -radix decimal /tb/dut/w_prod_c
add wave -noupdate -radix decimal /tb/dut/w_prod_a
add wave -noupdate /tb/dut/r_end
add wave -noupdate /tb/dut/w_end
add wave -noupdate -radix decimal /tb/dut/product
add wave -noupdate -radix decimal -childformat {{{/tb/p_output[8]} -radix decimal} {{/tb/p_output[7]} -radix decimal} {{/tb/p_output[6]} -radix decimal} {{/tb/p_output[5]} -radix decimal} {{/tb/p_output[4]} -radix decimal} {{/tb/p_output[3]} -radix decimal} {{/tb/p_output[2]} -radix decimal} {{/tb/p_output[1]} -radix decimal} {{/tb/p_output[0]} -radix decimal}} -expand -subitemconfig {{/tb/p_output[8]} {-radix decimal} {/tb/p_output[7]} {-radix decimal} {/tb/p_output[6]} {-radix decimal} {/tb/p_output[5]} {-radix decimal} {/tb/p_output[4]} {-radix decimal} {/tb/p_output[3]} {-radix decimal} {/tb/p_output[2]} {-radix decimal} {/tb/p_output[1]} {-radix decimal} {/tb/p_output[0]} {-radix decimal}} /tb/p_output
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {24 ns} 0}
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
WaveRestoreZoom {20 ns} {34 ns}
