###############################################################################
# TOP
###############################################################################

set TOP_MODULE Multip

set OUT_FILES "[pwd]/results"

set FASTCONV_ROOT "/sim/tarsio/FastConv_SystemVerilog"

set HDL_FILES "${FASTCONV_ROOT}/synthesis/conv-naive-m032p/rtl/pack_conv.sv ${FASTCONV_ROOT}/synthesis/conv-naive-m032p/rtl/mac_op9.sv"

puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Load the pdk using MMMC"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

read_mmmc "[exec git -C [pwd] rev-parse --show-toplevel]/synthesis/multip_only/scripts/mmmc_tsmc_28_bv_noclk.tcl"

puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Configuration of the Genus"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

set_multi_cpu_usage -local_cpu 112
set_db lp_default_probability 0.5
set_db syn_global_effort high
set_db auto_ungroup none
set_db hdl_parameter_naming_style ""
set_db interconnect_mode ple
set_db hdl_error_on_latch true

puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Load hdl files"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

read_hdl -sv ${HDL_FILES}

puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Elaboration"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

elaborate ${TOP_MODULE}
init_design

puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Synthesis - mapping and optimization"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

syn_generic
syn_map
syn_opt

puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Write Reports"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

report_gates > ${OUT_FILES}/reports/${TOP_MODULE}_gates.rpt
report_area > ${OUT_FILES}/reports/${TOP_MODULE}_area.rpt

set CURRENT_VIEW analysis_view_0p90v_25c_captyp_nominal
set_analysis_view -setup ${CURRENT_VIEW} -hold ${CURRENT_VIEW}
report_timing > ${OUT_FILES}/reports/${TOP_MODULE}_timing_setup_${CURRENT_VIEW}.rpt
report timing -lint -verbose > ${OUT_FILES}/reports/${TOP_MODULE}_timing_setup_${CURRENT_VIEW}_verbose.rpt
report_timing -unconstrained > ${OUT_FILES}/reports/${TOP_MODULE}_timing_setup_${CURRENT_VIEW}_verbose_unconstrained.rpt

puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Write netlist"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

write_hdl > ${OUT_FILES}/gate_level/${TOP_MODULE}_logic_mapped.v

set CURRENT_VIEW analysis_view_0p90v_25c_captyp_nominal
set_analysis_view -setup ${CURRENT_VIEW} -hold ${CURRENT_VIEW}
write_sdf > ${OUT_FILES}/gate_level/${TOP_MODULE}_${CURRENT_VIEW}.sdf

exit
