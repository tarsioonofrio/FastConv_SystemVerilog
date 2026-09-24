# The benchmark wrapper exposes only clock, reset, start, and done.
# Package pins and I/O standards are intentionally unspecified here.
create_clock -name clk -period 3.154574 [get_ports clk]
set_false_path -from [get_ports reset]
