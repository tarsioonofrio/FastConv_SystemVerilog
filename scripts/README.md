# Scripts de Automação

Os arquivos desta pasta encadeiam tarefas recorrentes do fluxo FastConv:

- `build-sim.sh`: inicializa um projeto `fast-conv` 2D, executa as fases de build, bind e quantização, roda simulações randômicas para múltiplos tamanhos e limpa artefatos temporários.
- `multiple-do.sh`: varre cada diretório informado, executa `vsim -do sim.do` com diferentes datasets (`file-032` até `file-512`), salva `run.txt` e copia `sim_summary.txt` para cada pasta de saída.
- `multiple-make.sh`: invoca `make` sequencialmente para cada arquivo de dados de simulação, facilitando a recompilação em lote.
- `multiple-power-eval.sh`: percorre projetos `tcn*`, roda a síntese lógica (`genus -f run_logical_synthesis.tcl`), simulação pós-layout (`xrun`) e avaliação de potência (`genus -f run_power.tcl`).
- `multiple-synth.sh`: executa apenas a síntese lógica para cada diretório listado, removendo relatórios antigos antes de chamar o Genus.
- `multiple-time-arch.sh`: chama `time-arch.py` para cada pasta recebida e gera as tabelas de tempo correspondentes.
- `report-all.py`: descobre os projetos em `rtl/conv*/synthesis/*`, lê os logs de simulação anotada (`sim/xrun.log`) e os relatórios Genus de área, registradores e potência, produzindo as tabelas consolidadas em `report/`. Use `--report-dir` para outro destino e `--chapter7-dir` para exportar as tabelas derivadas do capítulo 7.
- `time-arch.py`: busca `sim_summary.txt` nas pastas de resultados e monta `time.csv` com o tempo de simulação por tamanho.
- `metrics.py`: calcula MAE/RMSE dos datasets de simulação quantizada e grava os resultados em `report/` (ou no diretório informado por `--report-dir`).
- `test-do.bat.sh`: suíte Bats que garante a disponibilidade do ModelSim e roda `vsim` em cada subpasta contendo `sim.do`.

Use estes scripts para automatizar execuções em lote e consolidar os relatórios utilizados nas análises.

## Relatórios consolidados

As sínteses atuais ficam dentro de cada arquitetura RTL, por exemplo
`rtl/conv2x2/synthesis/stream4/tcn4-04mac/`. Para regenerar as tabelas do
repositório:

```bash
/home/tarsio/gaph/fast-convolution-rtl/.venv/bin/python scripts/report-all.py
```

O script reconhece tanto os logs Xcelium atuais (`xrun.log`) quanto o marcador
legado `Total execution time`. As tabelas antigas foram preservadas em
`report/legacy/`; elas não são usadas como entrada para a coleta atual.
