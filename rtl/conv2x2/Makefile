# Unified local simulation entry point for every 2x2 architecture.
# Each target selects exactly one source file; all targets share testbench.sv.

DATA = data/tcn4/sim/sim-032-3-3-normal/pack_data.sv
PARAM = pack-param/tcn4/pack_param.sv
MUX = mux-mult/tcn4/mux_mult_04.sv
MATRICES_STD = mult-matrices/tcn4/mult_matrices.sv
MATRICES_STREAM = mult-matrices/stream/tcn4/mult_matrices.sv
MEM = ../mem/mem.sv
COMMON = $(DATA) $(PARAM) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv
TB = testbench.sv

VERILATOR = verilator -j 0 -DSIMULATION --trace-fst --trace-max-array 4096 \
            --top-module tb -Wno-fatal

.PHONY: all std all16 stream04-4mac stream04-8mac stream00-8mac stream08 stream08-wstream4 stream08-wstream4-8mac \
	stream08-rowconst4-8mac stream08-rowconst4-exact-8mac stream08-prefetch4-8mac stream08-exact-8mac \
        run run-std run-all16 run-stream04-4mac run-stream00-8mac \
        run-stream08 run-stream08-wstream4 run-stream08-prefetch4 lint clean

all: std

std:
	$(VERILATOR) --binary --exe --Mdir obj_dir/std \
	  $(COMMON) $(MUX) $(MATRICES_STD) conv-i16-h16-t16-o4-m08-std.sv $(TB) --build \
	  -GNUM_MULT=8

all16:
	$(VERILATOR) --binary --exe --Mdir obj_dir/all16 \
	  $(COMMON) $(MUX) $(MATRICES_STD) conv-i16-h16-t00-o4-m16-all.sv $(TB) --build \
	  -GNUM_MULT=16

stream04-4mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream04-4mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i16-h16-t04-o4-m04-stream04.sv $(TB) --build \
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
stream08:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-$(NUM_MULT) \
	  $(COMMON) $(MATRICES_STREAM) conv-i16-h16-t08-o4-mxx-stream08-generic.sv $(TB) --build \
	  -GNUM_MULT=$(NUM_MULT)

run: run-std
run-std: std
	obj_dir/std/Vtb
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
	  $(COMMON) $(MATRICES_STREAM) conv-i16-h13-t08-o4-m04-stream08-wstream4.sv $(TB) --build

stream08-wstream4-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-wstream4-8mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i16-h13-t08-o4-m08-stream08-wstream4.sv $(TB) --build

stream08-rowconst4-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-rowconst4-8mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i16-h13-t08-o4-m08-stream08-rowconst4.sv $(TB) --build

stream08-rowconst4-exact-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-rowconst4-exact-8mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i16-h13-t08-o4-m08-stream08-rowconst4-exact.sv $(TB) --build

run-stream08-wstream4: stream08-wstream4
	obj_dir/stream08-wstream4/Vtb

# Four-word prefetch variant: overlaps the first new column with the current
# convolution and retains the shared testbench/data contract.
stream08-prefetch4:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-prefetch4 \
	  $(COMMON) $(MATRICES_STREAM) conv-i20-h16-t08-o4-m04-stream08-prefetch4.sv $(TB) --build

stream08-prefetch4-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-prefetch4-8mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i20-h16-t08-o4-m08-stream08-prefetch4.sv $(TB) --build

stream08-exact-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream08-exact-8mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i16-h20-t08-o4-m08-stream08-exact.sv $(TB) --build

run-stream08-prefetch4: stream08-prefetch4
	obj_dir/stream08-prefetch4/Vtb

lint:
	$(VERILATOR) --timing --lint-only $(COMMON) $(MUX) $(MATRICES_STD) conv-i16-h16-t16-o4-m04-std.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MUX) $(MATRICES_STD) conv-i16-h16-t16-o4-m08-std.sv $(TB) -GNUM_MULT=8
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STD) conv-i16-h16-t00-o4-m16-all.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i16-h16-t04-o4-m04-stream04.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i16-h16-t04-o4-m08-stream04.sv $(TB) -GNUM_MULT=8
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i16-h16-t00-o4-m08-stream00.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i16-h16-t08-o4-mxx-stream08-generic.sv $(TB) \
	  -GNUM_MULT=$(NUM_MULT)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i16-h13-t08-o4-m04-stream08-wstream4.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i16-h13-t08-o4-m08-stream08-wstream4.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i16-h13-t08-o4-m08-stream08-rowconst4.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i16-h13-t08-o4-m08-stream08-rowconst4-exact.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i20-h16-t08-o4-m04-stream08-prefetch4.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i20-h16-t08-o4-m08-stream08-prefetch4.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i16-h20-t08-o4-m08-stream08-exact.sv $(TB)

clean:
	rm -rf obj_dir dump.fst dump.vcd
