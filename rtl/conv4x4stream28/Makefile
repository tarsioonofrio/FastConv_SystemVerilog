SRCDIR = .
DATA = ../conv4x4/data/tcn16/sim/sim-032-3-3-normal/pack_data.sv
PARAM = $(SRCDIR)/pack-param/tcn16/pack_param.sv
MATRICES = $(SRCDIR)/mult-matrices/tcn16/mult_matrices.sv
SRC = $(SRCDIR)/conv.sv
TB = $(SRCDIR)/testbench.sv
PACK_DEF = ../../contrib/rtl/pack-def/pack_def.sv
CSA = ../csa/csa_lib.sv
MULTIP = ../multip/multip.sv
MEM = ../mem/mem.sv

OBJDIR = obj_dir
BIN = $(OBJDIR)/Vtb
VERILATOR = verilator -j 0 -DSIMULATION --trace-fst --trace-max-array 4096 --top-module tb -Wno-fatal
VERILATOR_BUILD = $(VERILATOR) --binary --exe

all: $(BIN)

$(BIN): $(SRC) $(TB) $(DATA) $(PARAM) $(MATRICES) $(PACK_DEF) $(CSA) $(MULTIP) $(MEM)
	$(VERILATOR_BUILD) $(DATA) $(PACK_DEF) $(PARAM) $(CSA) $(MULTIP) $(MATRICES) $(MEM) $(SRC) $(TB) --build

lint:
	$(VERILATOR) --timing --lint-only $(DATA) $(PACK_DEF) $(PARAM) $(CSA) $(MULTIP) $(MATRICES) $(MEM) $(SRC) $(TB)

run: all
	$(BIN)

row-test:
	verilator --binary --timing --top-module row_tb -Wno-fatal \
		$(MATRICES) streaming_row_testbench.sv -o /tmp/conv4x4stream28-row_tb
	/tmp/conv4x4stream28-row_tb

clean:
	rm -rf $(OBJDIR) dump.fst dump.vcd
