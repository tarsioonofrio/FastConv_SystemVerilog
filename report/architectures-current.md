# Arquiteturas de convolução usadas no paper ISCAS 2027

Este guia explica o padrão de datapath e distingue os três baselines 4×4 do
paper. Para uma pessoa que vem do artigo, o [guia de navegação ISCAS](iscas2027/README.md)
é o ponto de entrada mais direto: ele liga cada rótulo do paper a uma fonte
SystemVerilog, configuração ASIC, dataset e resultado.

## Mapa dos baselines do paper

| Rótulo no paper | Fonte representativa | O que muda |
| --- | --- | --- |
| `WPff` | [`WPN16 4×4, 32 MACs`](../rtl/conv4x4/conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column.sv) | Transformada polinomial, 16 bits, pesos espaciais transformados em execução. |
| `TCff` | [`TCN16 rowconst6 + frac6`](../rtl/conv4x4/archive/conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-rowconst6-trunc-frac6-column.sv) | Transformada de pesos Toom-Cook no core; pacote de palavras de 20 bits e parâmetro de transformação `frac6`. A fonte foi arquivada, mas o fluxo ASIC usado no paper continua ativo e completo. |
| `TCpre` | [`TCN16 transformed-frac6`](../rtl/conv4x4/conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-transformed-frac6-column.sv) | Pesos transformados fora do core; pacote de palavras de 20 bits e mesmo parâmetro `frac6`; é o baseline pretransformed selecionado no paper. |
| `IF` | [`IFN9 3×3, 18 MACs`](../rtl/conv3x3/conv-ifn9-i40-h27-t36-o9-m18-stream12-prefetch15-rowconst6-trunc-column.sv) | Família IF, com transformação de pesos em execução, 16 bits. |
| `TCtt` | [`TCN9 3×3, 5 MACs`](../rtl/conv3x3/conv-tcn9-i40-h14-t10-o9-m05-stream10-prefetch15-rowconst5-trunc-column.sv) | Família Toom-Cook 3×3, 16 bits. |
| `TCtw` | [`TCN4 2×2, 8 MACs`](../rtl/conv2x2/conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc-column.sv) | Família Toom-Cook 2×2, 16 bits. |

As linhas acima identificam o ponto selecionado na tabela ASIC, não todas as
variantes existentes. A Tabela de Designs do paper também lista varreduras de
MACs: WPff 8/16/32, TCff e TCpre 6/12/18, IF 6/12/18, TCtt 5 e TCtw 4/8.

## Padrão geral: streaming por colunas com `rowconst`

O padrão de referência mantém os pesos espaciais no core, transforma as linhas
necessárias conforme o escalonamento e compartilha um banco de MACs entre os
produtos Hadamard. Para o exemplo WPN16 4×4, o fluxo de dados é:

```text
colunas de entrada
        ↓
banco do tile 6×6 + prefetch das próximas 4 colunas
        ↓
transformada C das features (8×8)
        ↓
registrador de features transformadas
        ↓
produtos Hadamard em 8 MACs por lote
        ↓
registrador dos produtos
        ↓
inversa incremental por linha + acumulação
        ↓
acumulador do tile de saída 4×4
        ↓
escrita vetorial por coluna
```

Uma transferência de entrada carrega uma coluna com seis palavras; a interface
de saída lê/escreve uma coluna com quatro palavras. Ao avançar o tile, parte das
colunas é reutilizada e as novas são buscadas pelo prefetch. No padrão
`rowconst`, o core não precisa guardar simultaneamente os `K×K` coeficientes
transformados do kernel: calcula a linha necessária e mantém apenas o lote
ativo para os MACs. O pipeline tem fronteiras registradas entre transformação,
Hadamard e inversa; não é uma única cadeia combinacional de ponta a ponta.

## Como ler as tags do RTL

Exemplo: `conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column`.

