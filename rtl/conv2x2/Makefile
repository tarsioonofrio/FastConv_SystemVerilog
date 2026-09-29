# Local simulation entry points for the 2x2 architectures.
# Standard targets share testbench.sv; wide-memory experiments have dedicated testbenches.

DATA = data/tcn4/sim/sim-032-3-3-normal/pack_data.sv
DATA_EXACT = data/tcn4/sim/sim-032-3-3-normal-exact/pack_data.sv
DATA_TRUNC = data/tcn4/sim/sim-032-3-3-normal-trunc/pack_data.sv
PARAM = pack-param/tcn4/pack_param.sv
MUX = mux-mult/tcn4/mux_mult_04.sv
MATRICES_STD = mult-matrices/tcn4/mult_matrices.sv
MATRICES_STREAM = mult-matrices/stream/tcn4/mult_matrices.sv
MEM = ../mem/mem.sv
COMMON = $(DATA) $(PARAM) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv
TB = testbench.sv
TB_COLUMN = testbench_column.sv
TB_PREFETCH8_COLUMN = testbench_prefetch8_column.sv

VERILATOR = verilator -j 0 -DSIMULATION --trace-fst --trace-max-array 4096 \
            --top-module tb -Wno-fatal
VERILATOR_COLUMN_NO_TRACE = verilator -j 0 -DSIMULATION --top-module tb_column -Wno-fatal
VERILATOR_PREFETCH8_COLUMN_NO_TRACE = verilator -j 0 -DSIMULATION --top-module tb_prefetch8_column -Wno-fatal

.PHONY: all std std-column all16 stream04-4mac stream04-8mac stream00-8mac stream08 stream08-wstream4 stream08-wstream4-8mac \
	stream08-rowconst4-8mac stream08-rowconst4-exact-8mac stream08-rowconst4-exact-pipelined-8mac stream08-prefetch4-8mac stream08-prefetch4-rowconst4-8mac stream08-prefetch8-rowconst4-8mac stream08-prefetch4-rowconst4-latch-8mac stream08-prefetch4-rowconst4-temporal1-8mac stream08-exact-8mac \
	stream08-prefetch8-rowconst4-column stream08-prefetch8-rowconst4-trunc-column stream08-prefetch8-rowconst4-trunc-column-4mac stream08-prefetch8-rowconst4-trunc-8mac stream08-prefetch8-rowconst4-exact-8mac run run-std run-std-column run-all16 run-stream04-4mac run-stream00-8mac \
	        run-stream08-prefetch8-rowconst4-column run-stream08-prefetch8-rowconst4-trunc-column run-stream08-prefetch8-rowconst4-trunc-column-4mac run-stream08-rowconst4-exact-pipelined \
	        run-stream08-prefetch8-rowconst4-exact \
	        run-stream08 run-stream08-wstream4 run-stream08-prefetch4 run-stream08-prefetch4-rowconst4 run-stream08-prefetch8-rowconst4 run-stream08-prefetch4-rowconst4-latch run-stream08-prefetch4-rowconst4-temporal1 lint clean

all: std

std:
	$(VERILATOR) --binary --exe --Mdir obj_dir/std \
	  $(COMMON) $(MUX) $(MATRICES_STD) conv-i16-h16-t16-o4-m08-std.sv $(TB) --build \
	  -GNUM_MULT=8

# Experimental std variant that transfers one 4-sample feature column and one
# 2-pixel output column per memory transaction. It has a dedicated testbench.
std-column:
	$(VERILATOR_COLUMN_NO_TRACE) --binary --exe --Mdir obj_dir/std-column \
	  $(COMMON) $(MUX) $(MATRICES_STD) conv-i16-h16-t16-o4-m08-std-column.sv $(TB_COLUMN) --build

all16:
	$(VERILATOR) --binary --exe --Mdir obj_dir/all16 \
	  $(COMMON) $(MUX) $(MATRICES_STD) conv-i16-h16-t00-o4-m16-all.sv $(TB) --build \
	  -GNUM_MULT=16

