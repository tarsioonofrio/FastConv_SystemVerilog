# Estimativa de energia da macro SRAM para WPN16 4x4 m32

Esta nota registra uma estimativa inicial da energia de memória para a
arquitetura WPN16 4x4 com 32 multiplicadores. Ela complementa, mas não
substitui, o relatório de power do Joules: os resultados de SRAM abaixo são
calculados a partir dos valores informados no datasheet, não medidos no fluxo
ASIC atual.

## Macro identificada

Macro TSMC Memory Compiler localizada em:

```text
/pdk/tsmc/tsdn28hpcpuhdb4096x128m4mwa_170a/
```

É uma SRAM de porta dupla, ultra-alta densidade, em TSMC 28 nm HPC+, com
4096 palavras de 128 bits (524.288 bits = 64 KiB). O diretório contém
`DATASHEET/`, `NLDM/`, LEF, Verilog, GDS e SPICE. O datasheet e a Liberty
NLDM relevantes estão no corner `tt0p9v25c`, o mesmo corner typical de
0,9 V/25 °C empregado na campanha atual. O compilador está instalado em
`/pdk/tsmc/MC2_2012.02.00.d`; também foi identificada uma licença
`SRAM_LICENSE_13545.dat`, o que pode permitir gerar outras configurações.

Os caminhos e os números desta seção foram informados pelo usuário; os views
do PDK não foram inspecionados diretamente nesta máquina. Antes de usar a
macro em uma nova execução, confirme que os arquivos correspondem à revisão,
configuração e corner exatos.

## Números informados do datasheet

| Parâmetro | Valor |
| --- | ---: |
| Capacidade | 4096 × 128 bits = 64 KiB |
| Portas | 2 |
| Área | 118.814 µm² (374,0 × 317,7 µm) |
| Área normalizada | ≈ 0,227 µm²/bit |
| Leakage | 186 µA; ≈ 167,4 µW a 0,9 V |
| Dinâmica, uma porta lendo | 28,1 µA/MHz; ≈ 25,29 pJ por acesso de 128 bits |
| Dinâmica, uma porta escrevendo | 31,2 µA/MHz; ≈ 28,08 pJ por acesso de 128 bits |
| Standby | 2,4 µA/MHz, conforme a unidade apresentada no datasheet |
| Tempo de acesso da porta A | 0,54 ns; ciclo mínimo de 1,0 ns |

A conversão usada é `energia = corrente normalizada × tensão`:

```text
28,1 µA/MHz × 0,9 V = 25,29 pJ
31,2 µA/MHz × 0,9 V = 28,08 pJ
```

Os números de dinâmica pressupõem 50% de atividade e saída sem carga, segundo
o datasheet. A aplicação direta desses valores por acesso assume que a
definição de atividade e o perfil de acesso do workload são compatíveis com
essa caracterização; a conta abaixo não aplica correção adicional.

## Estimativa por camada do WPN16 4x4 m32

Contadores de acesso informados para o workload:

| Operação | Acessos por camada | Energia por acesso | Energia estimada |
| --- | ---: | ---: | ---: |
| Leitura de entrada | 9.900 | 25,29 pJ | 250,371 nJ |
| Leitura de saída | 7.992 | 25,29 pJ | 202,118 nJ |
| Escrita de saída | 9.216 | 28,08 pJ | 258,785 nJ |
| **Dinâmica total da SRAM** | **27.108** | — | **711,274 nJ** |

Os beats cabem em uma palavra da macro: uma coluna de entrada contém
`6 × 16 = 96 bits`, e uma coluna de saída contém 64 bits, ambos abaixo da
largura de 128 bits. Isso não significa que os bits não usados tenham custo
nulo; a estimativa utiliza o valor de energia por acesso de 128 bits do
datasheet.

Com leakage de aproximadamente 167,4 µW, a energia estática depende da janela
de tempo da camada:

```text
E_leak = 167,4 µW × duração_da_janela
```

Os ≈7 nJ informados correspondem a uma janela de cerca de 41,8 µs. Assim, a
estimativa total para essa janela é aproximadamente 718 nJ por macro
(711 nJ dinâmica + 7 nJ leakage). Se a camada usar mais de uma macro, o
leakage deve ser multiplicado pelo número de macros alimentadas; a dinâmica
deve ser calculada com os acessos efetivamente direcionados a cada instância
e porta.

Como referência, os ≈711 nJ de dinâmica calculada são maiores que os 411 nJ
informados para o núcleo nessa comparação. A diferença destaca que a energia
de memória pode dominar a energia de computação neste cenário.

## Interpretação e limites

A macro disponível tem 64 KiB, enquanto os dados deste workload ocupam cerca
de 6 KiB. Por isso, os ≈711 nJ devem ser lidos como uma estimativa de
referência conservadora para a macro grande. É plausível que uma configuração
menor tenha menor energia por acesso, mas isso precisa ser confirmado com o
datasheet/Liberty da macro menor; o valor atual não é um limite físico formal
para qualquer configuração.

Esta estimativa ainda não é um resultado Joules com SRAM caracterizada. Para
integrá-la ao fluxo ASIC, é necessário vincular a Liberty de potência correta
da macro no corner usado, simular o modelo funcional correspondente no
Xcelium e confirmar no relatório hierárquico do Joules a atividade e o power
da instância SRAM. Se o modelo de potência da macro não for carregado, a
categoria `memory` zerada no relatório não representa consumo físico nulo.
