SRC = conv2mac.sv
TB = testbench.sv
DATA = ../conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv
PARAM = ../conv2x2/pack-param/tcn4/pack_param.sv
MATRICES = mult-matrices/tcn4/mult_matrices.sv
MEM = ../mem/mem.sv

NUM_MULT ?= 4
OBJDIR = obj_dir/num_mult_$(NUM_MULT)
BIN = $(OBJDIR)/Vtb
VERILATOR = verilator -j 0 -DSIMULATION --trace-fst --trace-max-array 4096 --top-module tb -Wno-fatal
VERILATOR += -GNUM_MULT=$(NUM_MULT)
FIXED_VERILATOR = verilator -j 0 -DSIMULATION --trace-fst --trace-max-array 4096 -Wno-fatal
FIXED_COMMON = $(DATA) $(PARAM) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES)

all: $(BIN)

$(BIN): $(SRC) $(TB) $(DATA) $(PARAM) $(MATRICES) $(MEM)
	mkdir -p $(OBJDIR)
	$(VERILATOR) --binary --exe --Mdir $(OBJDIR) $(DATA) $(PARAM) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES) $(SRC) $(TB) --build

lint:
	$(VERILATOR) --timing --lint-only $(DATA) $(PARAM) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES) $(SRC) $(TB)

run: all
	$(BIN)

.PHONY: conv2mac conv4mac conv8mac run-conv2mac run-conv4mac run-conv8mac

conv2mac:
	mkdir -p obj_dir/conv2mac
	$(FIXED_VERILATOR) -GNUM_MULT=2 --binary --exe --top-module tb --Mdir obj_dir/conv2mac $(FIXED_COMMON) conv2mac.sv testbench.sv --build

conv4mac:
	mkdir -p obj_dir/conv4mac
	$(FIXED_VERILATOR) --binary --exe --top-module tb --Mdir obj_dir/conv4mac $(FIXED_COMMON) conv4mac.sv testbench.sv --build

conv8mac:
	mkdir -p obj_dir/conv8mac
	$(FIXED_VERILATOR) --binary --exe --top-module tb --Mdir obj_dir/conv8mac $(FIXED_COMMON) conv8mac.sv testbench.sv --build

run-conv2mac: conv2mac
	obj_dir/conv2mac/Vtb

run-conv4mac: conv4mac
	obj_dir/conv4mac/Vtb

run-conv8mac: conv8mac
	obj_dir/conv8mac/Vtb

clean:
	rm -rf obj_dir dump.fst dump.vcd
