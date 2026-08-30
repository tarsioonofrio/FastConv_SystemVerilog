SRCDIR = .
SRC = $(SRCDIR)/conv.sv
TB = $(SRCDIR)/testbench.sv
DATA = $(SRCDIR)/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv
PARAM = $(SRCDIR)/pack-param/tcn4/pack_param.sv
MUX = $(SRCDIR)/mux-mult/tcn4/mux_mult_16.sv
MATRICES = $(SRCDIR)/mult-matrices/tcn4/mult_matrices.sv
MEM = ../mem/mem.sv

OBJDIR = obj_dir
BIN = $(OBJDIR)/Vtb
VERILATOR = verilator -j 0 -DSIMULATION --trace-fst --trace-max-array 4096 --top-module tb -Wno-fatal
VERILATOR_BUILD = $(VERILATOR) --binary --exe

all: $(BIN)

$(BIN): $(SRC) $(TB) $(DATA) $(PARAM) $(MUX) $(MATRICES) $(MEM)
	$(VERILATOR_BUILD) $(DATA) $(PARAM) $(MUX) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES) $(SRC) $(TB) --build

lint:
	$(VERILATOR) --timing --lint-only $(DATA) $(PARAM) $(MUX) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES) $(SRC) $(TB)

run: all
	$(BIN)

clean:
	rm -rf $(OBJDIR) dump.fst dump.vcd
