# Dados de Entrada e Resultados

As subpastas deste diretório seguem um padrão comum (por exemplo, `ifn9`, `nv`, `tcn4`, `tcn9`):

- `data.sv`: matriz de estímulo em SystemVerilog utilizada para parametrizar a convolução correspondente.
- `config/`: conjunto de arquivos JSON (`bind.json`, `build.json`, `gen.json`, `init.json`, `quant.json`) que descrevem o fluxo utilizado pelo `fast-conv` — desde a inicialização do projeto até a quantização.
- `sim/`: resultados de simulação separados por tamanho de instância (`file-032`, `file-064`, `file-128`, `file-256`, `file-512`). Cada subpasta reúne os arquivos gerados pela execução da simulação (`data.sv`, `d.txt`, `g.txt`, `s.txt`, `sim.txt`, além de `run.txt` e `sim_summary.txt` quando disponíveis).

Assim, basta copiar uma pasta-modelo e ajustar os JSONs para criar um novo conjunto de dados seguindo o mesmo fluxo de geração e validação.
