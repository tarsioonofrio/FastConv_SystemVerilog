DATA = ../conv3x3/data/tcn9/sim/sim-032-3-3-normal/pack_data.sv
PARAM = ../conv3x3/pack-param/tcn9/pack_param.sv
MATRICES = mult-matrices/tcn9/mult_matrices_csa.sv
MEM = ../mem/mem.sv
COMMON = $(DATA) $(PARAM) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES)
FIXED_VERILATOR = verilator -j 0 -DSIMULATION --trace-fst --trace-max-array 4096 -Wno-fatal

.PHONY: conv5mac run-conv5mac clean

conv5mac:
	mkdir -p obj_dir/conv5mac
	$(FIXED_VERILATOR) --binary --exe --top-module tb --Mdir obj_dir/conv5mac -GNUM_MULT=5 -GSTATE_MULT=5 $(COMMON) conv5mac.sv testbench.sv --build

run-conv5mac: conv5mac
	obj_dir/conv5mac/Vtb

clean:
	rm -rf obj_dir dump.fst dump.vcd
