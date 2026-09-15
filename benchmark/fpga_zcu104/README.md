# Benchmark FPGA ZCU104 / WinoGen

Este diretório isola o experimento FPGA pedido em `tmp/winogen-fpa.md`. O
alvo é a mesma família usada pelo WinoGen:

| Campo | Valor |
| --- | --- |
| Vivado de referência | 2023.2 |
| Board de referência | ZCU104 |
| Part | `xczu7ev-ffvc1156-2-e` |
| Top RTL | `Conv` |
| Variante | `rtl/conv2x2/conv-i16-h16-t16-o4-m08-std.sv` |
| Precisão | 20 bits (`NBITS=20`) |
| Transformada | TC2x2 / F(2,3), saída 2x2 |
| MACs físicos | 8 |
| Dataset | `rtl/conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv` |

O RTL original não é modificado. Os manifestos e scripts apontam para os
arquivos canônicos do projeto; somente artefatos deste diretório são gerados
pelo fluxo.

## Estado desta execução

O checkout local não expõe `vivado`, `xvlog`, `xelab` ou `xsim`, portanto os
artefatos locais mantêm WNS, recursos pós-route, Fmax, power e cobertura SAIF
como `null`/`PENDING`. Isso não bloqueia a campanha: o catálogo de módulos da
Paxos confirmou `xilinx/vivado/2023.2`, com `vivado`, `xvlog`, `xelab` e `xsim`
disponíveis após `module load xilinx/vivado/2023.2`.

A Paxos foi verificada pelo endpoint institucional `paxos.inf.pucrs.br:8888`.
Ela oferece Genus 21.12/Xcelium 23.03 para o fluxo ASIC e Vivado 2023.2 para
esta campanha FPGA. O checkout persistente remoto está sujo e em outro commit;
por isso ele não deve ser resetado nem usado diretamente. A execução deve usar
um checkout/worktree isolado exatamente no commit publicado, conforme
`AGENTS.md`. A evidência completa está em
[`results/paxos_probe.md`](results/paxos_probe.md).

A validação funcional disponível localmente foi executada com Verilator e
passou: 2.025 inverse tiles, 23.675 ciclos, 8.100 writes válidos, zero samples
clipped e zero invalid output beats. Isso é apenas uma sanidade local do RTL,
não o resultado remoto final pedido para a campanha. O workload usa os dados
determinísticos do pacote gerado (não zeros); a seed documentada para o
workload de potência é `1`.

## Fluxo

1. `scripts/run_rtl_validation.sh` compila/executa o testbench de regressão e
   o testbench de workload repetido.
2. `scripts/synth_impl.tcl` faz síntese, opt, placement, phys-opt, routing,
   checkpoint e relatórios para um período solicitado.
3. `scripts/run_fmax.py` executa o sweep pós-route e refina a fronteira de
   timing; ele deve ser chamado na Paxos depois de carregar `xilinx/vivado/2023.2`.
4. `scripts/power_vectorless.tcl` gera vectorless typical/maximum a partir do
   checkpoint roteado.
5. `scripts/post_impl_saif.tcl` prepara a timing simulation pós-implementação;
   `scripts/run_post_impl_saif.sh` compila o netlist com XSim e
   `scripts/xsim_saif.tcl` abre a janela útil, gera SAIF e encerra.
6. `scripts/power_saif.tcl` importa o SAIF com `-strip_path`, salva o relatório
   de mapeamento e calcula power nos dois corners.
7. `scripts/collect_results.py` consolida relatórios em CSV, JSON e Markdown.

O Experimento A usa exatamente `317 MHz`, período `3.154574 ns`, e nunca reduz
a frequência para obter PASS. O Experimento B só chama uma frequência Fmax se
uma implementação pós-route tiver WNS >= 0; uma estimativa de período não é
aceita como Fmax.

## Métricas e convenções

Latência e II são medidos em ciclos no workload RTL. Para esta variante o job
processa a campanha completa do pacote. O GOPS publicado pelo coletor é
`2*k^2*n^2*C_in*C_out` por tile, contando MAC como duas operações, e fica
marcado como *equivalent direct-convolution GOPS*; não se afirma que seja uma
convenção explicitamente idêntica à do WinoGen.

Power é sempre rotulado como **Vivado post-route estimate**. Vectorless é
baseline/sanity check; o resultado principal, quando disponível, é SAIF de
timing simulation pós-implementation. Nenhum valor é chamado de medição física.

## Referência WinoGen (Tabela 1, kernel 3x3)

| Design | bits | DSP | LUT | FF | equivalent throughput (GOPS) |
| --- | ---: | ---: | ---: | ---: | ---: |
| F(4,3) PNmin | 8--16 | 6 | 2441 | 3587 | 9.883 |
| F(4,3) constrained | 8--16 | 48 | 8267 | 11678 | 123.824 |
| F(4,3) PNmax | 8--16 | 144 | 17472 | 18476 | 371.472 |
| F(6,3) PNmin | 8--16 | 8 | 3757 | 5703 | 12.508 |
| F(6,3) constrained | 8--16 | 128 | 31899 | 25307 | 412.020 |
| F(6,3) PNmax | 8--16 | 256 | 41093 | 40238 | 835.812 |

Essa referência não é uma medição do nosso design: WinoGen é 8--16 bits e o
baseline deste projeto é 20 bits. A comparação de sistema WinoGen `F(4,3) x12`
e `F(6,3) x5` não é usada para comparar diretamente um único core.

## Comandos em ambiente Vivado

```bash
vivado -mode batch -source benchmark/fpga_zcu104/scripts/synth_impl.tcl \
  -tclargs 317mhz 3.154574
python3 benchmark/fpga_zcu104/scripts/run_fmax.py
python3 benchmark/fpga_zcu104/scripts/collect_results.py
# depois de uma implementação roteada:
bash benchmark/fpga_zcu104/scripts/run_post_impl_saif.sh 317mhz
vivado -mode batch -source benchmark/fpga_zcu104/scripts/power_saif.tcl \
  -tclargs 317mhz reports/317mhz/activity.saif /tb_power
```

Os comandos de simulação SAIF devem ser executados somente depois que o
checkpoint routed, o netlist de timing e o SDF forem gerados pelo Vivado. A
captura de VCD do `tb_power.sv` é opcional e só é ativada ao compilar com
`-DPOWER_DUMP`; a campanha padrão compila sem essa macro e não gera VCD.
