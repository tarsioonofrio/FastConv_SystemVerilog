# Scripts de Automação

Os arquivos desta pasta encadeiam tarefas recorrentes do fluxo FastConv:

- `build-sim.sh`: ainda pode inicializar um projeto novo no `fast-conv`, gerar datasets e executar simulações exploratórias. Ele não é o coletor nem o fluxo oficial das arquiteturas já versionadas.
- `multiple-do.sh`: auxiliar legado para árvores que possuem `sim.do` e datasets `file-*`; não acompanha o layout atual `rtl/conv*/data` nem o wrapper oficial `test.fish`.
- `multiple-make.sh`: auxiliar legado para projetos com `Makefile` e os caminhos antigos `data/sim/file-*`; não é necessário para as sínteses atuais.
- `multiple-power-eval.sh`: fluxo legado, dependente da estrutura `sintese/`, `simSDF/` e módulos de ambiente; não deve ser usado com `rtl/conv*/synthesis/`.
- `multiple-synth.sh`: fluxo legado para `sintese/`; as sínteses atuais são executadas pelos scripts `logical/*.tcl` dentro de cada projeto.
- `multiple-time-arch.sh` e `time-arch.py`: geram a tabela antiga baseada em `src/<projeto>/data/sim_summary.txt`; foram substituídos pelo `time.csv` produzido por `report.py`.
- `report.py`: descobre somente os projetos em `rtl/conv*/synthesis/`, lê os logs de simulação anotada (`sim/xrun.log`) e os relatórios Genus de área, registradores e potência. Gera tabelas sem prefixos artificiais (`time.csv`, `logical.csv`, `power.csv`, `merged.csv` e tabelas analíticas) e `report.md` em `report/`, além de um conjunto isolado em `rtl/conv*/report/` para cada arquitetura. Nenhuma tabela `sys-*` é gerada. Use `--report-dir` para outro destino global e `--naive-synthesis-dir PATH` para habilitar explicitamente a tabela separada de razões contra uma síntese naive.
- `time-arch.py`: busca `sim_summary.txt` nas pastas de resultados e monta `time.csv` com o tempo de simulação por tamanho.
- `metrics.py`: calcula MAE/RMSE dos datasets de simulação quantizada e grava os resultados em `report/` (ou no diretório informado por `--report-dir`).
- `test-do.bat.sh`: suíte Bats que garante a disponibilidade do ModelSim e roda `vsim` em cada subpasta contendo `sim.do`.

Use estes scripts para automatizar execuções em lote e consolidar os relatórios utilizados nas análises.

## Relatórios consolidados

As sínteses atuais ficam dentro de cada arquitetura RTL, com uma pasta direta
por arquivo RTL, por exemplo
`rtl/conv2x2/synthesis/conv-stream4-i16-h16-t0-o4-m4/`. Para regenerar as tabelas do
repositório:

```bash
/home/tarsio/gaph/fast-convolution-rtl/.venv/bin/python scripts/report.py
```

Para comparar com uma implementação naive, informe a pasta do projeto de
síntese (ela deve conter os resultados `logical/`, `power/` e um log de
simulação):

```bash
/home/tarsio/gaph/fast-convolution-rtl/.venv/bin/python scripts/report.py \
  --naive-synthesis-dir /caminho/para/synthesis/naive
```

Sem essa opção, nenhuma razão contra naive é calculada. O Markdown global
inclui todas as tabelas CSV agregadas e analíticas; cada
`rtl/conv*/report/report.md` contém somente a arquitetura daquela pasta.

As tabelas analíticas geradas são `timing-summary.csv`, `area-hierarchy.csv`,
`power-breakdown.csv`, `register-budget.csv`, `throughput.csv`,
`energy-per-op.csv`, `mac-scaling.csv`, `pareto.csv`, `flow-status.csv` e
`functional-quality.csv`. As três primeiras são extraídas dos relatórios de
sintese; `register-budget.csv` combina as dimensões das janelas Winograd
(4x4, 5x5 e 6x6 para kernels 2x2, 3x3 e 4x4) com a contagem real dos bancos
registrados no RTL; as demais são derivações determinísticas de `merged.csv` ou dos
resultados de qualidade disponíveis. Em `register-budget.csv`, a coluna
`h_register_words` é contada diretamente nas declarações de `r_input_weight`, e
`t_register_words` nas declarações de bancos registrados de transformada/inversa
(`r_conv_temp`, `r_transform_row` e `r_inverse_row`). Vetores `w_*`
combinacionais e contadores de controle não entram nessas contagens. A coluna `mac_lanes` registra a quantidade
de lanes MAC da arquitetura, mas não é somada ao armazenamento, pois os
produtos são sinais `w_*` combinacionais.

O script reconhece tanto os logs Xcelium atuais (`xrun.log`) quanto o marcador
legado `Total execution time`. As tabelas antigas foram preservadas em
`report/legacy/`; elas não são usadas como entrada para a coleta atual.