stream04-4mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream04-4mac \
	  $(COMMON) $(MATRICES_STREAM) archive/m04/conv-i16-h16-t04-o4-m04-stream04.sv $(TB) --build \
	  -GNUM_MULT=4

stream04-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream04-8mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i16-h16-t04-o4-m08-stream04.sv $(TB) --build \
	  -GNUM_MULT=8

stream00-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream00-8mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i16-h16-t00-o4-m08-stream00.sv $(TB) --build \
	  -GNUM_MULT=8

# The generic stream08-family implementation supports NUM_MULT=4 and 8. Override
# NUM_MULT on the command line, for example: make stream08 NUM_MULT=8.
NUM_MULT ?= 4
ALLOW_GOLDEN_MISMATCH ?= 0
stream08:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-$(NUM_MULT) \
	  $(COMMON) $(MATRICES_STREAM) archive/m04/conv-i16-h16-t08-o4-mxx-stream08-generic.sv $(TB) --build \
	  -GNUM_MULT=$(NUM_MULT)

run: run-std
run-std: std
	obj_dir/std/Vtb
run-std-column: std-column
	obj_dir/std-column/Vtb_column
run-all16: all16
	obj_dir/all16/Vtb
run-stream04-4mac: stream04-4mac
	obj_dir/stream04-4mac/Vtb
run-stream00-8mac: stream00-8mac
	obj_dir/stream00-8mac/Vtb
run-stream08: stream08
	obj_dir/stream08-$(NUM_MULT)/Vtb

# Reads only the active four-word transformed-weight row before each
# Hadamard cycle; no complete sixteen-word weight register bank is kept.
stream08-wstream4:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-wstream4 \
	  $(COMMON) $(MATRICES_STREAM) archive/m04/conv-i16-h13-t08-o4-m04-stream08-wstream4.sv $(TB) --build

stream08-wstream4-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-wstream4-8mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i16-h13-t08-o4-m08-stream08-wstream4.sv $(TB) --build

stream08-rowconst4-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-rowconst4-8mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i16-h13-t08-o4-m08-stream08-rowconst4.sv $(TB) --build

stream08-rowconst4-exact-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-rowconst4-exact-8mac \
	  $(COMMON) $(MATRICES_STREAM) archive/m08/conv-i16-h13-t08-o4-m08-stream08-rowconst4-exact.sv $(TB) --build

# Corrected exact-arithmetic variant with registered feature and inverse stages.
# This RTL uses the matching golden package with scaled exact spatial weights.
stream08-rowconst4-exact-pipelined-8mac: DATA = data/tcn4/sim/sim-032-3-3-normal-exact/pack_data.sv
stream08-rowconst4-exact-pipelined-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-rowconst4-exact-pipelined-8mac \
	  $(COMMON) $(MATRICES_STREAM) archive/m08/conv-i16-h13-t08-o4-m08-stream08-rowconst4-exact-pipelined.sv $(TB) --build \
	  -GNUM_MULT=8 -GALLOW_GOLDEN_MISMATCH=$(ALLOW_GOLDEN_MISMATCH)

run-stream08-wstream4: stream08-wstream4
	obj_dir/stream08-wstream4/Vtb
run-stream08-rowconst4-exact-pipelined: stream08-rowconst4-exact-pipelined-8mac
	obj_dir/stream08-rowconst4-exact-pipelined-8mac/Vtb

# Four-word prefetch variant: overlaps the first new column with the current
# convolution and retains the shared testbench/data contract.
stream08-prefetch4:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-prefetch4 \
	  $(COMMON) $(MATRICES_STREAM) archive/m04/conv-i20-h16-t08-o4-m04-stream08-prefetch4.sv $(TB) --build

stream08-prefetch4-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-prefetch4-8mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i20-h16-t08-o4-m08-stream08-prefetch4.sv $(TB) --build

stream08-prefetch4-rowconst4-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-prefetch4-rowconst4-8mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4.sv $(TB) --build

# Eight-word prefetch captures both new feature columns during the active tile.
stream08-prefetch8-rowconst4-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-prefetch8-rowconst4-8mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4.sv $(TB) --build

