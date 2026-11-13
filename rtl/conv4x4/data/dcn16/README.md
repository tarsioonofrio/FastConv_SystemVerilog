# `dcn16`: convolução direta no controle rowconst-round (12 linhas)

A direta 3×3 escrita como identidade bilinear de 12 produtos (`make_custom_build.py`), no mesmo controle rowconst-round
do WP, com 16 bits e arredondamento. Entra nas varreduras de vazão e de camadas do hub
(`frentes/precisao-quantizada/piloto/vazao_f43.py`, `camadas_f43.py`).

## Falha na simulação de portas e correção (2026-11-08)

Eram duas causas diferentes: um índice fora da faixa no RTL (config de 7 × 7 com 48 multiplicadores) e o endereço de 16
bits do núcleo (as três de 42 × 42).

### Sintoma

Quatro das 16 configs passavam na simulação RTL e falhavam na simulação de portas, com canais de saída errados: as três
de 42 × 42 (`cin16-cout16-l10c1-s42`, com 12, 24 e 48 multiplicadores) e a de 48 multiplicadores em 7 × 7
(`mult48-...-l41c1-s7`). As outras 12, inclusive a de 12 × 12 com 48 multiplicadores, passavam.

### Diagnóstico

1. **Não é a simulação RTL:** `scripts/rtl_sim_config.sh` simula o RTL no Xcelium com os mesmos defines da síntese
   (`list-define.txt`, inclusive `ASIC_NUM_MULT`; o `run_flow_list.sh` simula só com o `NUM_MULT` padrão). As 5 configs
   suspeitas passaram.
2. **Não é timing:** `scripts/gate_sim_zero_delay.sh` simula a netlist sem SDF (`-nospecify -notimingchecks`). Falha
   do mesmo jeito, então a netlist calcula outra coisa.
3. **Não é o testbench:** o RTL com a lógica de limites do modo de portas do testbench passa, e as entradas entregues ao
   DUT são iguais nas duas simulações.
4. **Onde diverge:** `diag/trace.sh` grava, ciclo a ciclo, os pesos brutos e os registradores `r_input_weight` dos três
   grupos de lanes (`diag/spy_w_rtl.sv` no RTL e `diag/spy_w_gate.sv` na netlist, com os nomes achatados das
   instâncias). Na config `mult48-...-l41c1-s7`, os pesos brutos são iguais. Os registradores das lanes 12 a 14 (segundo
   grupo de 12) ficam em zero na netlist nas capturas do estado HADAMARD, mas recebem os valores certos no RTL. O primeiro
   ciclo divergente é 133.000 ns.
5. **Estrutura da netlist:** como as linhas da transformada de pesos da direta se repetem a cada 3, o Genus fundiu os
   registradores: sobram 9 `r_input_weight` (lanes 0-2, 12-14, 24-26). A netlist de 12 × 12, que passa, tem a mesma
   estrutura; o erro está na lógica que escolhe a linha capturada.

O RTL lê `w_weight_row[(count + 1)·ROWS_PER_CYCLE + lane / HADAMARD_SIZE]` e liga
`w_weight_row_enable[next_row_base + row]`. A guarda `count < STREAM_CYCLES − 1` mantém o índice dentro de 0..11 em
toda execução, mas a expressão, em `int`, cobre valores fora da faixa, e uma leitura fora da faixa vale X (o
sintetizador pode escolher qualquer valor). A causa exata dentro do Genus não foi isolada. A correção torna o índice
válido por construção:

    w_weight_row[(((count + 1) * ROWS_PER_CYCLE) + (lane / HADAMARD_SIZE)) % HADAMARD_SIZE][lane % HADAMARD_SIZE]
    w_weight_row_enable[(next_row_base + row) % HADAMARD_SIZE] = 1'b1;

Nas execuções reais o `% HADAMARD_SIZE` não muda nada (o índice já está na faixa); a simulação RTL é a mesma.

### Teste e aplicação

