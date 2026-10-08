# Tamanho da representação dos pesos por algoritmo

Este relatório compara a quantidade de coeficientes de um filtro no domínio
espacial com a quantidade produzida pela transformada de pesos de cada
algoritmo ativo.

## Comparação por algoritmo

Todos os algoritmos listados usam um filtro espacial 3×3, portanto cada filtro
tem 9 coeficientes espaciais. As versões chamadas 2×2, 3×3 e 4×4 indicam o
tile de saída, não a dimensão do filtro. A transformada pode expandir os 9
coeficientes para uma matriz de dimensão `HADAMARD_SIZE × HADAMARD_SIZE`.

| Algoritmo | Tile de saída | Matriz transformada | Espaciais | Transformados | Diferença | Fator | Aumento |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| TCN4 | 2×2 | 4×4 | 9 | 16 | +7 | 1,78× | +77,8% |
| IFN9 | 3×3 | 6×6 | 9 | 36 | +27 | 4,00× | +300,0% |
| TCN9 | 3×3 | 5×5 | 9 | 25 | +16 | 2,78× | +177,8% |
| TCN16 | 4×4 | 6×6 | 9 | 36 | +27 | 4,00× | +300,0% |
| WPN16 | 4×4 | 8×8 | 9 | 64 | +55 | 7,11× | +611,1% |

Os totais são por filtro, ou seja, por par de canais de entrada e saída. Para
uma camada com `Cin` canais de entrada e `Cout` canais de saída, multiplique as
contagens por `Cin × Cout`.

## Quantidade matemática não é o mesmo que armazenamento no RTL

A coluna “Transformados” descreve o tamanho completo da representação
matemática. Ela não significa que toda variante mantenha simultaneamente todos
esses coeficientes em registradores.

Nas variantes streaming `rowconst`, o RTL guarda os 9 coeficientes espaciais e
calcula as linhas transformadas conforme são necessárias. Assim, a matriz
completa aparece como lógica combinacional/temporária; o banco de pesos dos
MACs mantém somente os coeficientes ativos para o lote atual.

As variantes TCN16 `pretransformed-column` são diferentes: armazenam os 36
coeficientes transformados completos e carregam os pesos ativos para os MACs.
M06, M12 e M18 têm o mesmo banco completo de 36 coeficientes; o número de MACs
altera a quantidade ativa carregada em paralelo, não a dimensão da
transformada.

Portanto, o fator da tabela compara representações por número de coeficientes;
ele não prevê diretamente área, potência ou número total de registradores. A
implementação pode compartilhar operações, calcular linhas sob demanda ou
armazenar a transformada completa.

## Fontes RTL

- [TCN4](../rtl/conv2x2/conv-i24-h13-t08-o4-m04-stream08-prefetch8-rowconst4-trunc-column.sv)
- [IFN9](../rtl/conv3x3/conv-ifn9-i40-h15-t12-o9-m06-stream12-prefetch15-rowconst6-trunc-column.sv)
- [TCN9](../rtl/conv3x3/conv-tcn9-i40-h14-t10-o9-m05-stream10-prefetch15-rowconst5-trunc-column.sv)
- [TCN16 pretransformed](../rtl/conv4x4/conv-tcn16-i60-h15-t12-o16-m06-stream12-prefetch24-pretransformed-column.sv)
- [WPN16](../rtl/conv4x4/conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column.sv)