| Tag | Significado neste padrão | Exemplo |
| --- | --- | ---: |
| `wpn16` | Algoritmo/família matemática indicado pelo RTL e pelo dataset. | — |
| `iNN` | Palavras nominais no armazenamento de entrada: tile de features + prefetch. | `36 + 24 = 60` |
| `hNN` | Contagem nominal do armazenamento de pesos `rowconst`: pesos espaciais + palavras transformadas ativas. | `9 + 32 = 41` |
| `tNN` | Palavras nas fronteiras registradas de dados, aqui features transformadas + produtos Hadamard. | `32 + 32 = 64` |
| `oNN` | Palavras do tile de saída. | `4 × 4 = 16` |
| `mNN` | Número de lanes/MACs paralelos. | `32` |
| `streamNN` | Duas vezes a dimensão da transformada Hadamard nesta família. | `2 × 8 = 16` |
| `prefetchNN` | Palavras antecipadas: quatro colunas novas × seis linhas. | `24` |
| `rowconstNN` | Dimensão da transformada e número de coeficientes calculados por linha. | `8` |
| `trunc` | Transformada de pesos quantizada por truncamento/floor, segundo a escala do algoritmo. | — |
| `column` | Transferência vetorial por coluna, em vez de uma palavra escalar por beat. | `6 in / 4 out` |

Essas tags são uma convenção de nome e não substituem a inspeção do RTL. Em
particular, para `TCpre` o `h27` foi herdado do padrão online e não descreve o
armazenamento físico da arquitetura transformada. Consulte o [relatório de
tamanho das representações de pesos](weight-representation-size.md) ou o RTL
antes de interpretar uma tag como contagem física de registradores.

## Por que o paper tem dois TCN16 4×4

A transformada de kernel TCN16 tem escala 576, que não é potência de dois. A
truncagem simples em 16 bits degrada a precisão; no paper, `TCff` e `TCpre`
usam o mesmo pacote de 20 bits com a configuração de transformação
`WEIGHT_TRANSFORM_FRAC_BITS=6`.
O dataset usado pelos dois é
[`sim-032-3-12-normal-trunc-frac6-nbits20`](../rtl/conv4x4/data/tcn16/sim/sim-032-3-12-normal-trunc-frac6-nbits20/).
Seu `R²` publicado é 0,9985. Assim, a comparação entre `TCff` e `TCpre` isola
principalmente onde a transformação do kernel é executada, e não uma diferença
de precisão.

### `TCff`: transformação do kernel dentro do core

O RTL guarda os pesos espaciais e calcula sob demanda uma linha de seis
coeficientes transformados. O numerador é escalado por `2^6` antes da divisão
por 576, preservando os seis bits fracionários. O ponto do paper usa 18 MACs.
Embora a fonte esteja hoje em `rtl/conv4x4/archive/`, a configuração ativa
[`TCff m18`](../rtl/conv4x4/synthesis/conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-rowconst6-trunc-frac6-column-cin3-cout12/)
aponta para ela em `list-file.txt`; seus artefatos de síntese, simulação SDF e
power são a evidência usada no relatório.

### `TCpre`: transformação do kernel antes da execução

O ponto selecionado é
[`transformed-frac6-column`](../rtl/conv4x4/conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-transformed-frac6-column.sv),
com 18 MACs. Os pesos chegam transformados ao datapath, removendo do core a
lógica da transformação do kernel, mas exigindo armazenamento/tráfego da
representação transformada. Ele usa o mesmo pacote de 20 bits e `frac6` de
`TCff`; não confundir com versões antigas `pretransformed` sem fração que
permanecem arquivadas.

## Leituras seguintes

- [Guia de navegação do paper ISCAS 2027](iscas2027/README.md): tabelas/figuras,
  configurações e evidência por resultado.
- [Tamanho das representações de pesos](weight-representation-size.md):
  quantidade de coeficientes espaciais e transformados e estratégia de
  armazenamento.
- [Qualidade funcional dos datasets](functional-quality.csv): métricas
  calculadas para os datasets referenciados por configurações executadas.
- [README das arquiteturas 4×4](../rtl/conv4x4/README.md): fontes ativas e
  organização dos fluxos.