# Truncated prefetch8 rowconst variant uses its matching truncation golden.
stream08-prefetch8-rowconst4-trunc-8mac: DATA = $(DATA_TRUNC)
stream08-prefetch8-rowconst4-trunc-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-prefetch8-rowconst4-trunc-8mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc.sv $(TB) --build \
	  -GNUM_MULT=8 -GALLOW_GOLDEN_MISMATCH=$(ALLOW_GOLDEN_MISMATCH)

# Exact-arithmetic prefetch8 variant uses the matching exact-weight golden.
stream08-prefetch8-rowconst4-exact-8mac: DATA = $(DATA_EXACT)
stream08-prefetch8-rowconst4-exact-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-prefetch8-rowconst4-exact-8mac \
	  $(COMMON) $(MATRICES_STREAM) archive/m08/conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-exact.sv $(TB) --build \
	  -GNUM_MULT=8 -GALLOW_GOLDEN_MISMATCH=$(ALLOW_GOLDEN_MISMATCH)

# Column-wide memory interface with the eight-word prefetch grouped into two
# four-word beats. Uses a dedicated no-waveform testbench.
stream08-prefetch8-rowconst4-column:
	$(VERILATOR_PREFETCH8_COLUMN_NO_TRACE) --binary --exe --Mdir obj_dir/stream08-prefetch8-rowconst4-column \
	  $(COMMON) $(MATRICES_STREAM) conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-column.sv $(TB_PREFETCH8_COLUMN) --build

# Truncated-arithmetic variant with the same column-wide memory protocol.
stream08-prefetch8-rowconst4-trunc-column: DATA = $(DATA_TRUNC)
stream08-prefetch8-rowconst4-trunc-column:
	$(VERILATOR_PREFETCH8_COLUMN_NO_TRACE) --binary --exe --Mdir obj_dir/stream08-prefetch8-rowconst4-trunc-column \
	  $(COMMON) $(MATRICES_STREAM) conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc-column.sv $(TB_PREFETCH8_COLUMN) --build

# Four-MAC column variant uses the same truncated workload and memory testbench.
stream08-prefetch8-rowconst4-trunc-column-4mac: DATA = $(DATA_TRUNC)
stream08-prefetch8-rowconst4-trunc-column-4mac:
	$(VERILATOR_PREFETCH8_COLUMN_NO_TRACE) --binary --exe --Mdir obj_dir/stream08-prefetch8-rowconst4-trunc-column-4mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i24-h13-t08-o4-m04-stream08-prefetch8-rowconst4-trunc-column.sv $(TB_PREFETCH8_COLUMN) --build \
	  -GMAC_COUNT=4

stream08-prefetch4-rowconst4-latch-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-prefetch4-rowconst4-latch-8mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4-latch.sv $(TB) --build

stream08-prefetch4-rowconst4-temporal1-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-prefetch4-rowconst4-temporal1-8mac \
	  $(COMMON) $(MATRICES_STREAM) archive/m08/conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4-temporal1.sv $(TB) --build

stream08-exact-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-exact-8mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i16-h20-t08-o4-m08-stream08-exact.sv $(TB) --build

run-stream08-prefetch4: stream08-prefetch4
	obj_dir/stream08-prefetch4/Vtb
run-stream08-prefetch4-rowconst4: stream08-prefetch4-rowconst4-8mac
	obj_dir/stream08-prefetch4-rowconst4-8mac/Vtb
run-stream08-prefetch8-rowconst4: stream08-prefetch8-rowconst4-8mac
	obj_dir/stream08-prefetch8-rowconst4-8mac/Vtb
run-stream08-prefetch8-rowconst4-trunc: stream08-prefetch8-rowconst4-trunc-8mac
	obj_dir/stream08-prefetch8-rowconst4-trunc-8mac/Vtb
run-stream08-prefetch8-rowconst4-exact: stream08-prefetch8-rowconst4-exact-8mac
	obj_dir/stream08-prefetch8-rowconst4-exact-8mac/Vtb
