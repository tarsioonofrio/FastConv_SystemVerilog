DATA = ../conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv
PARAM = ../conv2x2/pack-param/tcn4/pack_param.sv
MATRICES = mult-matrices/tcn4/mult_matrices.sv
MEM = ../mem/mem.sv

FIXED_VERILATOR = verilator -j 0 -DSIMULATION --trace-fst --trace-max-array 4096 -Wno-fatal
FIXED_COMMON = $(DATA) $(PARAM) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES)

all: conv4mac

lint:
	$(FIXED_VERILATOR) --timing --lint-only $(FIXED_COMMON) conv4mac.sv testbench.sv
	$(FIXED_VERILATOR) --timing --lint-only $(FIXED_COMMON) conv8mac.sv testbench.sv

.PHONY: all lint conv4mac conv8mac run-conv4mac run-conv8mac clean

conv4mac:
	mkdir -p obj_dir/conv4mac
	$(FIXED_VERILATOR) --binary --exe --top-module tb --Mdir obj_dir/conv4mac $(FIXED_COMMON) conv4mac.sv testbench.sv --build

conv8mac:
	mkdir -p obj_dir/conv8mac
	$(FIXED_VERILATOR) --binary --exe --top-module tb --Mdir obj_dir/conv8mac $(FIXED_COMMON) conv8mac.sv testbench.sv --build

run-conv4mac: conv4mac
	obj_dir/conv4mac/Vtb

run-conv8mac: conv8mac
	obj_dir/conv8mac/Vtb

clean:
	rm -rf obj_dir dump.fst dump.vcd
