# FastConv_SystemVerilog

## Visão geral
FastConv é uma arquitetura de convolução 2D otimizada (Toom-Cook e variantes) descrita em SystemVerilog. O repositório reúne o RTL
sintetizável, pacotes de dados de teste, scripts de automação e os materiais de síntese usados para explorar diferentes
configurações de janelas e canais. Use-o como base para entender o pipeline completo: geração do hardware, simulação funcional e
fechamento de timing/potência.

## Estrutura do repositório
- `rtl/`: módulos SystemVerilog organizados por função (controle, memórias, multiplicadores, muxes, sistemas completos). Cada
  subpasta possui um `README.md` descrevendo o módulo e as portas.
- `data/`: conjuntos de pesos/feature maps e arquivos de configuração gerados pelo utilitário `fast-conv`.
- `scripts/`: automações para construir projetos FastConv, disparar simulações/sínteses em lote e consolidar relatórios.
- `synthesis/`: fluxo Cadence Genus/Xcelium com uma base (`source/`) e pastas de projetos sintetizados (por exemplo, `ifn9-06m`).
- `report/`: relatórios agregados em CSV produzidos após as sínteses.
- `contrib/`: experimentos anteriores, protótipos e materiais de apoio preservados para consulta.
- `copy-sv.sh`: utilitário para importar automaticamente novos artefatos SystemVerilog do gerador `fast-conv` para a árvore `rtl/`.

## Pré-requisitos
- Git e Python 3.8+ (para executar os scripts de automação e o utilitário `fast-conv`).
- CLI `fast-conv` instalada no PATH (https://github.com/paulocaroli/fast-conv) para gerar novos conjuntos de dados/RTL.
- ModelSim/QuestaSim (ou outro simulador compatível com `vsim`) para a simulação funcional.
- Cadence Genus (síntese lógica) e Cadence Xcelium (simulação pós-síntese) configurados no ambiente.
- Verilator opcional para lint estático via `veridian`.

## Simulação funcional (ModelSim/QuestaSim)
1. Escolha os arquivos de dados e parâmetros apropriados em `data/<projeto>/` (por padrão, `rtl/system/list-file.txt` já aponta para
o conjunto IFN9). Ajuste o conteúdo de `list-file.txt` e `list-def.txt` caso queira testar outra variante.
2. Entre em `rtl/system/` e execute o script TCL de compilação/simulação:
   ```bash
   cd rtl/system
   vsim -c -do sim.tcl
   ```
3. O script prepara a biblioteca `work`, compila os pacotes listados, monta o testbench `tb` e roda `7000ns` de simulação. Use `vsim`
   sem `-c` para abrir a interface gráfica, inspecionar as ondas (`wave.do`) e depurar.
4. Para campanhas maiores, utilize os utilitários da pasta `scripts/` (por exemplo, `multiple-do.sh` para varrer datasets ou
   `multiple-make.sh` para recompilar em lote).

## Síntese lógica e análise de potência (Cadence Genus)
1. Copie `synthesis/source/` para uma nova pasta (ex.: `cp -R synthesis/source synthesis/meu-projeto`) e ajuste `list-file.txt` e
   `list-define.txt` para o conjunto de arquivos desejado.
2. Em `synthesis/<projeto>/logical/`, execute a síntese:
   ```bash
   cd synthesis/<projeto>/logical
   genus -f run_logical_synthesis.tcl
   ```
   O script carrega os cenários MMMC (`scripts/mmmc_tsmc_28_bv.tcl`), sintetiza o topo definido e gera relatórios/netlists em
   `results/`.
3. Para análise de potência, entre em `synthesis/<projeto>/power/` e reutilize o netlist gerado:
   ```bash
   cd synthesis/<projeto>/power
   genus -f run_power.tcl
   ```
4. A simulação pós-síntese pode ser feita com o wrapper `sim/run-sim.sh`, que chama o Xcelium (`xrun`) usando o netlist mapeado e os
   mesmos arquivos/defines da síntese.
5. Consolide métricas com `scripts/reports.py` e `scripts/time.py`, que produzem os CSV em `report/`.

## Próximos passos
- Automatizar a troca de datasets sem editar `rtl/system/list-file.txt` manualmente.
- Revisar a quantização dos feature maps antes de gerar `data.sv`.

## TODO
- Garantir que o input feature map em `data.sv` não esteja quantizado.

