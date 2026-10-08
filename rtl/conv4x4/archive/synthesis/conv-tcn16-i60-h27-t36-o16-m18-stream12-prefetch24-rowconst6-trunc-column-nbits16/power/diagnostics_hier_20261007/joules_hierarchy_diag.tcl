###############################################################################
# Temporary Joules diagnostic: active-job power and activity by hierarchy.
# CONFIG_ROOT and POWER_ROOT are supplied by the remote shell environment.
###############################################################################

set CONFIG_ROOT [file normalize $::env(CONFIG_ROOT)]
set POWER_ROOT [file normalize $::env(POWER_ROOT)]
set TOP_MODULE Conv
set DB_FILE [file join $CONFIG_ROOT logical results gate_level ${TOP_MODULE}_logic_mapped.db]
set SHM [file join $CONFIG_ROOT sim dut.shm]
set START_TIME 101ns
set END_TIME 10875ns

set LIB_PATH /pdk/tsmc/PDK28/PDK_TSMC28_bv/tcbn28hpcplusbwp30p140_190a/TSMCHOME/digital/Front_End
set TECH_PATH /pdk/tsmc/PDK28/PDK_TSMC28_bv/tcbn28hpcplusbwp30p140_190a/TSMCHOME/digital/Back_End

create_library_set -name libset_0p90v_25c \
    -timing "${LIB_PATH}/timing_power_noise/NLDM/tcbn28hpcplusbwp30p140_180a/tcbn28hpcplusbwp30p140tt0p9v25c.lib"
create_opcond -name opcond_0p90v_25c -voltage 0.90 -temperature 25.0
create_timing_condition -name timing_cond_0p90v_25c \
    -opcond opcond_0p90v_25c -library_sets {libset_0p90v_25c}
create_rc_corner -name rc_corner_25c_captyp \
    -temperature 25.0 \
    -qrc_tech "${TECH_PATH}/qrc/RC_QRC_crn28hpc+_1p09m+ut-alrdl_5x1y1z1u_typical/qrcTechFile"
create_delay_corner -name delay_corner_0p90v_25c_captyp \
    -timing_condition timing_cond_0p90v_25c \
    -rc_corner rc_corner_25c_captyp
create_constraint_mode -name constraints_default \
    -sdc_files [file join $CONFIG_ROOT scripts constraints.sdc]
create_analysis_view -name analysis_view_0p90v_25c_captyp_nominal \
    -constraint_mode constraints_default \
    -delay_corner delay_corner_0p90v_25c_captyp

set CURRENT_VIEW analysis_view_0p90v_25c_captyp_nominal
read_db $DB_FILE
set_db interconnect_mode ple
read_stimulus $SHM -dut_instance tb_stream_column.dut \
    -start $START_TIME -end $END_TIME

report_sdb_annotation /Conv \
    > [file join $POWER_ROOT active_annotation_by_driver.txt]
report_power -inst /Conv -category {memory register latch logic bbox clock pad pm} \
    -type {leakage internal switching total} \
    -by_category -cols {leakage internal switching total} \
    -unit mW -format %.5e -header \
    > [file join $POWER_ROOT active_power_by_category.txt]
report_power -inst /Conv -by_hierarchy -levels all \
    -cols {hier level cells pct_cells leakage internal switching total} \
    -unit mW -format %.5e -header \
    > [file join $POWER_ROOT active_power_by_hierarchy.txt]
exit
