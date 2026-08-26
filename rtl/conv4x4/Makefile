SRCDIR = .
DATA = $(SRCDIR)/data/tcn16/sim/sim-032-3-3-normal/pack_data.sv
PARAM = $(SRCDIR)/pack-param/tcn16/pack_param.sv
MUX = $(SRCDIR)/mux-mult/tcn16/mux_mult_18.sv
MATRICES = $(SRCDIR)/mult-matrices/tcn16/mult_matrices.sv
SRC = $(SRCDIR)/conv.sv
TB = $(SRCDIR)/testbench.sv
PACK_DEF = ../../contrib/rtl/pack-def/pack_def.sv
CSA = ../csa/csa_lib.sv
MULTIP = ../multip/multip.sv

OBJDIR = obj_dir
BIN = $(OBJDIR)/Vtb
VERILATOR = verilator -j 0 -DSIMULATION --trace-fst --trace-max-array 4096 --top-module tb -Wno-fatal
VERILATOR_BUILD = $(VERILATOR) --binary --exe

all: $(BIN)

$(BIN): $(SRC) $(TB) $(DATA) $(PARAM) $(MUX) $(MATRICES) $(PACK_DEF) $(CSA) $(MULTIP)
	$(VERILATOR_BUILD) $(DATA) $(PACK_DEF) $(PARAM) $(MUX) $(CSA) $(MULTIP) $(MATRICES) $(SRC) $(TB) --build

lint:
	$(VERILATOR) --timing --lint-only $(DATA) $(PACK_DEF) $(PARAM) $(MUX) $(CSA) $(MULTIP) $(MATRICES) $(SRC) $(TB)

run: all
	$(BIN)

clean:
	rm -rf $(OBJDIR) dump.fst dump.vcd
