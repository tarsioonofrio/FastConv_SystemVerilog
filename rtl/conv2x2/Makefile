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

.PHONY: all std all16 stream4-4mac stream4-8mac stream12 \
        run run-std run-all16 run-stream4-4mac run-stream4-8mac \
        run-stream12 lint clean

all: std

std:
	$(VERILATOR) --binary --exe --Mdir obj_dir/std \
	  $(COMMON) $(MUX) $(MATRICES_STD) conv-std-i16-p32-o4-m4.sv $(TB) --build

all16:
	$(VERILATOR) --binary --exe --Mdir obj_dir/all16 \
	  $(COMMON) $(MUX) $(MATRICES_STD) conv-all-i16-p16-o4-m16.sv $(TB) --build \
	  -GNUM_MULT=16

stream4-4mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream4-4mac \
	  $(COMMON) $(MATRICES_STREAM) conv-stream4-i16-p16-o4-m4.sv $(TB) --build \
	  -GNUM_MULT=4

stream4-8mac:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream4-8mac \
	  $(COMMON) $(MATRICES_STREAM) conv-stream4-i16-p16-o4-m8.sv $(TB) --build \
	  -GNUM_MULT=8

# The generic stream12-family implementation supports NUM_MULT=2, 4 and 8. Override
# NUM_MULT on the command line, for example: make stream12 NUM_MULT=8.
NUM_MULT ?= 4
stream12:
	$(VERILATOR) --binary --exe --Mdir obj_dir/stream12-$(NUM_MULT) \
	  $(COMMON) $(MATRICES_STREAM) conv-stream12-generic-i16-p24-o4-m2-4-8.sv $(TB) --build \
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

lint:
	$(VERILATOR) --timing --lint-only $(COMMON) $(MUX) $(MATRICES_STD) conv-std-i16-p32-o4-m4.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STD) conv-all-i16-p16-o4-m16.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-stream4-i16-p16-o4-m4.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-stream4-i16-p16-o4-m8.sv $(TB)
	$(VERILATOR) --timing --lint-only $(COMMON) $(MATRICES_STREAM) conv-stream12-generic-i16-p24-o4-m2-4-8.sv $(TB) \
	  -GNUM_MULT=$(NUM_MULT)

clean:
	rm -rf obj_dir dump.fst dump.vcd
