# Arquiteturas de convolução em uso

Este relatório descreve o padrão streaming por colunas usado como arquitetura
geral nos algoritmos que não são TCN16 e as duas variantes específicas
atualmente mantidas para TCN16. O arquivo WPN16 abaixo é o exemplo
representativo do padrão geral; cada algoritmo e tamanho de kernel tem seu
próprio RTL gerado com a geometria e a transformada correspondentes.

## Visão geral

| Papel | RTL representativo | Ideia principal |
| --- | --- | --- |
| Padrão geral | [`conv-wpn16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8-trunc-column.sv`](../rtl/conv4x4/conv-wpn16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8-trunc-column.sv) | Mantém pesos espaciais, calcula sob demanda a linha transformada necessária e processa a matriz de Hadamard em lotes usando MACs paralelos. |
| TCN16 com `frac6` | [`conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-rowconst6-trunc-frac6-column.sv`](../rtl/conv4x4/conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-rowconst6-trunc-frac6-column.sv) | Mantém o cálculo da transformada de pesos no RTL, mas conserva seis bits fracionários para reduzir a perda de precisão da divisão por 576. |
| TCN16 pretransformed | [`conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-pretransformed-column.sv`](../rtl/conv4x4/conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-pretransformed-column.sv) | Recebe os 36 pesos já transformados no pacote de dados e os armazena no RTL; remove o cálculo da transformada de pesos durante a execução. |

## Padrão geral: streaming por colunas com pesos `rowconst`

O datapath do exemplo WPN16 segue esta sequência:

```text
colunas de entrada
        ↓
banco do tile 6×6 + prefetch das próximas 4 colunas
        ↓
transformada C das features (8×8)
        ↓
registrador de features transformadas
        ↓
produtos Hadamard em 8 MACs
        ↓
registrador dos produtos
        ↓
inversa incremental por linha + acumulação
        ↓
acumulador do tile de saída 4×4
        ↓
escrita vetorial por coluna
```

Uma transferência de entrada carrega uma coluna com seis palavras, e a interface
de saída lê/escreve uma coluna com quatro palavras. Para avançar ao tile
horizontal seguinte, duas colunas do tile atual são reutilizadas e quatro novas
colunas são buscadas. O banco de prefetch armazena essas quatro colunas antes
que o tile atual termine, reduzindo a espera entre tiles.

Os nove pesos espaciais do filtro são mantidos no core. `WeightTransformRowConst`
implementa as equações de uma linha da transformada com coeficientes constantes;
somente as linhas necessárias ao próximo lote são habilitadas. Assim, o RTL não
precisa manter simultaneamente um banco registrado com os 64 coeficientes
transformados de uma matriz 8×8. A transformada completa continua existindo
matematicamente, mas suas linhas são produzidas conforme o escalonamento dos
MACs.

O pipeline registra as features transformadas antes dos MACs e registra os
produtos Hadamard antes da inversa. A inversa é calculada incrementalmente por
linha, e seus resultados atualizam o acumulador do tile de saída. Esses bancos
de fronteira separam os estágios de transformação, multiplicação e inversa; não
se deve interpretar o streaming como uma única cadeia combinacional de ponta a
ponta.

### Como ler as tags do nome

Para o exemplo
`conv-wpn16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8-trunc-column`:

| Tag | Significado neste padrão | Valor do exemplo |
| --- | --- | ---: |
| `conv` | Módulo controlador de convolução. | — |
| `wpn16` | Algoritmo de Winograd indicado pelo RTL/dataset. | — |
| `iNN` | Palavras nos bancos de entrada: tile de features mais banco de prefetch. | `36 + 24 = 60` |
| `hNN` | Palavras nominais do armazenamento de pesos `rowconst`: pesos espaciais mais pesos transformados ativos para os MACs. | `9 + 8 = 17` |
| `tNN` | Palavras registradas nas duas fronteiras de dados: features transformadas e produtos Hadamard. | `8 + 8 = 16` |
| `oNN` | Palavras do tile de saída. | `4 × 4 = 16` |
| `mNN` | Número de lanes/MACs paralelos. | `8` |
| `streamNN` | `2 × HADAMARD_SIZE`; permanece constante quando se altera o número de MACs dentro da mesma família. | `2 × 8 = 16` |
| `prefetchNN` | Número de palavras antecipadas: colunas novas × altura do tile de entrada. | `4 × 6 = 24` |
| `rowconstNN` | Dimensão de Hadamard e número de coeficientes calculados por linha da transformada de pesos. | `8` |
| `trunc` | Coeficientes transformados são quantizados por truncamento/floor conforme a escala do algoritmo; não implica, por si só, bits fracionários adicionais. | — |
| `column` | Interface de memória vetorial: uma coluna de entrada/saída por transferência, em vez de uma única palavra escalar. | 6 entradas / 4 saídas por beat |

`i`, `h` e `t` são contagens nominais de palavras conforme a convenção do
gerador. Elas não substituem a leitura do RTL: por exemplo, `h` não inclui
vetores combinacionais e não é uma estimativa de área física.

## Por que existem duas variantes específicas de TCN16

