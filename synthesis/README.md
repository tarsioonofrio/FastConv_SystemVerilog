# Fluxo de síntese por arquitetura

Cada diretório `rtl/conv*` é o dono das suas configurações de síntese. A
estrutura de uma configuração é:

```text
rtl/conv3x3stream-if/synthesis/ifn9-12mac/
├── list-file.txt
├── list-define.txt
├── top-module.txt
├── testbench-file.txt
├── logical/
│   ├── logical_synthesis.tcl
│   └── run.sh
├── power/
│   ├── power.tcl
│   └── run.sh
├── scripts/
│   ├── constraints.sdc
│   ├── logical_synthesis_body.tcl
│   ├── mmmc_tsmc_28_bv.tcl
│   └── power.tcl
└── sim/
```

O diretório [`_template_sys`](./_template_sys/) é a origem para novas
configurações. Ele agora é autocontido: os corpos de síntese, o cenário MMMC,
as restrições e o fluxo de potência ficam dentro do template. O antigo
`synthesis/_source/` não é mais necessário.

`_template_conv` foi mantido somente como compatibilidade para experimentos
arquivados; as configurações novas devem ser copiadas de `_template_sys`.

`list-file.txt` usa caminhos relativos à raiz do repositório e contém todos os
arquivos HDL, inclusive o top. `list-define.txt` aceita a forma usada pelo
Xcelium (`-define NAME=VALUE`) e é convertida para o formato do Genus. O top e
o testbench são declarados, respectivamente, em `top-module.txt` e
`testbench-file.txt`. Configurações parametrizadas podem acrescentar
`top-parameters.txt`, com uma atribuição por linha, por exemplo
`NUM_MULT=2`.

## Exemplos

```bash
# Uma configuração específica
cd rtl/conv3x3stream-if/synthesis/ifn9-12mac/logical
bash ./run.sh

# Todas as etapas de uma configuração
cd rtl/conv3x3stream-if/synthesis/ifn9-12mac
bash ./logical/run.sh
bash ./sim/run.sh
bash ./power/run.sh

# O índice opcional da raiz percorre todas as configurações sob rtl/conv*
cd synthesis
bash ./run.sh -logical
bash ./run.sh rtl/conv3x3stream-tc/synthesis/tcn9-05mac
```

Os resultados do Genus continuam em `logical/results/`, com o netlist mapeado,
SDF, DB e relatórios da própria configuração. A análise de potência procura o
DB local e grava `power/power_evaluation.txt`; a simulação pós-síntese procura
o netlist e o testbench declarados pela configuração.

O `synthesis/run.sh` na raiz é apenas um índice de compatibilidade. Ele não
mantém configurações próprias e não executa automaticamente o diretório
`synthesis/_template_sys`.
