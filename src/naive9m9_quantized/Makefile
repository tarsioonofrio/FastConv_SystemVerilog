SRCDIR = .
SRC = $(SRCDIR)/pack_conv.sv $(SRCDIR)/mac_op9.sv $(SRCDIR)/naive_conv.sv

TB = tb_naive_conv.sv
TOP_MODULE = tb

OBJDIR = obj_dir
BIN = $(OBJDIR)/V$(TOP_MODULE)

# Comando base do Verilator
VERILATOR = verilator --trace --binary --exe --top-module $(TOP_MODULE)

# Regra principal (default): compilação e construção
all: $(BIN)

# Regra para compilar e gerar o binário, se algum dos arquivos fonte foi modificado
$(BIN): $(SRC) $(TB)
	$(VERILATOR) $(SRC) $(TB) --build

# Regra de Lint para verificar erros e warnings sem compilar
lint:
	verilator  --timing --lint-only $(SRC) $(TB)

# Limpeza dos arquivos gerados
clean:
	rm -rf $(OBJDIR) dump.vcd

# Alvo de execução
run: all
	$(BIN)

# Alvo de execução com GTKWave
view: run
	gtkwave dump.vcd &
