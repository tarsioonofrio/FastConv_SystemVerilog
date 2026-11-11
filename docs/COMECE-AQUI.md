# Comece aqui

Guia de entrada para quem vai trabalhar neste repositório. Leva de um clone limpo até rodar e modificar um acelerador, com
resultados conhecidos para conferir em cada passo. O `README.md` da raiz (em inglês) é a referência do artigo do ISCAS 2027;
este guia é o caminho de entrada e aponta para ele.

## 1. O que é o projeto

O FastConv é um núcleo de convolução 2-D (kernel 3×3, stride 1) em SystemVerilog. A entrada chega em colunas, em fluxo, e
o datapath troca a convolução direta por um **algoritmo rápido**. Cada tile de entrada passa por uma transformada linear e
os pesos por outra. Em seguida há um produto elemento a elemento (o "Hadamard", onde ficam os multiplicadores), e uma
transformada inversa gera o tile de saída. As três transformadas formam uma **identidade bilinear**: três matrizes que,
juntas, calculam exatamente a mesma convolução.

A pergunta da pesquisa é qual identidade gasta menos área e energia em hardware. Menos produtos economizam multiplicadores,
mas costumam exigir transformadas com frações (Toom-Cook). Transformadas só com somas e deslocamentos (Winograd polinomial,
"bit-shift", ternária) gastam mais produtos e menos lógica. O artigo do ISCAS 2027 mostrou que o WP 4×4, com 64
multiplicações, ocupa 64,6% menos área que o Toom-Cook 4×4, com 36. O trabalho atual testa identidades novas achadas por
busca (`bsn16`, `bsc16`, `bsh16`, `trn16`, ...) no mesmo controlador, com cargas reais da ResNet-18.

Todo o fluxo é o mesmo para qualquer identidade:

1. A identidade (três matrizes) vem do repositório `winograd-identities` ou da construção clássica.
2. O `fast-convolution-rtl` (CLI `fast-conv`) gera, a partir dela, os módulos auxiliares em SV, o dataset de entrada e a
   saída de referência (golden) bit a bit.
3. `rtl/stream-column/gen_stream_column.py` gera o RTL do núcleo para essa identidade.
4. Cada **configuração** (`rtl/conv*/synthesis/<config>/`) fixa RTL, dataset, precisão e carga. Ela roda simulação RTL
   (Verilator ou Xcelium), síntese (Genus), simulação de portas (Xcelium) e potência (Genus).
5. `make report` junta as evidências em `report/*.csv`.

## 2. Leitura, nesta ordem

| Arquivo | Para quê |
|---|---|
| `README.md` (raiz) | estrutura, quick start, de onde sai cada número do artigo |
| `rtl/stream-column/README.md` | o controlador compartilhado e como o RTL é gerado |
| `rtl/conv4x4/README.md` | os algoritmos e sufixos atuais (tabela de códigos) |
| `rtl/conv4x4/data/trn16/README.md` e `data/bsh16/README.md` | dois experimentos completos, do jeito que um experimento novo deve ficar registrado |
| `docs/repository-organization.md` | onde cada coisa mora e as regras de proveniência |
| `report/iscas2027/README.md` | o artigo bloco a bloco, ligado às evidências |
| `rtl/conv2x2/doc/history.md` | o histórico longo do controlador (consulta, não leitura linear) |

O PDF do artigo e a dissertação não estão no repositório. Peça ao orientador.

## 3. Acesso e máquinas

- **Máquina:** o projeto roda no `gaphs04`. O `paxos` também tem as ferramentas, mas é usado para síntese física pelo grupo.
  O `/sim` não é compartilhado entre as duas máquinas. O home é.
- **Ferramentas:**
  - Verilator 5.052: `module load verilator/5.052` e `source /opt/rh/gcc-toolset-15/enable`.
  - Cadence Genus 21.12: `module load cadence/genus/211`.
  - Xcelium 23.03: `module load cadence/xcelium/2303`.
  - Os scripts carregam os módulos sozinhos.
- **Biblioteca:** TSMC 28 nm HPC+ (`tcbn28hpcplusbwp30p140`) em `/pdk/tsmc/PDK28/`. Está sob NDA e nunca vai para o git.
  Os caminhos ficam no `scripts/mmmc_tsmc_28_bv.tcl` de cada configuração.
- **Python:** o do sistema é 3.6 e não serve. Crie um ambiente com o 3.12:

      python3.12 -m venv ~/venvs/fastconv && ~/venvs/fastconv/bin/pip install pandas numpy

- **Repositórios irmãos:** clone `fast-convolution-rtl` ao lado deste (o `Makefile` procura `../fast-convolution-rtl`). Ele
  só é necessário para gerar datasets novos.
- **Hub privado:** alguns READMEs citam caminhos do hub de coordenação, que é privado (`fast-conv`, em
  `frentes/precisao-quantizada/piloto/`). Ali ficam as tabelas do estudo de precisão e os scripts `reproduz.sh` que dependem
  dele. Peça acesso se precisar.

## 4. Regras do servidor (obrigatórias)

- **Tudo roda dentro do `tmux`**, uma sessão por job, com nome `fastconv-<assunto>-<data>` (ex.:
  `fastconv-synth-bsh16-20261115`). Os alvos EDA do `Makefile` se recusam a rodar fora do tmux.
- **No máximo 8 threads no total** para os seus jobs. O servidor é compartilhado com síntese física e simulação de outros
  projetos.
- **No tmux, use shell de login**: `bash -l script.sh`. Sem isso, o comando `module` não existe e aparece
  `verilator: command not found`.
