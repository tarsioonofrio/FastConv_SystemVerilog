###############################################################################
# TOP 
###############################################################################
set TOP_MODULE conv_rapida


puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Load the pdk using MMMC"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	# Multi-Mode Multi-Corner (MMMC)
	read_mmmc "scripts/mmmc_tsmc_28_bv.tcl"


puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Configuration of the Genus"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	set_multi_cpu_usage -local_cpu 112

	set_db lp_default_probability 0.5

	set_db syn_global_effort high

	### keep hierarchy
	set_db auto_ungroup none

	### Set PLE (Generates a set of load values, which were obtained from the physical layout..
	# estimator (PLE) or wire-load model, for all the nets in the specified design)
	set_db interconnect_mode ple

	### controls the verbosity of the tool
	#set_db information_level 9 

	### Avoid proceeding with latche inference
	set_db hdl_error_on_latch true


puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Control Clock Gating "
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	
	set_db lp_insert_clock_gating true


puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Load hdl files"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	read_hdl -sv "../rtl/pack_conv.sv ../rtl/csa_lib.sv ../rtl/multip.sv ../rtl/mult_matrices.sv ../rtl/fast_conv.sv"
	


puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Elaboration"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	elaborate ${TOP_MODULE}

	# Applying the constraints
	init_design 


puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Synthesis - mapping and optimization"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	# set_db [current_design] .retime true

	syn_generic
	syn_map
	syn_opt


puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Write Reports"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

    set OUT_FILES ./results

	# Reports clock-gating information for the design
	report_clock_gating > ${OUT_FILES}/reports/${TOP_MODULE}_clock_gating.rpt

	# Returns the physical layout estimation (ple) information for the specified design
	report_ple > ${OUT_FILES}/reports/${TOP_MODULE}_ple.rpt

	# Report area
	report_gates > ${OUT_FILES}/reports/${TOP_MODULE}_gates.rpt
	report_area >  ${OUT_FILES}/reports/${TOP_MODULE}_area.rpt

	### report timing and power
	###################################
	set CURRENT_VIEW analysis_view_0p81v_125c_capwst_slowest
	set_analysis_view -setup ${CURRENT_VIEW}  -hold ${CURRENT_VIEW}
	report_timing > ${OUT_FILES}/reports/${TOP_MODULE}_timing_setup_${CURRENT_VIEW}.rpt
	#---
	report_power -unit mW > ${OUT_FILES}/reports/${TOP_MODULE}_power_${CURRENT_VIEW}.rpt

	##################################
	set CURRENT_VIEW analysis_view_0p90v_25c_captyp_nominal
	set_analysis_view -setup ${CURRENT_VIEW}  -hold ${CURRENT_VIEW}
	report_timing > ${OUT_FILES}/reports/${TOP_MODULE}_timing_setup_${CURRENT_VIEW}.rpt
	#---
	report_power -unit mW > ${OUT_FILES}/reports/${TOP_MODULE}_power_${CURRENT_VIEW}.rpt
	
	# ###################################
	set CURRENT_VIEW analysis_view_0p99v_m40c_capbst_fastest
	set_analysis_view -setup ${CURRENT_VIEW}  -hold ${CURRENT_VIEW}
	report_timing > ${OUT_FILES}/reports/${TOP_MODULE}_timing_setup_${CURRENT_VIEW}.rpt
	#---	
	report_power -unit mW > ${OUT_FILES}/reports/${TOP_MODULE}_power_${CURRENT_VIEW}.rpt


	### Report timming -unconstrained amd -verbose 
	report timing -lint -verbose > ${OUT_FILES}/reports/${TOP_MODULE}_timing_setup_${CURRENT_VIEW}_verbose.rpt
	report_timing -unconstrained > ${OUT_FILES}/reports/${TOP_MODULE}_timing_setup_${CURRENT_VIEW}_verbose_unconstrained.rpt 


puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Write netlist"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	write_hdl > ${OUT_FILES}/gate_level/${TOP_MODULE}_logic_mapped.v
	
	## nominal 
	set CURRENT_VIEW analysis_view_0p81v_125c_capwst_slowest  
	set_analysis_view -setup ${CURRENT_VIEW} -hold ${CURRENT_VIEW}
	write_sdf > ${OUT_FILES}/gate_level/${TOP_MODULE}_${CURRENT_VIEW}.sdf
	
	## worst setup
	set CURRENT_VIEW analysis_view_0p90v_25c_captyp_nominal
	set_analysis_view -setup ${CURRENT_VIEW} -hold ${CURRENT_VIEW}
	write_sdf > ${OUT_FILES}/gate_level/${TOP_MODULE}_${CURRENT_VIEW}.sdf

	## worst hold
	set CURRENT_VIEW analysis_view_0p99v_m40c_capbst_fastest
	set_analysis_view -setup ${CURRENT_VIEW} -hold ${CURRENT_VIEW}
	write_sdf > ${OUT_FILES}/gate_level/${TOP_MODULE}_${CURRENT_VIEW}.sdf
	

puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Export design to Innovus"
puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	### default view
	set_analysis_view -setup analysis_view_0p81v_125c_capwst_slowest  \
    	              -hold  analysis_view_0p99v_m40c_capbst_fastest 

	### To generate all files needed to be loaded in an Innovus session, use the following command:
	write_design -innovus -base_name ${OUT_FILES}/physical_synthesis/work/data

