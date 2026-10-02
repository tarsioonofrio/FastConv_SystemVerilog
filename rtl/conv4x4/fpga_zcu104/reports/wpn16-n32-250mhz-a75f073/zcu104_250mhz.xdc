create_clock -name clk -period 4.000000 [get_ports clk]
set_false_path -from [get_ports reset]
