DATA = ../conv3x3/data/ifn9/sim/sim-032-3-3-normal/pack_data.sv
PARAM = ../conv3x3/pack-param/ifn9/pack_param.sv
MATRICES = mult-matrices/ifn9/mult_matrices_csa.sv
MEM = ../mem/mem.sv
COMMON = $(DATA) $(PARAM) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES)
FIXED_VERILATOR = verilator -j 0 -DSIMULATION --trace-fst --trace-max-array 4096 -Wno-fatal

.PHONY: conv6mac conv12mac conv18mac run-conv6mac run-conv12mac run-conv18mac clean

conv6mac:
	mkdir -p obj_dir/conv6mac
	$(FIXED_VERILATOR) --binary --exe --top-module tb --Mdir obj_dir/conv6mac -GNUM_MULT=6 -GSTATE_MULT=6 $(COMMON) conv6mac.sv testbench.sv --build

conv12mac:
	mkdir -p obj_dir/conv12mac
	$(FIXED_VERILATOR) --binary --exe --top-module tb --Mdir obj_dir/conv12mac -GNUM_MULT=12 -GSTATE_MULT=3 $(COMMON) conv12mac.sv testbench.sv --build

conv18mac:
	mkdir -p obj_dir/conv18mac
	$(FIXED_VERILATOR) --binary --exe --top-module tb --Mdir obj_dir/conv18mac -GNUM_MULT=18 -GSTATE_MULT=2 $(COMMON) conv18mac.sv testbench.sv --build

run-conv6mac: conv6mac
	obj_dir/conv6mac/Vtb

run-conv12mac: conv12mac
	obj_dir/conv12mac/Vtb

run-conv18mac: conv18mac
	obj_dir/conv18mac/Vtb

clean:
	rm -rf obj_dir dump.fst dump.vcd
