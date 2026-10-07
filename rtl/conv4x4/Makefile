SRCDIR = .
# Select the generated data/configuration without changing the testbench.
# TCN16 remains the default; WPN16 can be run with CONFIG=wpn16 NUM_MULT=64.
CONFIG ?= tcn16
DATASET ?= sim-032-3-3-normal
NUM_MULT ?= 18
DATA_DIR = $(if $(wildcard $(SRCDIR)/data/$(CONFIG)/sim/$(DATASET)/pack_data.sv),$(SRCDIR)/data/$(CONFIG)/sim/$(DATASET),$(SRCDIR)/data/archive/$(CONFIG)/sim/$(DATASET))
DATA = $(DATA_DIR)/pack_data.sv
PARAM = $(SRCDIR)/pack-param/$(CONFIG)/pack_param.sv
MUX = $(SRCDIR)/mux-mult/$(CONFIG)/mux_mult_$(NUM_MULT).sv
MATRICES = $(SRCDIR)/mult-matrices/$(CONFIG)/mult_matrices.sv
SRC = $(SRCDIR)/archive/conv.sv
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
# Streaming truncated-column variants: configurable row batches and the column
# memory interface (see ../stream-column).  CONFIG selects the algorithm and
# therefore the RTL file (conv-$(CONFIG)-*-stream*-trunc-column.sv), the matrices
# and the truncated dataset with raw spatial weights.
#   make run-stream-column CONFIG=<algorithm> [STREAM_COLUMN_NUM_MULT=<multiple>]
STREAM_COLUMN_DATASET ?= sim-032-3-3-normal-trunc
STREAM_COLUMN_NUM_MULT ?= $(if $(filter wpn16,$(CONFIG)),8,6)
STREAM_COLUMN_NUM_MULT_PADDED = $(shell printf '%02d' $(STREAM_COLUMN_NUM_MULT))
STREAM_COLUMN_PREFETCH_COLUMNS ?= 4
STREAM_COLUMN_PREFETCH_WORDS = $(shell expr $(STREAM_COLUMN_PREFETCH_COLUMNS) \* 6)
STREAM_COLUMN_DATA_DIR = $(if $(wildcard $(SRCDIR)/data/$(CONFIG)/sim/$(STREAM_COLUMN_DATASET)/pack_data.sv),$(SRCDIR)/data/$(CONFIG)/sim/$(STREAM_COLUMN_DATASET),$(SRCDIR)/data/archive/$(CONFIG)/sim/$(STREAM_COLUMN_DATASET))
STREAM_COLUMN_DATA = $(STREAM_COLUMN_DATA_DIR)/pack_data.sv
STREAM_COLUMN_SRC = $(wildcard $(SRCDIR)/conv-$(CONFIG)-*-m$(STREAM_COLUMN_NUM_MULT_PADDED)-stream*-prefetch$(STREAM_COLUMN_PREFETCH_WORDS)-*trunc-column.sv)
STREAM_COLUMN_TB = $(SRCDIR)/../stream-column/testbench_stream_column.sv
STREAM_COLUMN_OBJDIR = obj_dir/stream-column-$(CONFIG)-m$(STREAM_COLUMN_NUM_MULT)-p$(STREAM_COLUMN_PREFETCH_COLUMNS)
STREAM_COLUMN_BIN = $(STREAM_COLUMN_OBJDIR)/Vtb_stream_column
STREAM_COLUMN_FILES = $(STREAM_COLUMN_DATA) $(PARAM) $(MEM) $(CSA) $(MULTIP) $(MATRICES) $(STREAM_COLUMN_SRC) $(STREAM_COLUMN_TB)
STREAM_COLUMN_VERILATOR = verilator -j 0 -DSIMULATION --top-module tb_stream_column -GNUM_MULT=$(STREAM_COLUMN_NUM_MULT) -Wno-fatal --Mdir $(STREAM_COLUMN_OBJDIR)
STREAM_COLUMN_EXTRA_FLAGS ?=

stream-column: $(STREAM_COLUMN_BIN)

$(STREAM_COLUMN_BIN): $(STREAM_COLUMN_FILES)
	mkdir -p $(STREAM_COLUMN_OBJDIR)
	$(STREAM_COLUMN_VERILATOR) $(STREAM_COLUMN_EXTRA_FLAGS) --binary --exe $(STREAM_COLUMN_FILES) --build

run-stream-column: stream-column
	$(STREAM_COLUMN_BIN)

lint-stream-column:
	$(STREAM_COLUMN_VERILATOR) $(STREAM_COLUMN_EXTRA_FLAGS) --timing --lint-only $(STREAM_COLUMN_FILES)

clean-stream-column:
	rm -rf $(STREAM_COLUMN_OBJDIR)