- Uma cópia do RTL com a correção, sintetizada na config `mult48-...-l41c1-s7`, passou no fluxo e na simulação de
  portas com SDF. A área foi de 52.187 para 52.267 µm² (+0,15%).
- A correção foi aplicada ao RTL versionado, e as 16 configs da direta foram ressintetizadas
  (`flow-idxfix.list`; `bash -l scripts/run_flow_list.sh rtl/conv4x4/data/dcn16/flow-idxfix.list <logs>`, em duas
  listas paralelas no tmux).
- Os outros RTLs rowconst (WP, `trn16`, bit-shift-ternary, TC) têm a mesma forma de índice e passam na simulação de portas em
  todas as configs sintetizadas. Por isso não foram mudados, mas um RTL novo deve usar a forma corrigida.

### Resultado da ressíntese com o índice corrigido

A config de 7 × 7 com 48 multiplicadores passou a fechar a simulação de portas. As de 12 × 12, 22 × 22 e 7 × 7, que já
passavam, continuam passando. As áreas mudaram de −0,35% a +0,15% (ruído de síntese). As três de 42 × 42 **continuaram falhando**, com
os mesmos 20.800 erros (canais de saída 3 a 15 inteiros, 13 × 1.600). Era outra causa.

### Segunda causa: endereço de 16 bits nas configs de 42 × 42

- **Simulação de portas com atraso zero:** os mesmos 20.800 erros, então é lógica, não timing.
- **Traço das portas do DUT** (`diag/spy_ports.sv` com `diag/trace.sh`): o RTL emite endereços de entrada até 0x1073D
  (67.389); a porta da netlist tem 16 bits. As saídas começam a divergir na primeira escrita que depende desses endereços.
- **Por quê:** o pacote do testbench guarda os mapas (16 · 42² = 28.224 palavras), depois uma seção reservada para pesos
  pré-transformados (16 · 16 · H² = 36.864 com H = 12) e só então os pesos brutos (2.304), que vão de 65.088 a 67.391.
  Os pesos do canal de saída 3 começam em 65.520 e cruzam 2^16, por isso o erro começa exatamente no canal 3. O
  testbench usa, no RTL, a largura mínima que a carga pede (17 bits) e, nas portas, os 16 bits fixos do núcleo
  sintetizado. No WP (H = 8), o mesmo pacote termina em 46.912 e cabe.
- **Correção:** as três configs de 42 × 42 passam a sintetizar o núcleo com `NADDR=17` (`top-parameters.txt`), e o
  testbench aceita `-define ASIC_NADDR=17` (`list-define.txt`) para a simulação de portas. O padrão continua 16, então
  as outras configs não mudam. `prep_camadas.py` (hub) aplica a mesma regra às configs novas: endereço mais largo quando o
  pacote passa de 2^16.

### Resultado

As 16 configs passam na simulação RTL, no fluxo ASIC (folga ≥ 0) e na simulação de portas. Com o endereço de 17 bits, a
área das três de 42 × 42 subiu de +0,08% a +0,21% (22.395, 34.000 e 52.616 µm² com 12, 24 e 48 multiplicadores). A
direta entra agora na camada de 40 × 40 das tabelas do hub (`camadas_f43.md`), sem mudar o melhor ponto de nenhuma camada.

Os scripts de tabela do hub contavam como aprovada uma simulação de portas que imprimia "simulation passed" e depois
falhava na conferência final com o golden (`FINAL_GATE_OUTPUT_GOLDEN_CHECK`). Agora também exigem que não haja
`ERROR GATE` (`sintese_f43.portas_ok`). Antes, essas configs não apareciam nas tabelas porque o fluxo parava antes da
potência.

## Ferramentas

`scripts/rtl_sim_config.sh <config> <log>` e `scripts/gate_sim_zero_delay.sh <config> <log>` (na raiz do repositório,
`bash -l`, no tmux). `diag/trace.sh <config> <prefixo> <spy.sv>`: traço por ciclo no RTL e na netlist com atraso zero
(o spy da netlist precisa dos nomes achatados que o Genus deu aos registradores).
