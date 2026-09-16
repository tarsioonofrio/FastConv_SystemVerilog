# Generated from RTL/Verilator SAIF. Do not edit by hand.
# Apply after reset_switching_activity -all and before report_power.
set _activity_port [get_ports -quiet {clk}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.499989428505 -toggle_rate 2 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_end}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 4.22859800833e-05 -toggle_rate 8.45719601666e-05 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[0]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.368395458486 -toggle_rate 0.736790916971 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[10]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.341290145252 -toggle_rate 0.0115017865827 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[11]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.341290145252 -toggle_rate 0.00414402604816 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[12]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[13]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[14]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[15]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[1]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.490940228767 -toggle_rate 0.373723491976 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[2]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.491320802588 -toggle_rate 0.175063957545 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[3]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.491320802588 -toggle_rate 0.0753536165084 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[4]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.491024800727 -toggle_rate 0.0251178721695 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[5]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.539315389982 -toggle_rate 0.183013721801 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[6]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.499355138804 -toggle_rate 0.0916760048206 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[7]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.503076305051 -toggle_rate 0.0458380024103 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[8]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.50235744339 -toggle_rate 0.022834429245 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_addr[9]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.50235744339 -toggle_rate 0.0114172146225 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[0]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.37042518553 -toggle_rate 0.407805991923 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[10]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[11]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[12]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[13]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[14]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[15]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[16]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[17]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[18]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[19]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.377909804004 -toggle_rate 0.417954627143 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[1]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.371101761211 -toggle_rate 0.399940799628 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[2]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.361122269911 -toggle_rate 0.424804955917 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[3]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.367465166924 -toggle_rate 0.418123771064 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[4]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.372370340614 -toggle_rate 0.412711165613 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[5]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.369368036028 -toggle_rate 0.407636848003 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[6]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.373596634036 -toggle_rate 0.417447195382 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[7]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.367338308984 -toggle_rate 0.409920290928 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[8]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.368014884665 -toggle_rate 0.408989999366 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_data[9]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.3755840751 -toggle_rate 0.417616339303 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_en}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.736833202952 -toggle_rate 0.171342791298 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_input_valid}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.736833202952 -toggle_rate 0.171342791298 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[0]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.523500433431 -toggle_rate 0.285388079582 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[10]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.376472080682 -toggle_rate 0.0116286445229 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[11]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.227540858828 -toggle_rate 0.00651204093283 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[12]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[13]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[14]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[15]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[1]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.502188299469 -toggle_rate 0.576146478635 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[2]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.498847707043 -toggle_rate 0.330464934351 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[3]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.498636277142 -toggle_rate 0.167875340931 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[4]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.496437406178 -toggle_rate 0.0838953844853 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[5]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.504429456414 -toggle_rate 0.537750808719 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[6]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.470346956467 -toggle_rate 0.303528765038 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[7]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.470050954606 -toggle_rate 0.149523225575 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[8]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.485062477536 -toggle_rate 0.0782713491342 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_addr[9]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.445271370277 -toggle_rate 0.0397911072584 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[0]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.336088969702 -toggle_rate 0.226991141087 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[10]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.334312958539 -toggle_rate 0.224792270123 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[11]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.322346026175 -toggle_rate 0.229359155972 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[12]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.322007738334 -toggle_rate 0.235110049263 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[13]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.321627164514 -toggle_rate 0.235532909064 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[14]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.321627164514 -toggle_rate 0.235532909064 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[15]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.321627164514 -toggle_rate 0.235532909064 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[16]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.321627164514 -toggle_rate 0.235532909064 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[17]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.321627164514 -toggle_rate 0.235532909064 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[18]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.321627164514 -toggle_rate 0.235532909064 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[19]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.321627164514 -toggle_rate 0.235532909064 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[1]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.329407784849 -toggle_rate 0.229020868131 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[2]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.336765545383 -toggle_rate 0.230035731653 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[3]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.338626128507 -toggle_rate 0.229359155972 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[4]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.334355244519 -toggle_rate 0.233841469861 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[5]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.329365498869 -toggle_rate 0.224623126203 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[6]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.337568979005 -toggle_rate 0.22817514853 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[7]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.331606655813 -toggle_rate 0.232572890458 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[8]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.333974670698 -toggle_rate 0.230627735374 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_read[9]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.323022601856 -toggle_rate 0.233756897901 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[0]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.494069391293 -toggle_rate 0.211007040616 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[10]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.486119627038 -toggle_rate 0.208385309851 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[11]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.481637313149 -toggle_rate 0.205509863205 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[12]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.48201788697 -toggle_rate 0.204748715563 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[13]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.482694462651 -toggle_rate 0.204325855763 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[14]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.482694462651 -toggle_rate 0.204325855763 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[15]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.482694462651 -toggle_rate 0.204325855763 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[16]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.482694462651 -toggle_rate 0.204325855763 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[17]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.482694462651 -toggle_rate 0.204325855763 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[18]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.482694462651 -toggle_rate 0.204325855763 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[19]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.482694462651 -toggle_rate 0.204325855763 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[1]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.489756221325 -toggle_rate 0.216292788126 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[2]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.508742626382 -toggle_rate 0.212444763939 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[3]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.50252658731 -toggle_rate 0.212191048058 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[4]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.499651140664 -toggle_rate 0.213755629321 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[5]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.505106032095 -toggle_rate 0.211514472377 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[6]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.499904856545 -toggle_rate 0.212191048058 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[7]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.494661395014 -toggle_rate 0.214643634903 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[8]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.49757912764 -toggle_rate 0.21320591158 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_data_write[9]}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.493942533353 -toggle_rate 0.213713343341 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_en}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.77662431021 -toggle_rate 0.0646975495275 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_valid}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.77662431021 -toggle_rate 0.0646975495275 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_output_wr}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0.342516438675 -toggle_rate 0.171258219337 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {p_start}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 4.22859800833e-05 -toggle_rate 8.45719601666e-05 $_activity_port
}
unset _activity_port
set _activity_port [get_ports -quiet {reset}]
if {[llength $_activity_port]} {
  set_switching_activity -static_probability 0 -toggle_rate 0 $_activity_port
}
unset _activity_port
