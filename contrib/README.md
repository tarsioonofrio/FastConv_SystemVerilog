# Contrib

Este diretório concentra protótipos, estudos e materiais auxiliares que servem de referência para o desenvolvimento do FastConv. Cada subpasta guarda um recorte específico:

- `_docs/`: apresentações, artigos e planilhas de apoio utilizadas durante as investigações (por exemplo `bind-nest.pdf`, `example-seq.tex`).
- `control/`, `control-basic/`, `control-multiple/` e `control-reuse/`: variantes de controladores escritos em SystemVerilog (arquivos `control.sv`, `tb_control.sv`, `pack_conv.sv` etc.) acompanhadas de dados de estímulo (`data.sv`, `data-mem.sv`), scripts de simulação ModelSim (`sim.tcl`, `wave.do`) e listas de arquivos.
- `conv/` e `conv-old/`: implementações de blocos de convolução e respectivos testbenches (`testbench.sv`), organizadas em subpastas que isolam diferentes arranjos de multiplicadores e multiplexadores.
- `core-basic/` e `core-reuse/`: versões de núcleo de processamento com foco em diferentes estratégias de reutilização de hardware, com fontes SystemVerilog e ambientes de simulação dedicados.
- `matrix-generator/`: utilitários e fontes relacionados à geração de matrizes e estímulos específicos para experimentos de convolução.

Use estas referências como ponto de partida ao comparar abordagens ou recuperar scripts de simulação alternativos.
