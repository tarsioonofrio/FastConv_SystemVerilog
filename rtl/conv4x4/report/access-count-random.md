# Contagem de acessos aleatórios — Conv4x4

O testbench [`testbench_access_count.sv`](../testbench_access_count.sv) mantém a
imagem em **32×32** e varia os canais de entrada e saída juntos:
`Cin=Cout={32, 64, 128, 256, 512}`. A cada leitura, o testbench fornece dados
pseudoaleatórios; a saída numérica não é comparada com golden. O objetivo é
medir conclusão, ciclos e beats de acesso.

## Variantes

| RTL | MACs | NBITS | Hadamard | Canais |
| --- | ---: | ---: | ---: | ---: |
| [`conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column.sv`](../conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column.sv) | 32 | 16 | 8 | Cin=Cout |
| [`conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-rowconst6-trunc-frac6-column.sv`](../conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-rowconst6-trunc-frac6-column.sv) | 18 | 20 | 6 | Cin=Cout |
| [`conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-pretransformed-frac6-column.sv`](../conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-pretransformed-frac6-column.sv) | 18 | 20 | 6 | Cin=Cout |

Simulador: Verilator 5.050, sem waveform. Clock do TB: período de 2 ns. O
tempo de simulação é medido entre a aceitação de `p_start` e `p_end`; não é o
tempo de parede do host. Cada beat de entrada transporta seis amostras e cada
beat de saída quatro. As contagens são beats da interface column, não palavras
por lane nem acessos confirmados a uma macro SRAM física.

## Resultados

Em cada célula `rowconst / pré-transformado`, o primeiro número é comum ao
WPN16 m32 e ao TCN16 `rowconst` m18. O segundo é o TCN16 pré-transformado m18.
As contagens de feature reads e output writes são iguais nas três arquiteturas.

| Canais Cin=Cout | Ciclos | Tempo (µs) | Feature reads | Weight reads | Total input reads | Output reads | Output writes |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 32 | 612.357 / 615.429 | 1.224,714 / 1.230,858 | 278.528 | 3.072 / 6.144 | 281.600 / 284.672 | 330.336 / 333.312 | 262.144 |
| 64 | 2.449.413 / 2.461.701 | 4.898,826 / 4.923,402 | 1.114.112 | 12.288 / 24.576 | 1.126.400 / 1.138.688 | 1.342.656 / 1.354.752 | 1.048.576 |
| 128 | 9.797.637 / 9.846.789 | 19.595,274 / 19.693,578 | 4.456.448 | 49.152 / 98.304 | 4.505.600 / 4.554.752 | 5.413.248 / 5.462.016 | 4.194.304 |
| 256 | 39.190.533 / 39.387.141 | 78.381,066 / 78.774,282 | 17.825.792 | 196.608 / 393.216 | 18.022.400 / 18.219.008 | 21.738.240 / 21.934.080 | 16.777.216 |
| 512 | 156.762.117 / 157.548.549 | 313.524,234 / 315.097,098 | 71.303.168 | 786.432 / 1.572.864 | 72.089.600 / 72.876.032 | 87.123.456 / 87.908.352 | 67.108.864 |

O TCN16 pré-transformado lê duas vezes mais beats de pesos que as outras
variantes. A diferença de ciclos é exatamente igual ao número adicional de
weight-read beats em cada ponto; também há mais leituras de saída. WPN16 m32 e
TCN16 `rowconst` m18 tiveram as mesmas contagens e latências neste workload.

As 15 execuções chegaram a `p_end`, sem timeout. **Não foi verificada a
correção numérica**, intencionalmente. O sinal `ACCESS_COUNT_CAMPAIGN_PASS`
significa somente que os cinco jobs da variante terminaram.

Tempo aproximado de parede do host para compilar e simular cada variante:

| Variante | Build | Simulação |
| --- | ---: | ---: |
| WPN16 m32 | 10,8 s | 178,5 s |
| TCN16 `rowconst` m18 | 11,7 s | 186,5 s |
| TCN16 pré-transformado m18 | 20,2 s | 221,2 s |

## Reprodutibilidade

Exemplo de compilação WPN16; para o TCN16 `rowconst`, troque o RTL e use
`-GNUM_MULT=18 -GNBITS=20 -GHADAMARD_SIZE=6`. O TCN16 pré-transformado usa
também `rtl/conv4x4/mult-matrices/tcn16/mult_matrices.sv`.

```bash
verilator --timing --binary -j 0 \
  --top-module tb_conv4x4_access_count \
  -Wno-fatal -Wno-WIDTH -Wno-CMPCONST \
  --Mdir /tmp/fastconv-access-build \
  -GNUM_MULT=32 -GNBITS=16 -GHADAMARD_SIZE=8 \
  rtl/csa/csa_lib.sv rtl/multip/multip.sv \
  contrib/rtl/pack-def/pack_def.sv \
  rtl/conv4x4/mult-matrices/wpn16/mult_matrices.sv \
  rtl/conv4x4/conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column.sv \
  rtl/conv4x4/testbench_access_count.sv
/tmp/fastconv-access-build/Vtb_conv4x4_access_count
```

Os dados pseudoaleatórios vêm de xorshift32 com sementes determinísticas
distintas por contagem de canais. Todas as cinco configurações de canal são
instanciadas no mesmo TB e avançam em paralelo na simulação.
