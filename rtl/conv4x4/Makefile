SRCDIR = .
# Select the generated data/configuration without changing the testbench.
# TCN16 remains the default; WPN16 can be run with CONFIG=wpn16 NUM_MULT=64.
CONFIG ?= tcn16
DATASET ?= sim-032-3-3-normal
NUM_MULT ?= 18
DATA = $(SRCDIR)/data/$(CONFIG)/sim/$(DATASET)/pack_data.sv
PARAM = $(SRCDIR)/pack-param/$(CONFIG)/pack_param.sv
MUX = $(SRCDIR)/mux-mult/$(CONFIG)/mux_mult_$(NUM_MULT).sv
MATRICES = $(SRCDIR)/mult-matrices/$(CONFIG)/mult_matrices.sv
SRC = $(SRCDIR)/conv.sv
TB = $(SRCDIR)/testbench.sv
PACK_DEF = ../../contrib/rtl/pack-def/pack_def.sv
CSA = ../csa/csa_lib.sv
MULTIP = ../multip/multip.sv

OBJDIR = obj_dir/$(CONFIG)-$(NUM_MULT)
BIN = $(OBJDIR)/Vtb
VERILATOR = verilator -j 0 -DSIMULATION --trace-fst --trace-max-array 4096 --top-module tb -Wno-fatal --Mdir $(OBJDIR)
MEM = $(SRCDIR)/../mem/mem.sv
VERILATOR_BUILD = $(VERILATOR) --binary --exe

all: $(BIN)

$(BIN): $(SRC) $(TB) $(DATA) $(PARAM) $(MUX) $(MATRICES) $(PACK_DEF) $(CSA) $(MULTIP) $(MEM)
	$(VERILATOR_BUILD) $(DATA) $(PACK_DEF) $(PARAM) $(MUX) $(CSA) $(MULTIP) $(MATRICES) $(MEM) $(SRC) $(TB) --build

lint:
	$(VERILATOR) --timing --lint-only $(DATA) $(PACK_DEF) $(PARAM) $(MUX) $(CSA) $(MULTIP) $(MATRICES) $(MEM) $(SRC) $(TB)

run: all
	$(BIN)

clean:
	rm -rf $(OBJDIR) dump.fst dump.vcd
