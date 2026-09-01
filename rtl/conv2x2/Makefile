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

.PHONY: all std all16 stream4-4mac stream4-8mac stream12 stream12-prefetch4 \
        run run-std run-all16 run-stream4-4mac run-stream4-8mac \
        run-stream12 run-stream12-prefetch4 lint clean

all: std

std:
	$(VERILATOR) --binary --exe --Mdir obj_dir/std \
	  $(COMMON) $(MUX) $(MATRICES_STD) conv-i16-h16-t16-o4-m04-std.sv $(TB) --build

all16:
	$(VERILATOR) --binary --exe --Mdir obj_dir/all16 \
	  $(COMMON) $(MUX) $(MATRICES_STD) conv-i16-h16-t00-o4-m16-all.sv $(TB) --build \
	  -GNUM_MULT=16

stream4-4mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream4-4mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i16-h16-t00-o4-m04-stream4.sv $(TB) --build \
	  -GNUM_MULT=4

stream4-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream4-8mac \
	  $(COMMON) $(MATRICES_STREAM) conv-i16-h16-t00-o4-m08-stream4.sv $(TB) --build \
	  -GNUM_MULT=8

# The generic stream12-family implementation supports NUM_MULT=2, 4 and 8. Override
# NUM_MULT on the command line, for example: make stream12 NUM_MULT=8.
NUM_MULT ?= 4
stream12:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream12-$(NUM_MULT) \
	  $(COMMON) $(MATRICES_STREAM) conv-i16-h16-t08-o4-m02-04-08-stream12-generic.sv $(TB) --build \
	  -GNUM_MULT=$(NUM_MULT)

run: run-std
run-std: std
	obj_dir/std/Vtb
run-all16: all16
	obj_dir/all16/Vtb
run-stream4-4mac: stream4-4mac
	obj_dir/stream4-4mac/Vtb
run-stream4-8mac: stream4-8mac
	obj_dir/stream4-8mac/Vtb
run-stream12: stream12
	obj_dir/stream12-$(NUM_MULT)/Vtb

# Four-word prefetch variant: overlaps the first new column with the current
# convolution and retains the shared testbench/data contract.
stream12-prefetch4:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream12-prefetch4 \
	  $(COMMON) $(MATRICES_STREAM) conv-i20-h16-t08-o4-m04-stream12-prefetch4.sv $(TB) --build

run-stream12-prefetch4: stream12-prefetch4
	obj_dir/stream12-prefetch4/Vtb

lint:
	$(VERILATOR) --timing --lint-only $(COMMON) $(MUX) $(MATRICES_STD) conv-i16-h16-t16-o4-m04-std.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STD) conv-i16-h16-t00-o4-m16-all.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i16-h16-t00-o4-m04-stream4.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i16-h16-t00-o4-m08-stream4.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i16-h16-t08-o4-m02-04-08-stream12-generic.sv $(TB) \
	  -GNUM_MULT=$(NUM_MULT)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-i20-h16-t08-o4-m04-stream12-prefetch4.sv $(TB)

clean:
	rm -rf obj_dir dump.fst dump.vcd