- **Disco:** cada configuração gera até cerca de 1 GB de atividade (`sim/dut.shm`), que não é versionada. Apague os `.shm`
  das suas rodadas depois de medir a potência.

## 5. Primeira semana: exercícios com resposta conhecida

Rode tudo na raiz do repositório, dentro do tmux.

1. **Simulação RTL de um ponto do artigo** (WPff):

       module load verilator/5.052; source /opt/rh/gcc-toolset-15/enable
       scripts/sim-config.sh conv4x4 conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column-nbits16-cin3-cout12

   Esperado: `stream-column simulation passed: ... cycles_to_end=21573`.

2. **O mesmo para o `trn16` com carga real** (`conv-trn16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8-twopass-round-column-frac0-extra0-nbits16-cin16-cout16-l10c1`).
   Esperado: `passed`, `cycles_to_end=251437`.

3. **Controle negativo:** o mesmo comando do item 2 com `-GROUND=0` no fim tem que **falhar**, com
   `output golden mismatch count: 3840`. Um teste que não falha quando deveria não prova nada.

4. **Regerar os relatórios:**

       make report PYTHON=~/venvs/fastconv/bin/python && git status --short

   Esperado: nenhuma diferença, ou só nos últimos dígitos de `mae`/`rmse` (versões diferentes do numpy). Em
   `report/flow-status.csv`, 181 de 182 configurações têm `complete=True`.

5. **Fluxo ASIC completo de uma configuração pequena**, em pasta própria para não sobrescrever a evidência versionada.
   Copie uma config `cin3-cout12` do `bsh16` para um nome novo e rode:

       make flow ARCH=conv4x4 CONFIG=<sua cópia>

   Compare a área de `logical/results/reports/Conv_area.rpt` e a potência de `power/power_evaluation.txt` com a linha da
   config original em `report/merged.csv`. Devem coincidir, porque a síntese do Genus é determinística com as mesmas
   entradas. Apague a cópia depois.

6. **Ler um RTL gerado:** abra `rtl/conv4x4/conv-trn16-...-twopass-round-column.sv` e ache as três transformadas, os 8
   multiplicadores e a acumulação da inversa. Compare com as matrizes de `rtl/conv4x4/data/trn16/make_custom_build.py`.

## 6. Como o repositório se organiza (resumo)

- **A configuração é a identidade de um resultado.** O `list-file.txt` diz exatamente o que foi compilado, e o
  `top-parameters.txt` e o `list-define.txt` completam. Uma mudança de RTL, dataset ou precisão exige uma **config nova**.
  Nunca refaça um resultado em cima de uma config já fechada.
- **RTL atual** fica na raiz de `rtl/conv*/`. O que foi aposentado vai para `archive/`, junto com config e dataset, e nada
  se move pela metade.
- **Tabelas nunca são editadas à mão.** Tudo em `report/` sai de `make report`.
- **Logs de EDA são versionados em texto** (`xrun.log`, `genus` reports, `power_evaluation.txt`). Os avisos repetitivos de
  glitch do `xrun.log` são resumidos por `scripts/resume_xrun_log.py`, e o log completo fica local em `*.full.log`. Binários
  (`*.shm`, `*.db`, `*.sdf`, `fv/`) não entram no git.
- **"Pasta existe" não quer dizer "resultado existe".** Confira o log e o `report/flow-status.csv`.
- `make audit-layout` confere, sem mudar nada, se toda config aponta para arquivos que existem.

## 7. Como registrar um experimento

O padrão é o de `rtl/conv4x4/data/bsh16/README.md`:

1. **Pergunta**, em uma frase.
2. **Origem da identidade:** arquivo do `winograd-identities` e commit.
3. **Previsão registrada antes de sintetizar** (área, energia, erro), com a data. Se a previsão falhar, isso também é um
   resultado e fica escrito.
4. **Comandos exatos**, em scripts versionados (ex.: `derive_rtl.py`, `derive_configs.sh`, uma lista para
   `scripts/run_flow_list.sh`). Nada que gere um número publicado fica só no terminal.
5. **Resultado**, com tabela gerada por script a partir dos logs.

O README muda junto com o experimento, não no fim.

## 8. Git

- Trabalhe em uma branch por tarefa (`ic/<assunto>`) e abra um PR para `main`. O orientador revisa antes do merge.
- `git add` só de caminhos explícitos. Não use `git add -A` nem `git add .`, porque as rodadas geram muitos arquivos
  grandes que não devem entrar.
- As cerca de 60 branches remotas antigas (`backpressure`, `gating`, `tmp`, ...) são histórico. Só `main` importa. A tag
  `dissertation` marca o código da dissertação e a branch `iscas2027` o do artigo.

## 9. Armadilhas conhecidas

- **Larguras diferentes:** `TCff`/`TCpre` usam palavras de 20 bits e o resto 16. Toda comparação precisa declarar a largura.
- **Limite do Verilator:** linhas acima de cerca de 40 mil tokens são rejeitadas. Os `pack_data.sv` grandes são quebrados
  em 16 valores por linha.
- **Endereço de 16 bits:** cargas grandes (ex.: 42×42 com pesos brutos) estouram `NADDR=16`. Veja
  `rtl/conv4x4/data/dcn16/README.md`.
- **Ciclos RTL × portas:** o testbench RTL conta 40 ciclos a mais que a simulação de portas, um deslocamento fixo de início.
- **`make run` no `rtl/conv4x4`** compila o controlador antigo (`archive/conv.sv`). Para os RTL atuais, use
  `scripts/sim-config.sh`.
