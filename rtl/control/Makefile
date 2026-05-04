SRCDIR = .
SRC =  $(SRCDIR)/control.sv

TB = $(SRCDIR)/tb.sv

TOP_MODULE = tb

OBJDIR = obj_dir
BIN = $(OBJDIR)/V$(TOP_MODULE)

# Comando base do Verilator
VERILATOR = verilator -j 0 -DSIMULATION --trace-fst --trace-max-array 4096 --binary --exe --top-module $(TOP_MODULE)

# Regra principal (default): compilação e construção
all: $(BIN)

# Regra para compilar e gerar o binário, se algum dos arquivos fonte foi modificado
$(BIN): $(SRC) $(TB)
	$(VERILATOR) $(SRC) $(TB) --build

# Regra de Lint para verificar erros e warnings sem compilar
lint:
	verilator  --timing --lint-only $(SRC)  $(TB)

# Limpeza dos arquivos gerados
clean:
	rm -rf $(OBJDIR) dump.fst

# Alvo de execução
run: all
	$(BIN)

# Alvo de execução com GTKWave
view: run
	gtkwave dump.fst &
