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
# Standard column architecture. The RTL is shared by WPN16 (integer weights)
# and TCN16 frac6 (six fractional weight bits); the workload package selects
# the matching transformed-weight data, while STD_COLUMN_WEIGHT_FRAC_BITS
# selects the MAC scaling in the RTL.
STD_COLUMN_WEIGHT_FRAC_BITS ?= 0
STD_COLUMN_SRC = $(SRCDIR)/conv-tcn16-std-column.sv
STD_COLUMN_TB = $(SRCDIR)/testbench_tcn16_std_column.sv
STD_COLUMN_OBJDIR = obj_dir/std-column-$(CONFIG)-m$(NUM_MULT)-frac$(STD_COLUMN_WEIGHT_FRAC_BITS)
STD_COLUMN_BIN = $(STD_COLUMN_OBJDIR)/Vtb
STD_COLUMN_FILES = $(DATA) $(PACK_DEF) $(PARAM) $(MUX) $(CSA) $(MULTIP) $(MATRICES) $(MEM) $(STD_COLUMN_SRC) $(STD_COLUMN_TB)
STD_COLUMN_VERILATOR = verilator -j 0 -DSIMULATION --timing --top-module tb -GWEIGHT_FRAC_BITS=$(STD_COLUMN_WEIGHT_FRAC_BITS) -Wno-fatal --Mdir $(STD_COLUMN_OBJDIR)

std-column: $(STD_COLUMN_BIN)

$(STD_COLUMN_BIN): $(STD_COLUMN_FILES)
	mkdir -p $(STD_COLUMN_OBJDIR)
	$(STD_COLUMN_VERILATOR) --binary --exe $(STD_COLUMN_FILES) --build

run-std-column: std-column
	$(STD_COLUMN_BIN)

lint-std-column:
	$(STD_COLUMN_VERILATOR) --lint-only $(STD_COLUMN_FILES)

clean-std-column:
	rm -rf $(STD_COLUMN_OBJDIR)

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
