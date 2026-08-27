SRC = conv.sv
TB = testbench.sv
DATA = ../conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv
PARAM = ../conv2x2/pack-param/tcn4/pack_param.sv
MUX = ../conv2x2/mux-mult/tcn4/mux_mult_04.sv
MATRICES = mult-matrices/tcn4/mult_matrices.sv
MEM = ../mem/mem.sv

OBJDIR = obj_dir
BIN = $(OBJDIR)/Vtb
VERILATOR = verilator -j 0 -DSIMULATION -DSTREAMING_CONV_TEST --trace-fst --trace-max-array 4096 --top-module tb -Wno-fatal

all: $(BIN)

$(BIN): $(SRC) $(TB) $(DATA) $(PARAM) $(MUX) $(MATRICES) $(MEM)
	$(VERILATOR) --binary --exe $(DATA) $(PARAM) $(MUX) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES) $(SRC) $(TB) --build

lint:
	$(VERILATOR) --timing --lint-only $(DATA) $(PARAM) $(MUX) $(MEM) ../csa/csa_lib.sv ../multip/multip.sv $(MATRICES) $(SRC) $(TB)

run: all
	$(BIN)

clean:
	rm -rf $(OBJDIR) dump.fst dump.vcd
