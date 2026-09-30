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
	mkdir -p $(OBJDIR)
	$(VERILATOR_BUILD) $(DATA) $(PACK_DEF) $(PARAM) $(MUX) $(CSA) $(MULTIP) $(MATRICES) $(MEM) $(SRC) $(TB) --build

lint:
	$(VERILATOR) --timing --lint-only $(DATA) $(PACK_DEF) $(PARAM) $(MUX) $(CSA) $(MULTIP) $(MATRICES) $(MEM) $(SRC) $(TB)

run: all
	$(BIN)

clean:
	rm -rf $(OBJDIR) dump.fst dump.vcd

# ---------------------------------------------------------------------------
# Streaming truncated-column variants: one row of MACs per cycle and the column
# memory interface (see ../stream-column).  CONFIG selects the algorithm and
# therefore the RTL file (conv-*-$(CONFIG)-stream*-trunc-column.sv), the matrices
# and the truncated dataset with raw spatial weights.
#   make run-stream-column CONFIG=<algorithm>
STREAM_COLUMN_DATASET ?= sim-032-3-3-normal-trunc
STREAM_COLUMN_DATA = $(SRCDIR)/data/$(CONFIG)/sim/$(STREAM_COLUMN_DATASET)/pack_data.sv
STREAM_COLUMN_SRC = $(wildcard $(SRCDIR)/conv-*-$(CONFIG)-stream*-trunc-column.sv)
STREAM_COLUMN_TB = $(SRCDIR)/../stream-column/testbench_stream_column.sv
STREAM_COLUMN_OBJDIR = obj_dir/stream-column-$(CONFIG)
STREAM_COLUMN_BIN = $(STREAM_COLUMN_OBJDIR)/Vtb_stream_column
STREAM_COLUMN_FILES = $(STREAM_COLUMN_DATA) $(PARAM) $(MEM) $(CSA) $(MULTIP) $(MATRICES) $(STREAM_COLUMN_SRC) $(STREAM_COLUMN_TB)
STREAM_COLUMN_VERILATOR = verilator -j 0 -DSIMULATION --top-module tb_stream_column -Wno-fatal --Mdir $(STREAM_COLUMN_OBJDIR)

stream-column: $(STREAM_COLUMN_BIN)

$(STREAM_COLUMN_BIN): $(STREAM_COLUMN_FILES)
	mkdir -p $(STREAM_COLUMN_OBJDIR)
	$(STREAM_COLUMN_VERILATOR) --binary --exe $(STREAM_COLUMN_FILES) --build

run-stream-column: stream-column
	$(STREAM_COLUMN_BIN)

lint-stream-column:
	$(STREAM_COLUMN_VERILATOR) --timing --lint-only $(STREAM_COLUMN_FILES)

clean-stream-column:
	rm -rf $(STREAM_COLUMN_OBJDIR)