run-stream08-prefetch8-rowconst4-column: stream08-prefetch8-rowconst4-column
	obj_dir/stream08-prefetch8-rowconst4-column/Vtb_prefetch8_column

run-stream08-prefetch8-rowconst4-trunc-column: stream08-prefetch8-rowconst4-trunc-column
	obj_dir/stream08-prefetch8-rowconst4-trunc-column/Vtb_prefetch8_column
run-stream08-prefetch8-rowconst4-trunc-column-4mac: stream08-prefetch8-rowconst4-trunc-column-4mac
	obj_dir/stream08-prefetch8-rowconst4-trunc-column-4mac/Vtb_prefetch8_column

run-stream08-prefetch4-rowconst4-latch: stream08-prefetch4-rowconst4-latch-8mac
	obj_dir/stream08-prefetch4-rowconst4-latch-8mac/Vtb
run-stream08-prefetch4-rowconst4-temporal1: stream08-prefetch4-rowconst4-temporal1-8mac
	obj_dir/stream08-prefetch4-rowconst4-temporal1-8mac/Vtb

lint:
	$(VERILATOR) --timing --lint-only $(COMMON) $(MUX) $(MATRICES_STD) archive/m04/conv-i16-h16-t16-o4-m04-std.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MUX) $(MATRICES_STD) conv-i16-h16-t16-o4-m08-std.sv $(TB) -GNUM_MULT=8
	verilator -DSIMULATION --top-module tb_column -Wno-fatal --timing --lint-only $(COMMON) $(MUX) $(MATRICES_STD) conv-i16-h16-t16-o4-m08-std-column.sv $(TB_COLUMN)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STD) conv-i16-h16-t00-o4-m16-all.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) archive/m04/conv-i16-h16-t04-o4-m04-stream04.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i16-h16-t04-o4-m08-stream04.sv $(TB) -GNUM_MULT=8
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i16-h16-t00-o4-m08-stream00.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) archive/m04/conv-i16-h16-t08-o4-mxx-stream08-generic.sv $(TB) \
	  -GNUM_MULT=$(NUM_MULT)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) archive/m04/conv-i16-h13-t08-o4-m04-stream08-wstream4.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i16-h13-t08-o4-m08-stream08-wstream4.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i16-h13-t08-o4-m08-stream08-rowconst4.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) archive/m08/conv-i16-h13-t08-o4-m08-stream08-rowconst4-exact.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) archive/m08/conv-i16-h13-t08-o4-m08-stream08-rowconst4-exact-pipelined.sv $(TB) -GNUM_MULT=8
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) archive/m04/conv-i20-h16-t08-o4-m04-stream08-prefetch4.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i20-h16-t08-o4-m08-stream08-prefetch4.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4.sv $(TB)
	$(VERILATOR) --timing --lint-only $(DATA_TRUNC) $(PARAM) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES_STREAM) conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc.sv $(TB)
	$(VERILATOR) --timing --lint-only $(DATA_EXACT) $(PARAM) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES_STREAM) archive/m08/conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-exact.sv $(TB)
	$(VERILATOR_PREFETCH8_COLUMN_NO_TRACE) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-column.sv $(TB_PREFETCH8_COLUMN)
	$(VERILATOR_PREFETCH8_COLUMN_NO_TRACE) --timing --lint-only $(DATA_TRUNC) $(PARAM) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES_STREAM) conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc-column.sv $(TB_PREFETCH8_COLUMN)
	$(VERILATOR_PREFETCH8_COLUMN_NO_TRACE) --timing --lint-only $(DATA_TRUNC) $(PARAM) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES_STREAM) conv-i24-h13-t08-o4-m04-stream08-prefetch8-rowconst4-trunc-column.sv $(TB_PREFETCH8_COLUMN) -GMAC_COUNT=4
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4-latch.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) archive/m08/conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4-temporal1.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i16-h20-t08-o4-m08-stream08-exact.sv $(TB)

clean:
	rm -rf obj_dir dump.fst dump.vcd
