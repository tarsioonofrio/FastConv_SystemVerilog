SRCDIR = .
CONFIG ?= ifn9
DATASET ?= sim-032-3-3-normal
NUM_MULT ?= 6
MUX_SUFFIX = $(shell printf '%02d' $(NUM_MULT))
DATA = $(SRCDIR)/data/$(CONFIG)/sim/$(DATASET)/pack_data.sv
PARAM = $(SRCDIR)/pack-param/$(CONFIG)/pack_param.sv
MUX = $(SRCDIR)/mux-mult/$(CONFIG)/mux_mult_$(MUX_SUFFIX).sv
MATRICES = $(SRCDIR)/mult-matrices/$(CONFIG)/mult_matrices.sv
SRC = $(SRCDIR)/conv.sv
TB = $(SRCDIR)/testbench.sv
PACK_DEF = ../../contrib/rtl/pack-def/pack_def.sv
CSA = ../csa/csa_lib.sv
MULTIP = ../multip/multip.sv
MEM = $(SRCDIR)/../mem/mem.sv

OBJDIR = obj_dir/$(CONFIG)-$(NUM_MULT)
BIN = $(OBJDIR)/Vtb
VERILATOR = verilator -j 0 -DSIMULATION --trace-fst --trace-max-array 4096 --top-module tb -Wno-fatal --Mdir $(OBJDIR)
VERILATOR_BUILD = $(VERILATOR) --binary --exe

all: $(BIN)

$(BIN): $(SRC) $(TB) $(DATA) $(PARAM) $(MUX) $(MATRICES) $(PACK_DEF) $(CSA) $(MULTIP) $(MEM)
	mkdir -p $(OBJDIR)
	$(VERILATOR_BUILD) $(DATA) $(PACK_DEF) $(PARAM) $(MUX) $(CSA) $(MULTIP) $(MATRICES) $(MEM) $(SRC) $(TB) --build

lint:
	$(VERILATOR) --timing --lint-only $(DATA) $(PACK_DEF) $(PARAM) $(MUX) $(CSA) $(MULTIP) $(MATRICES) $(MEM) $(SRC) $(TB)

clean:
	rm -rf $(OBJDIR) dump.fst dump.vcd

run: all
	$(BIN)

# Alvo de execução com GTKWave
view: run
	gtkwave dump.fst &

# ---------------------------------------------------------------------------
# Streaming truncated-column variants: one row of MACs per cycle and the column
# memory interface (see ../stream-column).  CONFIG selects the algorithm and
# therefore the RTL file (conv-$(CONFIG)-*-stream*-trunc-column.sv), the matrices
# and the truncated dataset with raw spatial weights.
#   make run-stream-column CONFIG=<algorithm>
STREAM_COLUMN_DATASET ?= sim-032-3-3-normal-trunc
STREAM_COLUMN_DATA = $(SRCDIR)/data/$(CONFIG)/sim/$(STREAM_COLUMN_DATASET)/pack_data.sv
STREAM_COLUMN_SRC = $(wildcard $(SRCDIR)/conv-$(CONFIG)-*-stream*-trunc-column.sv)
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
