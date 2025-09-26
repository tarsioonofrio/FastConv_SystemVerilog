# Scripts de Automação

Os arquivos desta pasta encadeiam tarefas recorrentes do fluxo FastConv:

- `build-sim.sh`: inicializa um projeto `fast-conv` 2D, executa as fases de build, bind e quantização, roda simulações randômicas para múltiplos tamanhos e limpa artefatos temporários.
- `multiple-do.sh`: varre cada diretório informado, executa `vsim -do sim.do` com diferentes datasets (`file-032` até `file-512`), salva `run.txt` e copia `sim_summary.txt` para cada pasta de saída.
- `multiple-make.sh`: invoca `make` sequencialmente para cada arquivo de dados de simulação, facilitando a recompilação em lote.
- `multiple-power-eval.sh`: percorre projetos `tcn*`, roda a síntese lógica (`genus -f run_logical_synthesis.tcl`), simulação pós-layout (`xrun`) e avaliação de potência (`genus -f run_power.tcl`).
- `multiple-synth.sh`: executa apenas a síntese lógica para cada diretório listado, removendo relatórios antigos antes de chamar o Genus.
- `multiple-time-arch.sh`: chama `time-arch.py` para cada pasta recebida e gera as tabelas de tempo correspondentes.
- `reports.py`: agrega relatórios de área, clock gating e potência gerados pela síntese e produz `data/report.csv` e `data/report_transposed.csv`.
- `time-arch.py`: busca `sim_summary.txt` nas pastas de resultados e monta `time.csv` com o tempo de simulação por tamanho.
- `time.py`: consolida todos os `data/time.csv` gerados pelos projetos em uma única tabela pivotada (`data/time.csv`).
- `test-do.bat.sh`: suíte Bats que garante a disponibilidade do ModelSim e roda `vsim` em cada subpasta contendo `sim.do`.

Use estes scripts para automatizar execuções em lote e consolidar os relatórios utilizados nas análises.
