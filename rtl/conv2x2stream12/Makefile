SRC = conv.sv
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

all: $(BIN)

$(BIN): $(SRC) $(TB) $(DATA) $(PARAM) $(MATRICES) $(MEM)
	$(VERILATOR) --binary --exe --Mdir $(OBJDIR) $(DATA) $(PARAM) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES) $(SRC) $(TB) --build

lint:
	$(VERILATOR) --timing --lint-only $(DATA) $(PARAM) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES) $(SRC) $(TB)

run: all
	$(BIN)

clean:
	rm -rf obj_dir dump.fst dump.vcd
