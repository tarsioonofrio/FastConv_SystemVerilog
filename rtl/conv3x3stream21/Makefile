SRC = conv.sv
TB = testbench.sv
DATA = ../conv3x3/data/ifn9/sim/sim-032-3-3-normal/pack_data.sv
PARAM = ../conv3x3/pack-param/ifn9/pack_param.sv
MATRICES = mult-matrices/ifn9/mult_matrices_csa.sv
MEM = ../mem/mem.sv

OBJDIR = obj_dir
BIN = $(OBJDIR)/Vtb
VERILATOR = verilator -j 0 -DSIMULATION --trace-fst --trace-max-array 4096 --top-module tb -Wno-fatal

all: $(BIN)

$(BIN): $(SRC) $(TB) $(DATA) $(PARAM) $(MATRICES) $(MEM)
	$(VERILATOR) --binary --exe $(DATA) $(PARAM) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES) $(SRC) $(TB) --build

lint:
	$(VERILATOR) --timing --lint-only $(DATA) $(PARAM) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES) $(SRC) $(TB)

run: all
	$(BIN)

clean:
	rm -rf $(OBJDIR) dump.fst dump.vcd