TCN16 usa uma transformada de pesos 6×6 cuja escala é 576. Como 576 não é uma
potência de dois, descartar simplesmente o resto da divisão causa erro de
quantização considerável. O relatório de qualidade do dataset sem fração
registra `R² ≈ 0,742`; por isso foram exploradas duas opções com contratos
numéricos e custos de implementação diferentes.

### `rowconst6-trunc-frac6-column`

Esta variante preserva o cálculo da transformada no circuito: guarda os nove
pesos espaciais e calcula cada linha 6-wide quando ela é necessária. Antes da
divisão pela escala 576, o numerador é deslocado seis bits à esquerda; o
resultado é floor-dividido e armazenado com seis bits fracionários adicionais.
O multiplicador usa a escala de quantização ajustada (`QUANT + 6`). Isso
recupera precisão sem guardar previamente a matriz 6×6 completa no pacote como
fonte de pesos do core.

Foi desenvolvida para responder ao problema de qualidade numérica do TCN16
truncado sem fração. No dataset correspondente, `R² ≈ 0,99868`, contra
`R² ≈ 0,74204` no dataset TCN16 truncado sem `frac6`. Essa diferença é de
representação/quantização dos pesos; não é uma comparação isolada de
microarquitetura, pois os pacotes de dados também são diferentes.

### `pretransformed-column`

Esta variante desloca a transformada dos pesos para a geração do pacote. O
RTL lê, em beats vetoriais de seis palavras, os 36 coeficientes já transformados
e floor-truncados de cada filtro 6×6, guarda a matriz completa e carrega dela o
lote de até `NUM_MULT` pesos usado pelos MACs naquele ciclo. A transformada das
features continua ocorrendo no RTL; o que sai do caminho em tempo de execução é
somente o cálculo da transformada dos pesos.

Foi desenvolvida para separar o custo de cálculo/carregamento dos pesos do
datapath ativo e permitir caracterizar a alternativa em que o pré-processamento
é feito fora do core. O trade-off é explícito: não há os seis bits fracionários
da variante anterior, e o RTL passa a armazenar os 36 pesos transformados
completos, além do banco ativo dos MACs. Portanto, `pretransformed` não deve ser
apresentada como substituta de maior precisão da `frac6`; ela é uma alternativa
de organização do cálculo e do armazenamento.

### Tags das duas variantes TCN16

| Tag | `rowconst6-trunc-frac6` | `pretransformed` |
| --- | --- | --- |
| `tcn16` | Algoritmo TCN16; transformada de pesos e features 6×6. | Mesmo algoritmo e mesma geometria. |
| `i60` | 36 palavras do tile de entrada + 24 de prefetch. | Igual. |
| `h27` | 9 pesos espaciais + 18 pesos transformados ativos (`NUM_MULT=18`). | **Tag herdada da convenção da rowconst**: fisicamente há 36 pesos transformados armazenados mais 18 no banco ativo; portanto `h27` não conta todo o armazenamento de pesos desta variante. |
| `t36` | 18 features transformadas + 18 produtos registrados. | Igual. |
| `o16` | Tile de saída 4×4. | Igual. |
| `m18` | 18 MACs; como `HADAMARD_SIZE=6`, processa três linhas Hadamard por ciclo. | Igual. |
| `stream12` | `2 × 6`, conforme a convenção de nomes do gerador. | Igual. |
| `prefetch24` | Quatro novas colunas × seis linhas. | Igual. |
| `rowconst6` | Calcula sob demanda uma linha de seis coeficientes da transformada de pesos. | Não descreve o datapath desta variante; ela usa pesos pretransformados. O sufixo não aparece no nome. |
| `trunc-frac6` | Floor da transformada com seis bits fracionários preservados. | Não se aplica: dataset contém pesos já transformados e truncados sem fração adicional. |
| `pretransformed` | Não se aplica. | Os 36 pesos transformados são fornecidos pelo pacote e registrados no core. |
| `column` | Transferências vetoriais por coluna. | Igual. |

O campo `h27` da variante pretransformed merece atenção ao comparar nomes: ele
continua descrevendo a conta herdada `9 + 18`, mas a implementação não mantém os
nove pesos espaciais; mantém os 36 coeficientes pretransformados e os 18 pesos
ativos dos MACs, totalizando 54 palavras de armazenamento de pesos. Para
comparações de armazenamento, use a estrutura RTL ou o [relatório de tamanho
das representações de pesos](weight-representation-size.md), não apenas a tag
`h`.

## Relatórios e fontes

- [README das arquiteturas 4×4](../rtl/conv4x4/README.md) — variantes ativas e
  localização dos fluxos.
- [Tamanho das representações de pesos](weight-representation-size.md) —
  quantidade matemática de coeficientes espaciais/transformados e estratégia de
  armazenamento.
- [Qualidade dos datasets](functional-quality.csv) — métricas dos datasets
  ativos; a comparação TCN16 `frac6`/sem fração usa pacotes diferentes.
- [Fluxo ASIC TCN16 `frac6`](../rtl/conv4x4/report/tcn16-frac6-mac-sweep.md) e
  [fluxo ASIC TCN16 pretransformed sem fração](../rtl/conv4x4/report/tcn16-pretransformed-nofrac-asic-power-20261008.md) — resultados de campanha, não uma comparação controlada de apenas uma tag.
