# Conv2x2: história da redução de armazenamento

Este documento registra, em ordem executável, as alterações do datapath
streaming e a motivação de cada uma. A finalidade é permitir que cada etapa
seja aplicada e validada isoladamente, sem confundir redução de registradores
com uma mudança funcional no algoritmo Winograd/Toom-Cook.

As referências a `tcn4-*` e `stream4/tcn4-*` nas seções históricas preservam os
nomes usados nas campanhas originais. Na árvore ativa, os sufixos `stream00`,
`stream04` e `stream08` seguem o campo `t**` do nome do RTL. A árvore foi
achatada: cada resultado de síntese fica diretamente em
`synthesis/<nome-do-arquivo-rtl-sem-.sv>/`; experimentos preservados ficam em
`archive/<geracao>/synthesis/`.

Esta revisão acompanha toda a trajetória até os commits `445edc0d` e
`ea8706a3`: primeiro a migração dos modelos ativos para oito MACs, depois a
redução dos bancos de transformação, as experiências de prefetch, as
transformações de pesos em linhas, as tentativas temporal e shared e, por
fim, os bancos sensíveis a nível. O `std` ativo usa oito MACs por padrão. As
fontes m04 e as variantes experimentais retiradas da linha principal continuam
disponíveis em `archive/` para comparação, sem misturar seus resultados com a
linha ativa.

O gerador de relatórios segue a mesma separação: `python3 scripts/report.py`
considera somente `rtl/conv*/synthesis/`; a opção
`python3 scripts/report.py --include-archived` inclui também as campanhas em
`archive/*/synthesis/`. Assim, a ausência de uma variante arquivada no
`merged.csv` padrão é intencional, não perda de dados.

## 0. Visão geral da história: do `std` ao streaming

A forma mais fácil de entender estas arquiteturas é acompanhar a vida dos
dados, e não apenas comparar os nomes dos arquivos. A sequência didática de
redução começa em `archive/m04/conv-i16-h16-t16-o4-m04-std.sv`, a referência
convencional histórica, e segue pela redução dos bancos de dados:

```text
std -> stream08 -> stream04 -> stream00 -> all16 -> stream08-*
```

O caminho `std -> stream08 -> stream04 -> stream00` é a redução progressiva
dos registradores. `all16` aparece depois como referência paralela, não como
mais uma etapa dessa redução. A comparação consolida `stream08` como o melhor
compromisso PPA entre os baselines de 8 MACs, e é essa escolha que motiva os
testes seguintes `stream08-*`. O algoritmo Winograd continua calculando a
mesma combinação de transformada, produtos e inversa; muda quanto tempo cada
valor precisa ficar armazenado e onde fica a fronteira entre lógica e estado.

### 0.0 A cronologia executável da implementação

O ponto de partida desta narrativa é o arquivo
`archive/m04/conv-i16-h16-t16-o4-m04-std.sv`. Ele não é apenas um baseline
histórico: é o molde usado para formular cada experimento. A cada
passo, a pergunta foi a mesma: **qual informação ainda precisa cruzar uma
borda de clock, e qual pode permanecer como fio combinacional?** Os hashes
abaixo funcionam como marcadores de caderno; cada um corresponde a uma
alteração que pode ser reencontrada no Git.

1. **A linguagem dos nomes (`4aecfef7`).** Os nomes `stream00`, `stream04` e
   `stream08` foram alinhados ao campo `t**` do arquivo. Isso separou a
   quantidade de MACs (`m04`, `m08`) da quantidade de palavras agendadas por
   ciclo e tornou comparações entre gerações legíveis.
2. **O genérico deixa de prometer dois MACs (`04848aa3`).** A variante genérica
   `stream08` passou a aceitar somente os contratos de quatro e oito MACs. A
   FSM deixou de carregar um caso histórico que não fazia parte da linha de
   desenvolvimento.
3. **A migração para m08 (`bd4ff8ae`, `45b95289`).** Foram criados os fontes
   de oito MACs, suas configurações de síntese e o primeiro registro do fluxo
   de power no Paxos. A matemática permaneceu a mesma; o paralelismo mudou de
   quatro para oito produtos por passo.
4. **O m04 vira referência (`f23130ae`, `1c0a6b3d`).** Os modelos de quatro
   MACs foram movidos para `archive/m04/` e seus resultados foram regenerados
   como história. Assim, a árvore ativa passou a responder à pergunta sobre o
   projeto atual, enquanto os m04 preservaram a evidência da redução de ciclos.
5. **O fluxo remoto fica repetível (`8ca92ef8`, `b4a619f9`).** Os scripts
   passaram a inicializar corretamente os módulos Cadence e as campanhas
   pendentes de logical, gate-level e power foram concluídas. A partir daqui,
   cada redução de armazenamento passou a ser acompanhada por uma medição
   comparável de área, tempo e potência.
6. **O primeiro prefetch (`cbf923a2`, `96d9ed0b`, `a2f33948`, `28a8f419`).** O
   banco de prefetch passou a ser liberado no momento certo, os resultados
   foram registrados e a leitura da próxima coluna foi sobreposta ao uso do
   tile atual. O custo foi estado extra na entrada; o objetivo foi esconder a
   latência da memória sem alterar o número de janelas produzidas.
7. **Pesos em linhas constantes (`5d7abd4c`, `92fa4049`, `72784b2a`).** A
   variante `rowconst4` deixou de manter dezesseis pesos transformados. Ela
   guarda os nove pesos espaciais e apenas as linhas transformadas que estão
   em voo. O transformador de pesos ganhou seleção de linha e o fluxo de power
   passou a medir esse deslocamento de armazenamento para lógica.
8. **A experiência shared (`88d801a8`, `9b62205c`, `9b4fa904`).** Duas linhas
   de pesos passaram a compartilhar somas do transformador. A ideia reduziu
   hardware duplicado, mas introduziu uma dependência temporal adicional; por
   isso a variante original foi preservada antes de qualquer substituição.
9. **A experiência temporal (`2d58c7d9`, `87f7f4db`, `a8b5dfab`).** O shared
   foi substituído por uma captura temporal: um transformador de linha e um
   cache registram as quatro linhas nos instantes em que a FSM já está parada
   para usá-las. O número de ciclos foi mantido, mas a área e a potência
   mostraram que economizar instâncias combinacionais pode custar mais estado.
10. **Coeficientes selecionados antes da aritmética (`92976cc7`, `592df08b`).**
    A escolha dos coeficientes da linha passou a acontecer antes da soma. Isso
    tornou explícita a diferença entre guardar o peso transformado completo e
    guardar somente a linha ativa, e os reports registraram a campanha antes de
    ela ser arquivada.
11. **O arquivo histórico é separado da linha ativa (`6a1f7795`, `f5a793dc`).**
    As variantes exact e temporal foram movidas para `archive/m08/`; a
    documentação passou a distinguir fonte ativa, experimento histórico e
    resultado de síntese. O coletor de reports ganhou a regra de excluir
    `archive/` por padrão e incluí-lo apenas com `--include-archived`.
12. **Latches nos bancos independentes (`1566d9a2`, `75da237e`, `9ae63cf7`,
    `dd3c0ae9`, `43d264ad`, `8c0113d1`).** O prefetch de entrada, o banco de
    pesos espaciais e a leitura da saída foram convertidos experimentalmente
    para `always_latch`, mantendo FSMs, contadores e realimentações em
    `always_ff`. O fluxo foi ajustado para aceitar latches intencionais e os
    resultados de área/power foram medidos sem mudar o contrato funcional.
13. **Um único banco de features (`4d2a79f4`, `d760df5c`).** A cópia
    `r_input_feat_stage` foi removida. O banco único reduziu armazenamento, mas
    revelou no gate-level uma corrida de transparência na entrada de
    `CONV_INPUT`.
14. **Captura na borda e fechamento (`a60ac009`, `797badab`).** Somente
    `r_input_feat` passou a ser capturado na borda do clock; os latches
    independentes foram preservados. A simulação gate-level no Paxos terminou
    sem divergências, e o power foi medido sobre a netlist corrigida.
15. **O experimento deixa de ser ativo (`ea8706a3`, `445edc0d`).** O exact
    `h20` e o latch-bank `h13` foram movidos para `archive/m08/`, seus
    `list-file.txt` foram corrigidos para os novos caminhos e os reports ativos
    foram regenerados. Nada foi apagado: a mudança apenas tornou explícita a
    fronteira entre a implementação corrente e a história experimental.

Essa ordem é importante. O prefetch não nasceu com os latches; os latches não
nasceram com o banco único; e o banco único não foi aceito antes de passar pela
simulação anotada. Em cada capítulo abaixo, o código aparece como a prova
executável da decisão narrativa.

### 0.1 O ponto de partida: `std`

O `std` histórico arquivado era parametrizado para quatro MACs e registra a
matriz transformada inteira em `r_conv_temp[0:15]`. O `std` ativo usa oito MACs,
mas preserva essa mesma fronteira convencional. Ele também conserva
`r_conv_input[0:15]` como fronteira da entrada da convolução. O caminho de
dados tem, portanto, os seguintes bancos de 20 bits:

```text
r_input_feat[16]       janela 4x4
r_input_weight[16]     pesos transformados
r_conv_temp[16]        transformada inteira registrada
r_conv_input[16]       entrada capturada para a convolução
r_output_write[4]      tile que será escrito
r_output_read[4]       contribuição anterior de canais
                                      total: 72 palavras de dados
```

O `std` é simples de raciocinar porque cada etapa possui uma fronteira clara:

```text
r_input_feat -> Transform -> r_conv_temp -> r_conv_input -> Multip[0:7] -> Inverse -> output
```

O preço dessa clareza é manter 16 valores transformados mesmo quando somente
oito produtos estão sendo calculados por ciclo.

### 0.2 Primeira redução: `stream08`

O `stream08` conserva duas linhas de quatro valores: uma para a transformada e outra para a inversa.
A matriz `w_conv_transform[0:15]` continua sendo calculada
combinacionalmente; `r_transform_row[0:3]` guarda a faixa que será usada no
ciclo seguinte, enquanto a segunda faixa permanece no caminho combinacional.
A inversa passa a ser consumida por linhas:

```text
std:      16 input + 16 weights + 16 temp      + 16 conv_input + 8 output = 72
stream08: 16 input + 16 weights +  4 transform + 4 inverse     + 8 output = 48
```

O ganho de 24 palavras vem da remoção de `r_conv_temp[16]` e
`r_conv_input[16]`, além da substituição da matriz de resultado pela inversa
incremental. O acumulado dos quatro pixels fica no banco de saída.

### 0.3 Segunda redução: `stream04`

No `conv-i16-h16-t04-o4-m08-stream04.sv`, a linha transformada continua
registrada, mas `r_inverse_row[0:3]` deixa de ser necessário. O produto atual
entra diretamente em `InverseRow`; somente o acumulado entre linhas atravessa o
clock em `r_output_write[0:3]`:

```text
std:      16 input + 16 weights + 16 temp      + 16 conv_input + 8 output = 72
stream08: 16 input + 16 weights + 4 transform  + 4 inverse     + 8 output = 48
stream04: 16 input + 16 weights + 4 transform                  + 8 output = 44
```

O sufixo `stream04` segue a fronteira `t04` do RTL e não a quantidade de MACs:
o arquivo documentado aqui usa oito MACs. As quatro palavras da linha
transformada continuam sendo a fronteira temporal; os oito produtos são
calculados em duas linhas de Hadamard por ciclo.

### 0.4 Terceira redução: `stream00`

No `conv-i16-h16-t00-o4-m08-stream00.sv`, o banco
`r_transform_row[0:3]` também é removido. O índice
`r_transform_product_idx` seleciona diretamente quatro elementos de
`w_conv_transform`. A memória economizada na transformada reaparece como
`r_output_accumulator[0:3]`, necessário para manter a soma parcial da inversa.
Na variante ativa `conv-i16-h16-t00-o4-m08-stream00.sv`, esse banco é eliminado e
`r_output_write[0:3]` assume as duas funções:

```text
std:          16 input + 16 weights + 16 temp      + 16 conv_input + 8 output = 72
stream08:     16 input + 16 weights + 4 transform  + 4 inverse     + 8 output = 48
stream04:     16 input + 16 weights + 4 transform                  + 8 output = 44
stream00-m08: 16 input + 16 weights                                + 8 output = 40
```

No m08 ativo, o banco de escrita é reutilizado como acumulador porque a FSM
não escreve a memória externa durante HADAMARD. O benefício nominal é de
quatro palavras (80 bits em `NBITS=20`). A síntese histórica do m04 mostrou,
porém, que Genus já havia eliminado a redundância equivalente: células e área
permaneceram iguais, enquanto a potência caiu ligeiramente. Esse resultado
fica preservado no Anexo A, sem misturar a linha de base arquivada com o fluxo
ativo.

### 0.5 Referência paralela: `all` com 16 MACs

Depois de acompanhar a redução serial `std -> stream08 -> stream04 -> stream00`,
o `all` serve como comparação paralela. O arquivo
`conv-i16-h16-t00-o4-m16-all.sv` pergunta se podemos trocar ciclos por
paralelismo: a transformada e a inversa passam a ser fios combinacionais, e os
16 produtos são calculados no mesmo ciclo. Para isso, `r_conv_temp[16]` deixa
de existir, mas a arquitetura ainda conserva `r_conv_input[16]`. A inversa é
capturada diretamente no banco de saída, sem uma cópia intermediária:

```text
std:   16 input + 16 weights + 16 temp + 16 conv_input + 8 output = 72
all:   16 input + 16 weights           + 16 conv_input + 8 output = 56
```

O `all` reduz 16 palavras em relação ao `std`, mas aumenta de 4 para 16 MACs.
Ele ilustra outra troca: menos ciclos de cálculo em troca de paralelismo e de
uma área maior que a de `stream08`. Por isso, fica depois das variantes de
redução como referência, e não como degrau intermediário da família streaming.

### 0.6 Consolidação de `stream08` e início dos testes `stream08-*`

Entre os baselines de oito MACs, `stream08` é o melhor compromisso entre
armazenamento, área e potência: usa 48 palavras, contra 44 em `stream04` e 40
em `stream00`, mas obteve a menor área (15.660,389 um2) e a menor potência
(0,664592 mW) desse grupo. Não é o vencedor em latência: seus 25.699 ciclos
superam os 23.675 de `stream04` e `stream00`. A escolha de `stream08` como base
dos testes seguintes, portanto, privilegia o compromisso PPA, não a menor
latência nem a menor contagem isolada de registradores. O `all` também teve
potência ligeiramente menor, mas usa 16 MACs e área substancialmente maior.

Com essa referência consolidada, a próxima pergunta foi aplicada aos pesos.
As variantes `stream08-wstream4` e `stream08-rowconst4` deixam de registrar
16 pesos transformados e passam a guardar nove pesos espaciais mais oito
pesos transformados ativos:

```text
stream08:       h16                      + t08
stream08-* row: h09 espacial + h08 ativo + t08
```

O total de dados passa de 48 para 49 palavras no m08, mas parte do trabalho migrado
para os registradores aparece como lógica combinacional de transformação de
peso. O `rowconst4-exact` mantém a mesma quantidade de palavras, mas usa
larguras maiores e elimina arredondamentos intermediários. Já o
`stream08-prefetch4` faz a troca oposta: adiciona quatro palavras para manter a
próxima coluna viva e permitir sobreposição entre leitura e processamento.

Assim, a história completa não é simplesmente "cada arquivo tem menos
registradores". A redução principal e a decisão de onde continuar estão
resumidas assim:

```text
std       guarda etapas completas e tem 72 palavras
stream08  serializa produtos e inversa e fica com 48
stream04   elimina a linha de inversa e fica com 44
stream00   remove a fronteira extra e reutiliza r_output_write, ficando com 40
all16     remove a temp, mas paraleliza tudo e fica com 56
decisão   consolida stream08 como base de melhor compromisso PPA entre os baselines m08
rowconst  reduz pesos transformados, chegando a 49
prefetch  adiciona estado de entrada para ganhar overlap, chegando a 52
```

Essa seção encerra a visão geral da trajetória. Depois do escopo e do contrato
da seção 1, o documento se divide em duas leituras complementares. Primeiro,
**Alterações em ordem lógica** organiza as arquiteturas pela sequência didática
`std -> stream08 -> stream04 -> stream00 -> all -> stream08-*`. No final,
**Alterações em ordem cronológica** preserva o diário de implementação, os
ajustes do fluxo e as campanhas na ordem em que ocorreram.

## 1. Escopo e contrato congelado

O diretório implementa F(2x2, 3x3), com matriz Hadamard 4x4 e 16 produtos.
Os fontes ativos de referência usam oito MACs; os equivalentes m04 foram
preservados em `archive/m04/` para não apagar a linha de base histórica.

| Arquivo                                                                | Estado                       | MACs por ciclo | Linhas inversas consumidas por ciclo |
| ---------------------------------------------------------------------- | ---------------------------- | -------------: | -----------------------------------: |
| `conv-i16-h16-t16-o4-m08-std.sv`                                       | ativo e padrão (`make std`)  |              8 |                                    2 |
| `conv-i16-h16-t08-o4-m08-stream08.sv`                                  | ativo                        |              8 |                                    2 |
| `conv-i16-h16-t04-o4-m08-stream04.sv`                                  | ativo                        |              8 |                                    2 |
| `conv-i16-h16-t00-o4-m08-stream00.sv`                                  | ativo, variação `stream08`   |              8 |                                    2 |
| `conv-i16-h16-t00-o4-m16-all.sv`                                       | ativo de referência paralela |             16 |                                    4 |
| `conv-i16-h13-t08-o4-m08-stream08-wstream4.sv`                         | ativo                        |              8 |                                    2 |
| `conv-i16-h13-t08-o4-m08-stream08-rowconst4.sv`                        | ativo                        |              8 |                                    2 |
| `conv-i20-h16-t08-o4-m08-stream08-prefetch4.sv`                        | ativo                        |              8 |                                    2 |
| `conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4.sv`              | ativo                        |              8 |                                    2 |
| `conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4-latch-single.sv` | ativo experimental           |              8 |                                    2 |

O contrato funcional que não pode mudar durante a redução é:

1. a FSM de entrada continua produzindo a mesma janela e os mesmos pesos;
2. `Transform` continua calculando a mesma matriz transformada;
3. cada produto continua associado ao peso correspondente;
4. `InverseRowAccumulate` continua recebendo as linhas na mesma ordem;
5. o estado acumulado continua disponível em `r_output_write` antes do ciclo seguinte;
6. a FSM de saída continua escrevendo os mesmos 8100 valores nos mesmos
   endereços;
7. o caminho de referência `rtl/conv2x2` permanece intocado.

O pacote usado na validação RTL é
`../conv2x2/data/tcn4/sim/sim-032-3-3-normal/pack_data.sv`, com os parâmetros
de `../conv2x2/pack-param/tcn4/pack_param.sv`.

## Alterações em ordem lógica

Esta parte explica a arquitetura pela vida dos dados: começa no `std`, percorre
as reduções `stream08`, `stream04` e `stream00`, apresenta `all` como referência
paralela e termina com os experimentos `stream08-*`. A ordem é conceitual, não
uma cronologia dos commits. O bloco cronológico no final preserva essa
cronologia e os relatórios das campanhas.

### 1. Ponto de partida: `std` e redução dos registradores

Encerrada a visão geral e definido o contrato, começamos pelo `std`: seus
bancos estabelecem a referência para entender as reduções seguintes. Esta
subseção também define o que significa contar armazenamento no RTL. Depois, a
leitura percorre `stream08 -> stream04 -> stream00 -> all` e termina nos
experimentos `stream08-*`. A sequência é arquitetural, não a data dos commits.

Aqui a pergunta é: quais palavras precisam sobreviver a cada borda de clock em
cada arquitetura?

Não é uma tabela de PPA: a comparação de PPA fica no bloco cronológico. Esta
parte compara o fluxo e o armazenamento dos dados no RTL. As contagens de
palavras ajudam a explicar a arquitetura, mas não substituem flip-flops e área
medidos na síntese.

Os exemplos detalhados das reduções `stream08`, `stream04` e `stream00` apontam
para fontes históricas m04 e ilustram a vida dos bancos de dados. A visão geral
e o inventário de fontes ativos identificam as variantes m08 atuais.

Uma palavra é um elemento de um vetor como `r_input_feat[0]`. Para o caso
TC2x2 usado nesta pasta, a maior parte das palavras tem `NBITS=20` bits. Um
vetor de 4 elementos, portanto, representa 4 palavras ou 80 bits de estado.

Há três categorias diferentes no RTL:

1. **Estado de dados:** valores de feature, pesos, produtos parciais e saídas.
2. **Estado de controle:** FSMs, contadores, índices e endereços. Eles também
   são flip-flops, mas não aparecem nos campos `i`, `h`, `t` e `o` do nome.
3. **Fios combinacionais:** sinais `w_*`, módulos `Transform`, `InverseRow`,
   `Multip` e muxes. Eles podem consumir área e timing, mas não mantêm um valor
   entre ciclos e, por isso, não são registradores.

O nome do arquivo resume apenas os bancos de dados principais:

| Campo | Significado neste documento                       | Exemplo                                               |
| ----- | ------------------------------------------------- | ----------------------------------------------------- |
| `i`   | palavras no banco da janela de entrada            | `r_input_feat[0:15]` = `i16`                          |
| `h`   | palavras registradas dos pesos ativos             | `r_input_weight[0:15]` = `h16`                        |
| `t`   | palavras registradas para transformada/inversa    | `r_transform_row[0:3]` + `r_inverse_row[0:3]` = `t08` |
| `o`   | palavras no banco de saída do tile                | `r_output_write[0:3]` = `o4`                          |
| `m`   | multiplicadores físicos ativos por ciclo Hadamard | `m04`, `m16`                                          |

Essa convenção não substitui a leitura do RTL. Por exemplo, `r_conv_input`,
`r_output_accumulator`, `r_output_read` e um banco de prefetch são
registradores reais, mas não estão todos codificados nos cinco
campos do nome. Por isso as tabelas seguintes mostram também um inventário
integral de palavras de dados.

#### 1.1 O que significa reduzir registradores

Para uma matriz Hadamard 4x4 existem 16 valores transformados. A arquitetura
ingênua pode registrar esses 16 valores e depois registrar uma matriz inteira de
produtos ou resultados intermediários. A arquitetura streaming faz uma pergunta
mais econômica:

> Qual é o menor trecho do resultado que precisa permanecer vivo quando o
> próximo ciclo chega?

A resposta muda conforme a fronteira sequencial escolhida:

```text
tile de entrada -- Transform combinacional -- produtos -- inversa por linha
      |                    |                     |              |
   r_input_feat       w_conv_transform       w_conv_product   parcial
      16 palavras         16 fios              m palavras     acumulado
```

No caminho all16, todos os 16 produtos são calculados juntos. No caminho
streaming, somente uma linha ou um grupo de `m` produtos atravessa a fronteira
de clock. A economia vem de não guardar simultaneamente aquilo que pode ser
recalculado ou consumido no mesmo ciclo.

### 2. Primeira redução: `stream08`

Arquivo ativo: `conv-i16-h16-t08-o4-m08-stream08.sv`.

O `stream08` mantém a janela e os pesos completos, mas percorre os 16 produtos
em dois ciclos de oito MACs. A matriz transformada continua existindo como
`w_conv_transform[0:15]`: quatro operandos são capturados em
`r_transform_row`, enquanto os outros quatro são selecionados diretamente da
matriz em cada ciclo. A inversa também é consumida por linha.

#### 2.1 Bancos registrados

| Banco                       | Palavras | O que atravessa o clock                                    |
| --------------------------- | -------: | ---------------------------------------------------------- |
| `r_input_feat[0:15]`        |       16 | Tile 4x4 em processamento                                  |
| `r_input_weight[0:15]`      |       16 | Os 16 pesos, rotacionados em grupos de 8                   |
| `r_transform_row[0:3]`      |        4 | Grupo da transformada consumido pelo próximo ciclo         |
| `r_inverse_row[0:3]`        |        4 | Última linha de produtos mantida para o trace              |
| `r_output_write[0:3]`       |        4 | Acumulador parcial do tile de saída                        |
| `r_output_read[0:3]`        |        4 | Contribuição de canais anteriores                          |
| **total integral de dados** |   **48** | Inclui os dois bancos de interface de saída                |

Na convenção do nome, `i16 + h16 + t08 + o4` soma 44 palavras porque `o4`
conta somente o banco de escrita. A contagem integral acrescenta as quatro
palavras de `r_output_read` e chega a 48.

#### 2.2 Mudanças de sinais, módulos e controle: `std` -> `stream08`

Depois da redução dos bancos descrita em 2.1, comparamos agora os outros
elementos da implementação. A referência é o `std` ativo de oito MACs, para
isolar as mudanças de microarquitetura sem misturá-las com uma mudança na
quantidade de multiplicadores.

| Aspecto | `std` | `stream08` | Efeito |
| ------- | ----- | ---------- | ------ |
| Caminho dos operandos | `r_conv_temp[0:7]` alimenta diretamente os oito `Multip`. | `r_transform_row` e `w_transform_feature` alimentam os oito `Multip`, combinando valores registrados e seleções diretas de `w_conv_transform`. | Os produtos deixam de consumir o FIFO completo e passam a consumir grupos da transformada em fluxo. |
| Sinais de seleção legados | `MuxMult8`, `r_conv_idx_in` e `r_conv_idx_out` aparecem no RTL, mas as saídas do mux não têm consumidores no caminho funcional desta fonte. | Esses sinais e a instância `MuxMult8` não aparecem. | É uma remoção de estrutura sem uso funcional no `std`; não deve ser contada como ganho de datapath por si só. |
| Retenção da janela | `TRANSFER` desloca a janela antes de `HOLD_WRITE`. | `r_stream_transfer_pending` guarda o pedido; `w_conv_input_release` autoriza o deslocamento. | A janela atual permanece estável até o datapath terminar de consumi-la. |
| Sinais da inversa | `w_conv_inverse` recebe a saída matricial de `Inverse`. | `w_inverse_product_row*` alimentam as operações por linha; `w_output_acc_after_lane0` e `w_output_acc_next` encadeiam as somas. | A inversa matricial é substituída por cálculo incremental e acumulação por linha. |
| Controle do fluxo | `r_conv_multiply_count` encerra a sequência HADAMARD; `r_conv_idx_in/out` pertencem ao caminho `MuxMult8` sem efeito funcional. | `r_conv_multiply_count` encerra a sequência, enquanto `r_transform_product_idx` e `r_inverse_row_idx` acompanham grupo e linha. | O contador de ciclos permanece; os novos índices representam o avanço explícito do fluxo por linhas. |

Os módulos `Transform` e os oito `Multip` permanecem. No `std`, os
multiplicadores são descritos por um `generate`; no `stream08`, são instâncias
explícitas ligadas aos operandos selecionados. A instância `MuxMult8` presente
no `std` não participa do caminho funcional, pois suas saídas não são
consumidas; o `stream08` não a declara. Já o módulo funcional `Inverse` é
substituído por duas instâncias funcionais de `InverseRow` — uma para cada
grupo de quatro produtos — e duas de `InverseRowAccumulate` para combinar as
linhas processadas no mesmo ciclo. Há ainda uma instância de `InverseRow`
alimentada por `r_inverse_row`, usada apenas pelo trace `STREAM_DEBUG`.

Os índices `r_transform_product_idx` e `r_inverse_row_idx` são registradores de
controle, não palavras dos bancos de dados contados em 2.1. Eles tornam visível
o progresso do fluxo e não devem ser confundidos com os registradores de dados
que motivaram a redução.

As três FSMs preservam os mesmos estados enumerados: 11 na entrada, quatro na
convolução (`WAIT_CONV`, `TRANSFORM`, `HADAMARD`, `INVERSE`) e seis na saída.
Portanto, esta transição não reduz a quantidade de estados. A diferença está
nas condições de avanço: `HOLD_WRITE` só libera a leitura/deslocamento seguinte
quando `w_conv_input_release` e a condição de escrita estão satisfeitos. O
controle faz a janela esperar pelo consumo da transformada sem acrescentar um
novo estado à FSM.

#### 2.3 O ciclo a ciclo

```text
TRANSFORM:    r_transform_row <- w_conv_transform[0:3], índice <- 0
HADAMARD 0:   usa [0:3] registrados e [4:7] selecionados diretamente -> 8 produtos
borda:        r_transform_row <- w_conv_transform[8:11], índice <- 8
HADAMARD 1:   usa [8:11] registrados e [12:15] selecionados diretamente -> 8 produtos
```

Em cada borda, `r_output_write` recebe o novo acumulado da inversa. O valor
anterior não precisa de uma matriz 4x4: quatro acumuladores de saída são
suficientes para os quatro pixels do tile.

O `r_inverse_row` desta variante é uma fronteira adicional que não participa
do resultado final quando `STREAM_DEBUG` está desligado; ele existe por causa
do caminho legado de trace. Por isso a contagem textual desta fonte não é ainda
o limite mínimo de armazenamento da família `stream08`.

#### 2.4 Comparação PPA: `std` -> `stream08`

A comparação usa as variantes m08, ambas com oito MACs, aprovadas na mesma
campanha gate-level e avaliadas com o mesmo workload. Assim, os deltas mostram
o efeito observado da mudança de arquitetura sem misturar quantidades de MACs.

| Métrica | `std` m08 | `stream08` m08 | Diferença (`stream08` - `std`) |
| ------- | --------: | -------------: | -----------------------------: |
| Células reportadas | 8.874 | 10.254 | +1.380 (+15,5%) |
| Área total (um2) | 15.675,268 | 15.660,389 | -14,879 (-0,095%) |
| Ciclos do workload | 23.675 | 25.699 | +2.024 (+8,5%) |
| Power (mW) | 0,863333 | 0,664592 | -0,198741 (-23,0%) |
| Energia (nJ) | 204,416 | 170,810 | -33,606 (-16,4%) |

Neste resultado, `stream08` reduz power e energia, mas aumenta o número de
células reportadas e leva mais ciclos. A área total fica praticamente igual à
do `std`; portanto, a redução de registradores não se converteu aqui numa
redução material de área. Os resultados são da campanha gate-level reportada
na comparação cronológica geral; não devem ser confundidos com a contagem
nominal de palavras de dados da subseção 2.1.

### 3. Segunda redução: `stream04`

Arquivo: `conv-i16-h16-t04-o4-m04-stream04.sv`.

O sufixo `stream04` identifica a fronteira `t04`; esta fonte fixa tem quatro
MACs. Somente uma linha de quatro valores da
transformada é registrada. A linha da inversa não é armazenada; o produto do
ciclo atual entra diretamente em `InverseRow` e depois em `InverseRowAccumulate`.

#### 3.1 Bancos registrados

| Banco                       | Palavras |
| --------------------------- | -------: |
| `r_input_feat[0:15]`        |       16 |
| `r_input_weight[0:15]`      |       16 |
| `r_transform_row[0:3]`      |        4 |
| `r_output_write[0:3]`       |        4 |
| `r_output_read[0:3]`        |        4 |
| **total integral de dados** |   **44** |

Em comparação direta com o `stream08`, saem as quatro palavras de
`r_inverse_row`. A acumulação funcional não desaparece: ela continua em
`r_output_write`, que passa a exercer simultaneamente o papel de banco de
saída do tile e de estado parcial entre linhas.

#### 3.2 Por que isso reduz estado sem mudar a matemática

`InverseRow` e um bloco combinacional. Ele recebe o vetor de produtos do ciclo,
calcula os quatro valores parciais da inversa e entrega o resultado ao
`InverseRowAccumulate`. Como o acumulador já está registrado em
`r_output_write`, guardar novamente a linha de produtos em `r_inverse_row` seria
duplicar uma informação que já foi consumida.

O fluxo fica:

```text
r_transform_row -> Multip[0:3] -> InverseRow -> Accumulate -> r_output_write
```

Essa é a primeira redução que remove um banco inteiro sem aumentar o número de
produtos. O preco e uma dependencia combinacional mais direta entre MAC,
inversa e acumulador.

### 4. Terceira redução: `stream00`

Arquivo: `conv-i16-h16-t00-o4-m04-stream00.sv`.

Aqui a fronteira `r_transform_row` também foi removida. `Transform` continua
produzindo os 16 valores, mas eles permanecem em `w_conv_transform`; o índice
`r_transform_product_idx` seleciona diretamente os quatro valores que alimentam
os MACs no ciclo corrente.

#### 4.1 Bancos registrados

| Banco                       | Palavras | Motivo                                                   |
| --------------------------- | -------: | -------------------------------------------------------- |
| `r_input_feat[0:15]`        |       16 | Mantem o tile de entrada                                 |
| `r_input_weight[0:15]`      |       16 | Mantem e rotaciona os pesos                              |
| `r_output_write[0:3]`       |        4 | Acumula a inversa e depois fornece o tile à FSM de saída |
| `r_output_read[0:3]`        |        4 | Mantém a contribuição anterior                           |
| **total integral de dados** |   **40** |

O `t00` agora faz sentido para a transformada: não existe banco registrado de
transformada nem de linha inversa. A acumulação também não exige um banco
adicional: `r_output_write` é zerado no início da janela e recebe
`w_output_acc_next` em cada ciclo HADAMARD.

Por isso `stream00` m04 e m08 possuem a mesma fronteira de armazenamento:

```text
stream00-m04: 16 input + 16 weights + 4 output-write + 4 output-read = 40
stream00-m08: 16 input + 16 weights + 4 output-write + 4 output-read = 40
```

A diferença entre m04 e m08 é temporal: m04 consome uma linha da inversa por
ciclo e precisa de quatro ciclos HADAMARD; m08 consome duas linhas e precisa de
dois ciclos. O banco registrado é o mesmo.

#### 4.2 Implementação comum do banco compartilhado

O arquivo `conv-i16-h16-t00-o4-m08-stream00.sv` usa dois grupos de quatro MACs
por ciclo e, por isso, produz duas linhas da inversa de uma vez. O arquivo m04
usa um grupo, mas segue a mesma politica: `r_output_accumulator` foi removido
e o valor anterior entra diretamente em `InverseRowAccumulate` por meio de
`r_output_write`, que recebe o novo acumulado no mesmo processo sequencial do
datapath.

O último resultado já fica em `r_output_write` quando `w_conv_end` sinaliza o
fim da convolução. A FSM de saída apenas consome esse banco, somando
`r_output_read` quando necessário. Não há cópia final nem ciclo adicional:

```text
HADAMARD:      r_output_write <= w_output_acc_next
fim HADAMARD:  w_conv_end <= 1
WRITE_OUTPUT:  p_output_data_write <- r_output_write + r_output_read
```

### 5. Referência paralela: `all` com 16 MACs

Arquivo: `conv-i16-h16-t00-o4-m16-all.sv`.

Depois da sequência de redução `std -> stream08 -> stream04 -> stream00`, o
`all` permite comparar esse caminho com uma arquitetura paralela. Esta é uma
boa referência para entender o que o streaming remove: ela faz a transformada,
os produtos e a inversa de forma paralela. O nome `t00` significa apenas que
não há um banco dedicado chamado `r_transform_row` ou `r_inverse_row`; não
significa que o datapath não tenha registradores intermediários.

#### 5.1 Bancos de dados do `all`

| Banco                  | Palavras | Papel durante a janela                                       |
| ---------------------- | -------: | ------------------------------------------------------------ |
| `r_input_feat[0:15]`   |       16 | Mantém a janela 4x4 lida da feature map                      |
| `r_input_weight[0:15]` |       16 | Mantém todos os pesos transformados                          |
| `r_conv_input[0:15]`   |       16 | Captura a entrada da convolução antes do caminho de produtos |
| `r_output_write[0:3]`  |        4 | Mantém os quatro valores que serão escritos                  |
| `r_output_read[0:3]`   |        4 | Mantém a contribuição anterior de outro canal                |
| **total de dados**     |   **56** | Soma dos bancos acima                                        |

Os 56 valores são uma contagem de armazenamento de dados, não uma contagem de
flip-flops sintetizados. Ainda existem registradores escalares de endereço,
contagem de janela, canais, FSM e controle de leitura/escrita.

#### 5.2 Sequência de vida dos dados

1. A FSM de entrada preenche `r_input_feat` com a janela 4x4.
2. A FSM de pesos preenche `r_input_weight` com 16 pesos.
3. `Transform` calcula `w_conv_transform[0:15]`. Esse vetor é `w_*`: é um fio,
   não um banco registrado.
4. Os 16 `Multip` calculam `w_conv_product[0:15]` no mesmo ciclo.
5. `Inverse` calcula `w_conv_inverse[0:3]`, também combinacionalmente.
6. `r_output_write` captura diretamente `w_conv_inverse` no mesmo ciclo em que
   `st_input_current == CONV_INPUT`; não existe uma cópia intermediária.
7. `r_output_read` guarda a contribuição anterior que será somada pelo banco
   de saída.

O `all` troca tempo por largura: mantém mais fronteiras de dados, mas termina
uma janela Hadamard em um único ciclo. Em comparação com `std`, elimina o banco
da transformada registrada e captura a inversa diretamente na saída. Em
comparação com `stream08`, usa mais palavras e 16 MACs para processar todos os
produtos no mesmo ciclo.

### 6. Variantes `stream08-*`: reduzir pesos sem guardar 16 pesos transformados

Depois de comparar as arquiteturas de feature, a próxima linha de trabalho foi
aplicar a mesma ideia aos pesos. A pergunta passou a ser:

> Precisamos manter os 16 pesos transformados, ou podemos manter os 9 pesos
> espaciais e gerar somente a linha que os MACs usam?

Essa mudança não reduz o banco de entrada: `r_input_feat[0:15]` continua
necessário. Ela reduz ou reorganiza somente o lado dos pesos.

#### 6.1 `stream08-wstream4`

Arquivo ativo: `conv-i16-h13-t08-o4-m08-stream08-wstream4.sv`.

| Banco                                        | Palavras |
| -------------------------------------------- | -------: |
| `r_input_feat[0:15]`                         |       16 |
| `r_weight_spatial[0:8]`                      |        9 |
| `r_input_weight[0:7]`                        |        8 |
| `r_transform_row[0:3]`                       |        4 |
| `r_inverse_row[0:3]`                         |        4 |
| `r_output_write[0:3]` + `r_output_read[0:3]` |        8 |
| **total integral de dados**                  |   **49** |

O campo `h13` é a soma dos nove pesos espaciais com os oito pesos
transformados ativos. Não há um banco `r_input_weight[0:15]`: a FSM lê o tile
espacial, `WeightTransform` calcula a matriz transformada e
`WeightTransformRow` seleciona a linha correspondente ao ciclo.

O ponto de economia não é simplesmente trocar 16 por 9. Oito palavras
transformadas ainda precisam existir para alimentar os oito MACs; o ganho
vem de não armazenar as outras doze ao mesmo tempo.

#### 6.2 `stream08-rowconst4`

Arquivo ativo: `conv-i16-h13-t08-o4-m08-stream08-rowconst4.sv`.

A fronteira de registradores é a mesma de `wstream4`: 9 pesos espaciais, 8
pesos ativos, 4 palavras de transformada, 4 de inversa e os bancos de saída.
Assim, a contagem integral chega a 49 palavras no m08.

A diferença está no combinacional. `WeightTransformRowConst` calcula uma linha
com constantes fixas e faz o arredondamento no fim da soma. Os vetores locais
`weight[0:8]`, `sum[0:3]`, `rounded[0:3]` e `remainder[0:3]` são sinais
combinacionais do módulo; eles não devem ser contados como registradores.

Essa versão pode alterar área e timing mesmo mantendo a mesma contagem de
palavras. Reduzir registradores não garante reduzir área quando o arredondamento
adiciona comparadores, extensões de sinal e somadores.

#### 6.3 `stream08-rowconst4-exact` e `stream08-exact`

Estas duas alternativas foram retiradas da linha ativa e estão descritas no
**Anexo A**, no fim deste arquivo. A primeira mantém a fronteira de 49 palavras
do `rowconst4`, mas aumenta as larguras para preservar numeradores exatos; a
segunda mantém 16 pesos transformados exatos e chega a 52 palavras. A
separação evita que uma escolha histórica de largura seja confundida com o
fluxo ativo de redução de armazenamento.

#### 6.4 `stream08-prefetch4`

Arquivo ativo: `conv-i20-h16-t08-o4-m08-stream08-prefetch4.sv`.

Essa variante não transforma pesos. Ela usa o mesmo núcleo `stream08` e adiciona
`r_input_prefetch[0:3]` para capturar a próxima coluna enquanto a janela atual
está sendo processada.

```text
stream08 baseline: 16 input + 16 weights + 4 transform + 4 inverse + 8 out = 48
prefetch4:         20 input + 16 weights + 4 transform + 4 inverse + 8 out = 52
```

O banco de prefetch não reduz o trabalho de uma janela. Ele protege a entrada
seguinte e pode reduzir bolhas entre janelas. O custo é quatro palavras extras
de estado, além dos flags `r_input_prefetch_full` e do controle de commit.

#### 6.5 `stream08-prefetch4-rowconst4`

Arquivo ativo: `conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4.sv`.

Esta variante combina o prefetch de quatro amostras com a técnica
`rowconst4`. O tile espacial de pesos continua registrado em
`r_weight_spatial[0:8]`, mas apenas as oito palavras transformadas das duas
linhas consumidas pelos oito MACs ficam no banco ativo `r_input_weight[0:7]`.
As quatro instâncias `WeightTransformRowConst` geram as linhas sob o controle
da FSM de Hadamard; não há um banco registrado de 16 pesos transformados.

```text
entrada:       16 palavras da janela + 4 palavras do prefetch
pesos:           9 palavras espaciais + 8 palavras transformadas ativas
computacao:      8 MACs, duas linhas por ciclo de Hadamard
```

O prefetch só é habilitado depois que o primeiro tile de pesos foi carregado.
Na borda direita ou quando o banco ainda não está cheio, a variante preserva
o deslocamento de duas colunas do `stream08` original; quando o banco está
cheio, o commit substitui as colunas novas antes da leitura da segunda coluna.
O baseline `rowconst4` continua sendo o arquivo ativo
`conv-i16-h13-t08-o4-m08-stream08-rowconst4.sv`, com sua configuração de
síntese correspondente em `synthesis/`.

#### 6.6 `stream08-prefetch4-rowconst4-temporal1`

Esta alternativa temporal está arquivada e foi deslocada para o **Anexo A**.
Ela é importante como contraexemplo: manteve 21.892 ciclos, mas o cache de
quatro linhas aumentou área e potência. O fluxo ativo continua sendo o
`prefetch4-rowconst4`, que preserva as linhas constantes em paralelo.

#### 6.7 Arquivamento, `shared` e reprodutibilidade

As variantes que só existem em `archive/`, incluindo `shared`, `exact`,
`temporal1` e o banco latch, ficam reunidas no **Anexo A**. Cada diretório de
síntese preserva `list-file.txt`, logs do Genus, netlist, simulação anotada e
`power_evaluation.txt`; os caminhos dos fontes arquivados foram corrigidos para
que a reprodução histórica não dependa de arquivos ativos.

### 7. Comparativo de registradores de dados

A tabela usa a contagem integral, incluindo `r_output_read`, porque o objetivo
é enxergar o armazenamento real das variantes que ainda orientam o
desenvolvimento. As versões que permanecem somente em `archive/` aparecem no
Anexo A, para que a ordem principal não seja interrompida por experimentos
encerrados.

| Arquitetura                                 | Entrada | Pesos | Transform/inversa | Estado adicional de dados | Saída/interface | Total de palavras |
| ------------------------------------------- | ------: | ----: | ----------------: | ------------------------: | --------------: | ----------------: |
| `std`, 8 MACs                               |      16 |    16 |                16 |        `r_conv_input[16]` |               8 |            **72** |
| `stream08`, 8 MACs                          |      16 |    16 |                 8 |                         0 |               8 |            **48** |
| `stream04`, 8 MACs                          |      16 |    16 |                 4 |                         0 |               8 |            **44** |
| `stream00`, 8 MACs                          |      16 |    16 |                 0 |                         0 |               8 |            **40** |
| `all`, 16 MACs                              |      16 |    16 |                 0 |        `r_conv_input[16]` |               8 |            **56** |
| `stream08-wstream4`                         |      16 |    17 |                 8 |                         0 |               8 |            **49** |
| `stream08-rowconst4`                        |      16 |    17 |                 8 |                         0 |               8 |            **49** |
| `stream08-prefetch4`                        |      20 |    16 |                 8 |                         0 |               8 |            **52** |
| `stream08-prefetch4-rowconst4`              |      20 |    17 |                 8 |                         0 |               8 |            **53** |
| `stream08-prefetch4-rowconst4-latch-single` |      20 |    17 |                 8 |                         0 |               8 |            **53** |

Essa tabela mostra três lições importantes:

1. `t00` não quer dizer que a arquitetura tem menos registradores totais; no
   `all`, o banco `r_conv_input` fica fora de `t`, enquanto a inversa é
   capturada diretamente no banco de saída.
2. `stream00` e `stream04` podem empatar em palavras, mas colocam a fronteira em
   pontos diferentes do datapath.
3. A variante com menos pesos transformados (`wstream4`/`rowconst4`) pode ter
   a mesma quantidade de palavras que outra, mas usar larguras e lógica muito
   diferentes.

Na linha `temporal1`, as 16 palavras de cache são a declaração RTL completa
(`r_weight_row_cache0..3`). A linha `cache3` não alimenta nenhum MAC no
agendamento final e tende a ser removida pelo Genus; por isso o relatório
pós-síntese contabiliza 1.401 flip-flops, e não uma simples multiplicação da
contagem nominal de palavras. Essa diferença entre estado declarado e estado
retido é parte do motivo para sempre conferir o relatório de área.

### 8. O que a contagem não mostra

A contagem de palavras é uma ferramenta de raciocínio arquitetural, não um
substituto para Genus. Ela não mostra:

- número de flip-flops depois de otimização e remoção de registradores mortos;
- largura real de cada sinal, principalmente nas variantes `exact`;
- muxes necessários para selecionar linhas e rotacionar pesos;
- profundidade dos somadores da transformada, inversa e arredondamento;
- clock-enable e atividade de cada banco;
- registradores escalares de FSM, endereço e contadores;
- área e potência de fios longos e buffers.

Por isso a ordem correta de estudo é:

```text
contar palavras -> provar a vida dos dados -> simular bit a bit
-> sintetizar o mesmo RTL -> rodar anotada -> medir power/energia
```

Se uma redução remove quatro palavras, mas cria uma árvore de muxes maior que
o banco removido, a síntese pode ficar pior. O registro da decisão deve mostrar
os dois lados: palavras removidas e lógica adicionada.

### 9. Mapa mental final

```text
STD (72 palavras)
  mantém as etapas convencionais em bancos separados.
        |
        | substitui as matrizes completas por linhas consumidas em fluxo
        v
STREAM08 (48 palavras)
  registra linhas da transformada e da inversa.
        |
        | elimina a linha de inversa já consumida
        v
STREAM04 (44 palavras)
  conserva a linha transformada e acumula a inversa na saída.
        |
        | elimina também r_transform_row e seleciona w_conv_transform diretamente
        v
STREAM00 (40 palavras)
  reutiliza o banco de saída como acumulador.
        |
        | comparação paralela, não mais uma etapa de redução
        v
ALL16 (56 palavras; 16 MACs)
  calcula os 16 produtos em paralelo.
        |
        | stream08 é escolhido pelo melhor compromisso PPA entre os baselines m08
        v
STREAM08-*
  inicia os testes de armazenamento de pesos, precisão e prefetch.
```

O princípio comum é simples: uma informação deve ser registrada somente se
precisa sobreviver a uma borda de clock. Todo o restante deve ser consumido no
ciclo em que é produzido, desde que a ordem, o valor bit-exato e o contrato de
memória permaneçam inalterados.

### 10. Comparações metodológicas

As referências que só existem em `archive/` não interrompem a narrativa das
variantes ativas. A descrição do `std` m04 e do `stream08` genérico, incluindo
seus bancos de 72 e 48 palavras e a remoção do suporte a dois MACs, foi
transferida para o **Anexo A**. A seção principal segue a ordem de redução dos
registradores (`std`, `stream08`, `stream04`, `stream00`), apresenta `all16`
como comparação paralela e então registra a escolha de `stream08` como base
PPA para os testes de pesos `stream08-*`.

### 11. Como comparar duas alterações sem se enganar

Ao comparar duas fontes, preencha esta sequência antes de olhar para área:

1. Liste cada declaração `r_*` que possui vetor de dados.
2. Separe bancos de dados de contadores, estados e endereços.
3. Para cada banco, escreva quando ele recebe um valor e por quantos ciclos o
   valor precisa continuar válido.
4. Marque se o mesmo valor aparece em outro banco com outro nome.
5. Conte palavras e bits separadamente.
6. Identifique o fio combinacional que passou a fazer o trabalho do banco
   removido.

Um exemplo concreto:

```text
remover r_transform_row[4]
  ganho: -4 palavras e -80 bits
  substituto: muxes de w_conv_transform indexados por r_transform_product_idx
  risco: caminho combinacional maior e seleção desalinhada com os pesos

remover r_inverse_row[4]
  ganho: -4 palavras e -80 bits
  substituto: InverseRow alimentado diretamente por w_inverse_product_row
  risco: perder somente o trace ou, se houver outro fanout, perder dado funcional
```

O segundo caso é seguro somente depois de procurar todos os consumidores do
sinal. Uma linha usada apenas por `$display` é diferente de uma linha usada
como entrada de `InverseRowAccumulate`.

### 12. Regra prática para as próximas reduções

A sequência de redução que este inventário recomenda é:

```text
1. retirar bancos duplicados (`r_conv_input` e capturas intermediárias da saída)
2. retirar linhas que são somente trace (`r_inverse_row` quando comprovado)
3. mover a fronteira da transformada (`r_transform_row` versus mux direto)
4. dobrar ou reutilizar o acumulador de saída
5. somente depois reduzir o banco de pesos
6. por último avaliar prefetch e overlap de entrada
```

Essa ordem evita otimizar o lugar errado. O banco de pesos espaciais de nove
palavras parece menor que 16, mas pode exigir transformadores, arredondadores e
controle de linhas. O prefetch de quatro palavras parece pequeno, mas aumenta a
vida da entrada e pode permitir que a FSM leia enquanto a convolução está
ocupada.

O critério final continua sendo triplo:

```text
mesmos resultados + mesma interface de memória + menor custo medido
```

Uma contagem menor que falha no golden, perde uma contribuição de canal ou
precisa de uma árvore de muxes maior não é uma redução arquitetural válida.

### 13. Conversão dos modelos m04 para m08

Na rodada de setembro de 2026, os modelos ativos que só tinham quatro MACs
receberam uma variante `m08` separada. Os arquivos e diretórios `m04` foram
movidos para `archive/m04/` como referência histórica para que os resultados
anteriores de área, timing e potência continuem reproduzíveis.

Nos novos `stream04` e `stream08-*`, cada ciclo de Hadamard consome duas linhas
de quatro elementos: a primeira linha permanece registrada e a segunda é
alimentada diretamente pela transformada. A inversa é feita em dois blocos
`InverseRow` e dois `InverseRowAccumulate`, com avanço de
`r_inverse_row_idx` em dois. Assim, há oito instâncias físicas de `Multip` (ou
`MultipExact`/`MultipSpatialExact` nas variantes exatas) sem alterar a
interface externa `Conv`.

Arquivos `m08` adicionados:

```text
conv-i16-h16-t16-o4-m08-std.sv
conv-i16-h16-t00-o4-m16-all.sv
conv-i16-h16-t08-o4-m08-stream08.sv
conv-i16-h16-t04-o4-m08-stream04.sv
conv-i16-h16-t00-o4-m08-stream00.sv
conv-i16-h13-t08-o4-m08-stream08-wstream4.sv
conv-i16-h13-t08-o4-m08-stream08-rowconst4.sv
conv-i20-h16-t08-o4-m08-stream08-prefetch4.sv
conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4.sv
conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4-latch-single.sv
```

As variantes `rowconst4-exact`, `stream08-exact`, `shared` e `temporal1` foram
encerradas e permanecem no Anexo A. O coletor padrão exclui projetos
arquivados; para reproduzir a comparação histórica, execute
`scripts/report.py --include-archived`.

O genérico `stream08` também foi movido para
`archive/m04/conv-i16-h16-t08-o4-mxx-stream08-generic.sv`, junto com sua
configuração de síntese. O mesmo caminho é usado pelos alvos de simulação
compatíveis do `Makefile`.

O alvo `make std` agora usa `conv-i16-h16-t16-o4-m08-std.sv` e passa
`NUM_MULT=8`. Os alvos explícitos de oito MACs foram adicionados ao
`Makefile`; os alvos e fontes de quatro MACs continuam disponíveis para
comparação.

O fluxo RTL e o fluxo de potência foram executados para os fontes m08
selecionados na Paxos, usando Genus 21.1, Xcelium 23.03, o banco gate-level e
o `dut.shm` produzido pela simulação. A rodada do prefetch rowconst4 temporal1
foi feita a partir dos commits `92976cc7` (seleção dos coeficientes antes da
aritmética) e `592df08b` (registro dos resultados). Os artefatos completos,
incluindo os logs de `logical`, `sim` e `power`, permanecem no diretório de
síntese correspondente, mesmo quando a fonte foi arquivada depois.

Resultados nominais de `report_power -unit mW` (linha `Subtotal`):

| Variante m08                                |   Leakage | Internal | Switching |        Total |
| ------------------------------------------- | --------: | -------: | --------: | -----------: |
| `std`                                       | 0.0527922 | 0.475721 |  0.334820 | **0.863333** |
| `stream04`                                  | 0.0553297 | 0.411765 |  0.291210 | **0.758305** |
| `stream08-wstream4`                         | 0.0648294 | 0.346387 |  0.261474 | **0.672691** |
| `stream08-rowconst4`                        | 0.0649760 | 0.342512 |  0.264060 | **0.671548** |
| `stream08-prefetch4`                        | 0.0559951 | 0.419183 |  0.301483 | **0.776661** |
| `stream08-prefetch4-rowconst4`              | 0.0664352 | 0.403777 |  0.306344 | **0.776556** |
| `stream08-prefetch4-rowconst4-latch-single` | 0.0644949 | 0.317654 |  0.259372 | **0.641520** |

As variantes m08 ativas com fluxo completo tiveram `LOGICAL_RC=0`, `SIM_RC=0`
e `POWER_RC=0`. O mesmo workload reportou
2.025 tiles inversos, 8.100 escritas válidas e zero amostras de entrada fora
dos limites. Os componentes `Leakage`, `Internal` e `Switching` das linhas
de prefetch estão registrados nos respectivos `power_evaluation.txt`; a
tabela acima destaca os valores nominais de total.

Os resultados `m04` e os relatórios de síntese anteriores permanecem sob
`archive/m04/`; nenhum arquivo `m04` foi sobrescrito pelos artefatos `m08`.

### 14. Diagrama de ondas das FSMs e do prefetch

O diagrama abaixo mostra a relação temporal entre as três FSMs do
`stream08-prefetch4` e o leitor auxiliar de entrada. Cada coluna representa
um ciclo completo entre duas bordas de subida de `clk`. O nome mostrado é o
valor do estado registrado (`*_current`) durante aquele ciclo; a transição
para o próximo estado acontece na borda seguinte.

O leitor auxiliar não é uma nova enumeração dentro de `type_st_input`. Ele é
representado pelos registradores `r_input_prefetch_active`,
`r_input_prefetch_phase` e `r_input_prefetch_full`. A fase é um contador
portável: `PREFETCH_PHASES = STREAM_CYCLES + 2`, com uma fase para
`TRANSFORM`, uma para cada ciclo de `HADAMARD` e uma para `INVERSE`.
Por isso, no diagrama ele aparece como uma quarta faixa paralela à FSM de
entrada, sem acrescentar estados enumerados à FSM principal.

#### 14.1 Carregamento do primeiro tile

Antes do primeiro `CONV_INPUT`, a FSM de entrada ainda precisa carregar as
quatro linhas completas da janela 4x4. A notação `[4]` significa quatro
ciclos, um para cada palavra da linha. Assim que o tile entra em
`CONV_INPUT`, o endereço da primeira coluna do tile seguinte já é emitido.
Com a latência de uma borda da RAM, a amostra chega no início de `TRANSFORM`.

```text
                         ciclos de clock  ───────────────────────────────────────────────────────────────>

FSM de entrada       WAIT_INPUT  ADDRESS_INPUT  READ_WEIGHTS[n]  READ_IN_10A[4]  READ_IN_10B[4]
                     READ_IN_8C[4]  READ_IN_8D[4]  CONV_INPUT  TRANSFER  HOLD_WRITE  ...

FSM de convolução    WAIT_CONV ────────────────────────────────────────────────┐
                                                                                └─ TRANSFORM
                                                                                   HADAMARD[2]
                                                                                   INVERSE
                                                                                   WAIT_CONV

FSM de saída         WAIT_OUTPUT  RESET_OUTPUT ────────────────────────────────┐
                                                                                └─ WRITE_OUTPUT /
                                                                                   READ_OUTPUT

Prefetch auxiliar    idle       idle       idle       idle       START  READ[0:3]  READY  COMMIT
```

Durante `TRANSFORM`, `HADAMARD` e `INVERSE`, o banco `r_input_feat` permanece
estável. O prefetch do próximo tile começa somente depois que o tile atual
foi carregado em `CONV_INPUT`; a emissão do endereço antecipado usa a borda
anterior para que a primeira amostra fique disponível em `TRANSFORM`.

#### 14.2 Regime estacionário com prefetch

A partir do tile seguinte, a coluna necessária para o próximo tile é lida
durante o uso do tile corrente. A sequência abaixo não fixa a duração de
`HOLD_WRITE`, pois ela também depende da FSM de saída e de
`w_input_write_done`; ela mostra apenas a sobreposição relevante.

```text
                         k       k+1       k+2       k+3       k+4       k+5       k+6       k+7
                         │         │         │         │         │         │         │         │
clk                      ↑         ↑         ↑         ↑         ↑         ↑         ↑         ↑

FSM de entrada       CONV_INPUT TRANSFER  HOLD_WRITE HOLD_WRITE HOLD_WRITE READ_IN_8D ...
                                  │         │         │         │         │
                                  └─────────┴─────────┴─────────┴─────────┘
                                    espera a liberação e o buffer pronto

FSM de convolução    WAIT_CONV  TRANSFORM  HADAMARD  HADAMARD  INVERSE  WAIT_CONV ...

FSM de saída         RESET_OUTPUT  RESET_OUTPUT  RESET_OUTPUT  WRITE_OUTPUT /
                                                            READ_OUTPUT ...

Prefetch auxiliar    START      READ[0]   READ[1]   READ[2]   READ[3]   READY  COMMIT
                     issue      phase=0   phase=1   phase=2   phase=3   full=1 full→0

Porta de entrada     request    prefetch  prefetch  prefetch  prefetch  livre   READ_IN_8D
                     addr+b0    addr+b1   addr+b2   addr+b3
```

No ciclo `START` (`CONV_INPUT`), o leitor auxiliar emite um endereço-base
derivado da mesma progressão de `r_input_addr_feat`, mas grava em
`r_input_prefetch[0:3]`. Com a latência de uma borda da RAM, a primeira
amostra fica válida no início de `TRANSFORM`. O contador de fase
`r_input_prefetch_phase` avança apenas quando `p_input_valid` está ativo.
Assim, ele não altera `r_input_addr_count`, que continua pertencendo à FSM
principal. Para o
`stream08` atual, os valores são `0 = TRANSFORM`, `1..STREAM_CYCLES =
HADAMARD` e `STREAM_CYCLES + 1 = INVERSE`; portanto, com dois ciclos de
Hadamard, as quatro leituras são indexadas por `0, 1, 2, 3`.

O commit não ocorre simplesmente quando `full=1`. A condição é:

```text
r_input_prefetch_full
&& (w_conv_input_release || w_conv_end ||
    (st_conv_current == WAIT_CONV &&
     st_output_current inside {RESET_OUTPUT, READ_OUTPUT}))
&& w_input_write_done
```

Essa proteção impede que a coluna pré-carregada sobrescreva
`r_input_feat` enquanto o transformador, o Hadamard ou a inversa ainda podem
consultar o tile corrente. Depois do commit, `READ_IN_8D` captura a segunda
coluna nova e a janela seguinte fica completa.

#### 14.3 Transições de controle

```text
FSM de entrada:

  READ_IN_10A ─> READ_IN_10B ─> READ_IN_8C ─> READ_IN_8D
        │                                      │
        └──────── carregamento inicial ────────┘

  CONV_INPUT ─> TRANSFER ─> HOLD_WRITE
                 │
                 ├─ prefetch incompleto: permanece em HOLD_WRITE
                 ├─ prefetch completo e commit seguro: ─> READ_IN_8D
                 └─ primeiro tile/sem prefetch: ────────> READ_IN_8C

  READ_IN_8D ─> CONV_INPUT ─> TRANSFER

FSM de convolução:

  WAIT_CONV ─> TRANSFORM ─> HADAMARD ─> INVERSE ─> WAIT_CONV
                         (2 ciclos no m08)

FSM de saída:

  WAIT_OUTPUT ─> RESET_OUTPUT ─> WRITE_OUTPUT
                              └─> READ_OUTPUT
```

A leitura do prefetch e o cálculo da convolução compartilham a porta externa
de memória de entrada, mas não compartilham seus contadores temporais. A
convolução usa `r_input_feat`; o prefetch usa `r_input_prefetch`. Essa é a
razão pela qual a implementação precisa de alguns registradores adicionais,
mas não de uma segunda cópia da FSM de endereçamento completa.

### 15. Alternativas arquivadas

As experiências com latches foram deslocadas para o **Anexo A**, junto com as
demais versões que não fazem parte da árvore ativa. O baseline
`prefetch4-rowconst4` continua sendo a referência corrente; a variante latch
fica documentada como experimento de redução de flip-flops, com seu resultado
funcional e PPA preservado no anexo.

### Anexo A — Versões que só existem em `archive/`

Este anexo reúne, independentemente da quantidade de MACs, tudo que foi
retirado da linha ativa. A regra é simples: o corpo principal explica as
decisões que ainda podem ser usadas para desenvolver os fontes ativos; o
anexo conserva as tentativas anteriores, seus bancos de dados e seus números,
para que nenhuma comparação histórica desapareça.

#### A.1 Referências m04

O [baseline `std` m04](/home/tarsio/gaph/FastConv_SystemVerilog/rtl/conv2x2/archive/m04/conv-i16-h16-t16-o4-m04-std.sv)
mantém 16 palavras de features, 16 pesos transformados, 16 palavras de
transformada, 16 de entrada da convolução e 8 de saída: 72 palavras de dados.
Ele é a fronteira inicial da história, não a implementação padrão atual.

Também ficam aqui os antigos `stream00`, `stream04`, `stream08`, `wstream4`,
`prefetch4` e `stream08-exact` m04. Eles mostram a mesma sequência de redução
com quatro MACs: remover `r_conv_input`, consumir a linha de inversa no ciclo
em que ela é produzida, selecionar a linha transformada diretamente e, no
prefetch, adicionar quatro palavras para manter a próxima coluna viva. Os
fontes e as sínteses estão em `archive/m04/`; os resultados históricos são
incluídos somente com `--include-archived`.

| Fonte arquivada                                       | Papel histórico                                |
| ----------------------------------------------------- | ---------------------------------------------- |
| `conv-i16-h16-t16-o4-m04-std.sv`                      | Referência convencional, 4 MACs                |
| `conv-i16-h16-t00-o4-m04-stream00.sv`                 | Streaming sem linha transformada registrada    |
| `conv-i16-h16-t04-o4-m04-stream04.sv`                 | Streaming com linha transformada registrada    |
| `conv-i16-h16-t08-o4-m04-stream08.sv`                 | Streaming genérico fixo, 4 MACs                |
| `conv-i16-h16-t08-o4-mxx-stream08-generic.sv`         | Genérico histórico para `NUM_MULT=4` ou `8`    |
| `conv-i16-h13-t08-o4-m04-stream08-wstream4.sv`        | Pesos espaciais e linha ativa, 4 MACs          |
| `conv-i16-h13-t08-o4-m04-stream08-rowconst4.sv`       | Transformação de linha constante, 4 MACs       |
| `conv-i16-h13-t08-o4-m04-stream08-rowconst4-exact.sv` | Linha constante com numeradores exatos, 4 MACs |
| `conv-i16-h20-t08-o4-m04-stream08-exact.sv`           | Pesos transformados exatos, 4 MACs             |
| `conv-i20-h16-t08-o4-m04-stream08-prefetch4.sv`       | Prefetch de coluna, 4 MACs                     |

O [`stream08` genérico m04](/home/tarsio/gaph/FastConv_SystemVerilog/rtl/conv2x2/archive/m04/conv-i16-h16-t08-o4-mxx-stream08-generic.sv)
implementa a mesma organização streaming para `NUM_MULT=4` ou `8`. O suporte
a dois MACs foi retirado em `04848aa3`, porque manter esse caso no arquivo genérico
criava uma promessa de datapath que não era mais usada nem validada.

#### A.2 `rowconst4-exact` e `stream08-exact` m08

O [rowconst4-exact](/home/tarsio/gaph/FastConv_SystemVerilog/rtl/conv2x2/archive/m08/conv-i16-h13-t08-o4-m08-stream08-rowconst4-exact.sv)
preserva a contagem nominal de 45 palavras do `rowconst4`, mas usa larguras
maiores para carregar numeradores exatos e retirar arredondamentos
intermediários. A lição é que menos palavras não significa necessariamente
menos bits, somadores ou área.

O [stream08-exact h20](/home/tarsio/gaph/FastConv_SystemVerilog/rtl/conv2x2/archive/m08/conv-i16-h20-t08-o4-m08-stream08-exact.sv)
faz a troca oposta: mantém 16 pesos transformados exatos e simplifica a
aritmética do tile. O custo nominal é de 52 palavras de dados, mas a largura
exata evita perdas de precisão durante a transformação.

| Fonte arquivada em `archive/m08/`                     | Decisão preservada                     |
| ----------------------------------------------------- | -------------------------------------- |
| `conv-i16-h13-t08-o4-m08-stream08-rowconst4-exact.sv` | Linhas constantes com aritmética exata |
| `conv-i16-h20-t08-o4-m08-stream08-exact.sv`           | Pesos transformados exatos armazenados |

Os números preservados para as duas variantes exatas são os seguintes. Eles
continuam disponíveis no report completo arquivado, mas não entram na tabela
principal de PPA:

| Variante arquivada         | Células | Área total (um2) | Ciclos | Slack nominal (ps) | Power total (mW) |
| -------------------------- | ------: | ---------------: | -----: | -----------------: | ---------------: |
| `stream08-rowconst4-exact` |  12.903 |       20.041,711 | 25.654 |                217 |         0,814403 |
| `stream08-exact`           |  11.153 |       17.007,726 | 25.717 |                227 |         0,733399 |

#### A.3 `shared` e `temporal1`

O `shared` tentou dividir as somas de `WeightTransformRowConst` entre linhas.
O ganho potencial de lógica veio acompanhado de dependências de seleção e
controle; por isso a versão original foi preservada antes da substituição.

O [temporal1](/home/tarsio/gaph/FastConv_SystemVerilog/rtl/conv2x2/archive/m08/conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4-temporal1.sv)
usou uma única instância do transformador de linha, capturada em quatro
bordas já existentes (`READ_WEIGHTS`, `TRANSFORM` e `HADAMARD`). O contrato
funcional foi mantido em 21.892 ciclos, mas o cache temporal elevou o custo
para 13.193 células, 20.432,097 um2 e 0,984856 mW. É um contraexemplo útil:
compartilhar hardware combinacional pode transferir custo para cache e
seleção.

O report anotado do temporal1 confirma 2.025 tiles, 8.100 escritas válidas e
21.892 ciclos. O slack nominal foi de 190 ps; a energia correspondente ao
workload foi 215,629 nJ.

#### A.4 Banco latch

O [latch-bank m08](/home/tarsio/gaph/FastConv_SystemVerilog/rtl/conv2x2/archive/m08/conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4-latch.sv)
converteu somente bancos independentes para `always_latch`: prefetch de
entrada, pesos espaciais e leitura da saída. FSMs, contadores, endereços,
`r_input_feat`, `r_transform_row`, `r_inverse_row` e o acumulador de saída
continuaram edge-triggered para preservar a janela temporal.

O experimento manteve 21.892 ciclos, reduziu 340 flip-flops (29,3%), chegou a
18.989,810 um2 e 0,741005 mW, e perdeu 24 ps de slack nominal. Ele permanece
como evidência de uma troca de armazenamento, não como padrão ativo.

## Alterações em ordem cronológica

Esta parte registra como o RTL e o fluxo de avaliação mudaram ao longo do
desenvolvimento. Diferentemente da seção lógica anterior, aqui a ordem é a dos
experimentos, decisões de implementação, correções de infraestrutura e
campanhas executadas. Os resultados são evidências históricas vinculadas às
fontes e aos commits indicados; não representam necessariamente o estado atual
de todas as variantes.

### 1. Inventário detalhado: baseline `std` e snapshot de `stream00`

Este inventário abre o diário técnico com dois pontos de referência, sem
recontar a sequência didática da seção lógica: primeiro documenta os bancos do
`std`; depois registra o snapshot de `stream00` que serviu de base a alguns
experimentos incrementais. Cada palavra de dados tem 20 bits (`NBITS=20`). O
`std` mantém bancos registrados para a janela, os pesos transformados, a
transformada completa e a entrada da convolução.

#### 1.1 Baseline: bancos de dados do `std`

| Sinal                  |        Dimensão | Função                                 |
| ---------------------- | --------------: | -------------------------------------- |
| `r_input_feat[0:15]`   |    16 x 20 bits | Janela 4x4 lida da feature map         |
| `r_input_weight[0:15]` |    16 x 20 bits | Pesos transformados                    |
| `r_conv_temp[0:15]`    |    16 x 20 bits | Matriz transformada completa           |
| `r_conv_input[0:15]`   |    16 x 20 bits | Entrada registrada antes dos produtos  |
| `r_output_write[0:3]`  |     4 x 20 bits | Valores do tile que serão escritos     |
| `r_output_read[0:3]`   |     4 x 20 bits | Contribuição anterior de outros canais |
| **Total de dados**     | **72 palavras** | **Bancos de dados do baseline**        |

Essa contagem é de palavras de dados, não de flip-flops sintetizados. Ela
estabelece a referência para entender quais fronteiras o streaming remove ou
substitui.

#### 1.2 Snapshot de `stream00` antes das alterações incrementais

O inventário abaixo é o ponto de partida dos experimentos cronológicos 2 a 5:
um snapshot de `stream00` m04/m08 anterior às alterações incrementais. Ele
não representa todas as variantes streaming. Os bancos da janela, dos pesos,
`r_output_write` e `r_output_read` continuam existindo, mas não são repetidos
nesta tabela. A última coluna mostra o destino de cada estado; ela não
prescreve que todos devam permanecer.

| Sinal                     |    Dimensão | Função                                                             | Destino nos experimentos                      |
| ------------------------- | ----------: | ------------------------------------------------------------------ | --------------------------------------------- |
| `r_transform_row`         | 4 x 20 bits | Mantém a linha transformada que alimenta os MACs no ciclo seguinte | Removida em `stream00`; mantida em `stream04` |
| `r_inverse_row`           | 4 x 20 bits | Cópia da última linha de produtos, usada apenas pelo trace         | Removida; não participa do caminho funcional  |
| `r_output_accumulator`    | 4 x 20 bits | Acumula parcialmente os quatro pixels de saída                     | Incorporada a `r_output_write`                |
| `r_inverse_row_idx`       |      2 bits | Índice da linha usado pela inversa incremental                     | Mantido                                       |
| `r_transform_product_idx` |      4 bits | Base do grupo de produtos atual                                    | Mantido para selecionar a faixa em `stream00` |

Os sinais `w_inverse_partial_current`, `w_output_acc_next` e
`w_output_capture` são combinacionais. Eles não representam palavras
armazenadas e não devem ser contadas como registradores.

#### 1.3 Como ler o registro técnico dos experimentos seguintes

Este trecho não é uma segunda sequência didática das arquiteturas. Ele reúne o
registro de implementação e as evidências das campanhas. Primeiro, há três
perguntas independentes sobre o snapshot de `stream00`:

| Pergunta                                                  | Resultado registrado                                                                        |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `r_inverse_row` participa do cálculo funcional?           | Não; era usado apenas pelo trace e foi removido.                                            |
| `r_transform_row` precisa ficar registrado?               | Depende da variante: `stream00` o remove; `stream04` o mantém após a comparação de síntese. |
| Acumulador e banco final de saída precisam ser separados? | Não nessa FSM; `r_output_write` passou a exercer os dois papéis.                            |

Depois dessas decisões, o assunto muda. Os experimentos 6 e 7 delimitam o
escopo histórico e registram o plano da época; os experimentos 8 e 9 tratam
dos ajustes de scripts e configurações; os experimentos 10 e 11 apresentam as
campanhas gate-level antes e depois da simplificação da FSM; o experimento 12
reúne a comparação de PPA.

Em particular, os experimentos 2 a 5 não descrevem uma cadeia em que toda
variante recebe cumulativamente cada alteração. A remoção de `r_transform_row` é uma
ramificação: `stream00` não a mantém, enquanto `stream04` a preserva por causa
do resultado de síntese. Para a explicação por arquitetura, use a seção
**Alterações em ordem lógica**, organizada na ordem `std -> stream08 ->
stream04 -> stream00 -> all -> stream08-*`.

### 2. Experimento 1: remover `r_inverse_row`, usado apenas pelo trace

#### 2.1 Motivação

Nos snapshots então avaliados de `conv-i16-h16-t00-o4-m04-stream00.sv` e
`conv-i16-h16-t00-o4-m08-stream00.sv`, `r_inverse_row` recebia
`w_inverse_product_row` ou `w_inverse_product_row_lane1`. A única leitura era
uma instância adicional de `InverseRow`, cujo resultado (`w_inverse_partial`) era
impresso no bloco `STREAM_DEBUG`. A saída real usa as instâncias
`inverse_row_lane0`/`inverse_row_lane1`, alimentadas diretamente pelos
produtos do ciclo atual, e depois usa `InverseRowAccumulate`.

Portanto, `r_inverse_row` não participa de `r_output_accumulator`, `w_output_acc_next`,
`w_output_capture`, `p_output_data_write` ou dos endereços de memória.

#### 2.2 Mudança aplicada

Em ambos os arquivos foram removidos:

- a declaração de `r_inverse_row`;
- sua inicialização no reset;
- sua inicialização no estado `TRANSFORM`;
- sua captura no estado `HADAMARD`;
- a instância `InverseRow inverse_row` usada somente pelo trace;
- as linhas `Slast` e `SIG` do trace `STREAM_DEBUG`.

A acumulação funcional não foi reescrita. O trecho continua sendo:

```systemverilog
InverseRow inverse_row_current(... w_inverse_product_row ...);
InverseRowAccumulate inverse_row_acc(... w_inverse_partial_current ...);
```

Para `conv-i16-h16-t00-o4-m08-stream00.sv`, o segundo caminho continua usando
`w_inverse_product_row_lane1` e `inverse_row_acc_second`.

Na antiga variante parametrizada de 2 MACs, o vetor `r_inverse_row` conservava a
primeira metade dos produtos enquanto a segunda metade era calculada no ciclo
seguinte. Essa variante foi removida desta pasta; a observação fica registrada
apenas para explicar por que a redução não foi aplicada de forma mecânica.

#### 2.3 Redução obtida

Cada variante removeu 4 palavras de 20 bits, ou 80 bits de armazenamento.
Considerando `conv4mac` e `conv8mac`, a redução textual é de 8 palavras, ou
160 bits. Essa é uma contagem no RTL, não uma redução comprovada de flip-flops
ou área: esses efeitos só podem ser afirmados a partir da síntese do mesmo
snapshot de código.

#### 2.4 Condições de aceite do experimento

- compilação e simulação Verilator sem erros;
- mesmos `inverse_tiles`, `valid_writes` e valores golden;
- lint também com `STREAM_DEBUG` definido;
- nenhuma referência residual ao banco `r_inverse_row` nem à instância
  `InverseRow` que existia somente para trace;
- as referências funcionais a `w_inverse_partial_current` e às instâncias
  `inverse_row_current`/`inverse_row_lane1` continuam esperadas e não devem
  ser removidas.

### 3. Evidências do experimento `r_inverse_row`

#### 3.1 `conv4mac`

Comando:

```bash
make run-stream08 NUM_MULT=4
```

Resultado observado:

```text
2x2 simulation passed: inverse_tiles=2025 cycles=29749
valid_writes=8100 input_samples_clipped=0 invalid_output_beats=0
Core active cycles: 12150
```

#### 3.2 `conv8mac`

Comando:

```bash
make run-stream08 NUM_MULT=8
```

Resultado observado:

```text
2x2 simulation passed: inverse_tiles=2025 cycles=25699
valid_writes=8100 input_samples_clipped=0 invalid_output_beats=0
Core active cycles: 8100
```

#### 3.3 Lint

Os dois arquivos também passaram por:

```bash
verilator --lint-only -Wno-fatal -DSIMULATION -DSTREAM_DEBUG ...
```

Os avisos restantes são avisos de largura já existentes em memória,
multiplicador, contadores e testbench; não houve erro de elaboração.

O wrapper ModelSim `fish ./test-streaming.fish` não iniciou neste ambiente e
terminou com código 159 (SIGSYS do sandbox). Isso é uma limitação da
execução local, não uma falha funcional observada no Verilator.

### 4. Experimento 2: testar a fronteira de `r_transform_row`

Este experimento compara duas escolhas de microarquitetura; não é uma remoção
adotada por todas as variantes. Nas variantes `stream00` m04 e m08, os MACs
selecionam diretamente de `w_conv_transform` a faixa indicada por
`r_transform_product_idx`, sem armazená-la em `r_transform_row`. A variante
`stream04` m04 mantém esse banco como alternativa de comparação. São duas
ramificações, não etapas cumulativas. `r_transform_row` guarda a linha
transformada entre sua captura e o ciclo em que os MACs a consomem;
`r_inverse_row`, tratado no experimento 2, era apenas uma cópia para trace.

#### 4.1 Hipótese

Substituímos a linha armazenada por seleção combinacional de
`w_conv_transform[r_transform_product_idx + offset]`. O valor selecionado fica
estável durante o ciclo porque `r_transform_product_idx` só muda na borda de
clock que encerra o grupo de Hadamard; nessa mesma borda os pesos ativos são
rotacionados. Assim, a nova linha e os novos pesos passam a valer juntos no
ciclo seguinte.

#### 4.2 Protocolo de avaliação da hipótese

1. desenhar a tabela ciclo a ciclo para `NUM_MULT=4` e `NUM_MULT=8`;
2. confirmar a relação entre `st_conv_current`, `r_transform_product_idx`,
   `r_conv_multiply_count` e `r_transform_row`;
3. criar uma variante temporária sem `r_transform_row`;
4. comparar produto por produto e acumulador por acumulador contra a versão
   congelada;
5. somente depois rodar a regressão completa e, se disponível, síntese.

No caso `NUM_MULT=4`, os quatro índices usados são 0, 4, 8 e 12. No caso
`NUM_MULT=8`, os grupos são 0 e 8 e todos os oito operandos passam a ser
selecionados diretamente da matriz transformada.

#### 4.3 Mudança aplicada

Na variante sem o banco, a declaração de `r_transform_row` foi removida e
`w_transform_feature` passou a usar diretamente os índices da linha atual. A
regressão funcional passou, mas a síntese contabilizou os muxes de seleção
dentro da hierarquia `Transform`.

Na variante `conv-i16-h16-t04-o4-m04-stream04.sv`, `r_transform_row[0..3]` foi mantido como fronteira registrada:

- a primeira linha `w_conv_transform[0..3]` é capturada na entrada do Hadamard;
- as linhas seguintes `4..7`, `8..11` e `12..15` são carregadas nas bordas dos
  ciclos correspondentes;
- os MACs leem somente o banco registrado durante cada ciclo.

`conv-i16-h16-t00-o4-m04-stream00.sv` continua sem essa fronteira. A
alternativa `stream04` não altera
`conv-i16-h16-t00-o4-m08-stream00.sv`.

O acumulador, os pesos, os contadores e a ordem da inversa não foram
alterados.

#### 4.4 Redução obtida

Na variante `conv-i16-h16-t04-o4-m04-stream04.sv`, manter a fronteira representa
4 palavras adicionais de 20 bits (80 bits) em relação à variante sem
`r_transform_row`. Na síntese daquela campanha, essa alternativa produziu
6.515 células, 10.857,984 de área total e
1.768,687 de área na hierarquia `Transform`, contra 8.765 células, 12.072,861
e 2.987,622 respectivamente na variante sem `r_transform_row`. Portanto, os
80 bits adicionais vieram acompanhados de uma redução da área total de
aproximadamente 10,1% e da área atribuída à hierarquia `Transform` em
aproximadamente 40,8%.

#### 4.5 Evidência

O teste da variante `conv-i16-h16-t04-o4-m04-stream04.sv` continua funcionalmente
equivalente:

```text
conv4mac: inverse_tiles=2025 cycles=27724 valid_writes=8100
          input_samples_clipped=0 invalid_output_beats=0
```

Nenhum erro de golden output foi observado. A simulação anotada do netlist
regenerado também passou com `cycles=27725` e 0 erros de elaboração.

### 5. Experimento 3: reutilizar `r_output_write` como acumulador

Esta alteração foi aplicada a `conv-i16-h16-t00-o4-m04-stream00.sv` e
`conv-i16-h16-t00-o4-m08-stream00.sv`. Antes, quatro palavras de
`r_output_accumulator` mantinham a soma parcial e outras quatro palavras de
`r_output_write` mantinham o tile final. Como a FSM não escreve a memória
externa durante HADAMARD, os dois papeis podem usar o mesmo banco.

O `STREAMING_DATAPATH_BLOCK` agora zera `r_output_write` no início da janela e
grava nele `w_output_acc_next` a cada ciclo HADAMARD. O `OUTPUT_DATA_BLOCK`
deixou de escrever esse banco e permanece responsavel apenas por
`r_output_read`. Assim, não existem dois processos sequenciais dirigindo o
mesmo sinal.

```text
antes:  r_output_accumulator[4] -> acumulação
        r_output_write[4]       -> escrita
depois: r_output_write[4]       -> acumulação e escrita
```

A redução nominal é de quatro palavras, ou 80 bits com `NBITS=20`. O critério
de aceite foi a simulação bit a bit das variantes m04 e m08:

```text
stream00 m04: inverse_tiles=2025 cycles=27725 valid_writes=8100
stream00 m08: inverse_tiles=2025 cycles=23675 valid_writes=8100
input_samples_clipped=0 invalid_output_beats=0 (ambas)
```

A síntese regenerada do m04 produziu 8.473 células, área 12.127,770 um2,
slack de 243 ps e potência de 0,684856 mW. A área permaneceu igual à rodada
anterior porque o Genus já removia a redundância equivalente; a potência foi
recalculada com o novo netlist.

### 6. Escopo retirado: variante de 2 MACs

A antiga variante parametrizada de 2 MACs foi validada durante o
desenvolvimento, mas não faz mais parte desta árvore. O arquivo
`conv2mac.sv`, o alvo correspondente do Makefile e a configuração de síntese
`synthesis/tcn4-02mac` foram removidos para que não exista uma fonte ou
netlist obsoleto apresentado como configuração suportada.

Os resultados antigos permanecem nos registros de campanha histórica somente
para rastreabilidade; eles não devem ser usados como resultados atuais da
pasta `conv2x2`.

### 7. Plano de execução original (registro histórico)

Esta lista registra o plano proposto naquela etapa do desenvolvimento. Ela não
é o roteiro atual do repositório: parte das variantes m04 foi arquivada, e as
campanhas concluídas aparecem nos experimentos 10 a 12. Na época, cada item deveria
ser um commit separado ou uma unidade de trabalho facilmente revertível:

1. estabelecer o baseline então mantido, com 4 e 8 MACs;
2. remover `r_inverse_row` e o `InverseRow` usado pelo trace;
3. repetir o baseline e registrar ciclos e saídas;
4. comparar a variante sem `r_transform_row` com a variante que restaura essa
   fronteira sequencial;
5. escolher entre as alternativas somente após medir área, timing e potência;
6. estudar a reutilização de `r_output_write` ou uma acumulação dobrada;
7. rodar simulação anotada e power com o netlist do commit correspondente.

O princípio metodológico registrado era não promover uma alteração com base
apenas na área estimada em RTL: cada etapa deveria identificar a mudança, sua
motivação, os testes e o que ainda não havia sido medido.

### 8. Correções no fluxo de síntese e simulação gate-level

As mudanças desta seção são de infraestrutura: corrigem a seleção e a
elaboração dos arquivos usados pelo Genus e pelo Xcelium. Elas não alteram a
arquitetura do datapath descrita nos experimentos 2 a 5.

#### 8.1 Motivação

As duas variantes avaliadas naquela campanha compartilhavam o fluxo Genus e
usavam módulos fixos (`conv-i16-h16-t00-o4-m04-stream00.sv` e
`conv-i16-h16-t00-o4-m08-stream00.sv`). O nome do topo e os caminhos das listas
precisavam corresponder ao layout local para que a síntese não lesse fontes de
outra pasta.

#### 8.2 Mudança aplicada

Os scripts de parsing usados nas campanhas históricas de
`stream4/tcn4-04mac` e `stream4/tcn4-08mac` foram corrigidos para:

- ignorar linhas vazias e comentários;
- converter `NAME=VALUE` em `{NAME VALUE}` antes de `elaborate`;
- preservar a possibilidade de uma linha já estar no formato Tcl;
- resolver as listas de HDL a partir do diretório da configuração ou da raiz
  do repositório;
- ler o topo de `top-module.txt`, evitando o nome legado `system` quando o
  módulo real é `Conv`.

A mesma correção de origem foi aplicada ao caminho do testbench e às duas
`list-file.txt`. Nenhuma síntese é considerada atualizada apenas por essa
mudança de script: a prova exige executar Genus depois que todas as alterações
de RTL forem finalizadas.

#### 8.3 Verificações previstas para fechar a campanha

- confirmar textualmente que todos os caminhos das listas existem;
- executar `make run-stream04-4mac` e `make run-stream00-8mac` no RTL;
- concluir Genus para as duas configurações e, em seguida, executar simulação
  anotada e power com os artefatos dessa mesma campanha.

Esses itens são os critérios registrados para aquela campanha, não tarefas
pendentes agora; os resultados gate-level correspondentes estão nos
experimentos 10 e 11.

#### 8.4 Cuidados de anotação SDF registrados nessa correção

O `sdf_cmd.cmd` precisa usar exatamente o nome produzido pelo Genus
(`Conv_...sdf`, respeitando maiúsculas e minúsculas). Se apontar para
`conv_...sdf`, o Xcelium pode continuar a simulação sem anotação e emitir
apenas um aviso; nesse caso, a simulação não conta como anotada.

O runner gate-level também não deve compilar o `conv*.sv` comportamental junto
com `Conv_logic_mapped.v`: o netlist já contém a hierarquia mapeada e os
módulos auxiliares. A lista deve conter `pack_data.sv`, `pack_param.sv`,
`mem.sv`, o testbench e o netlist, evitando que o simulador escolha
silenciosamente uma definição duplicada de `Conv`.

### 9. Configurações da campanha histórica por variante

Esta tabela registra as configurações usadas naquela campanha; não é o
inventário atual de variantes ativas. As fontes m04 agora ficam em
`archive/m04/`. Para a lista de fontes ativas, use a tabela da seção 1.

| Configuração                       | Fonte do core                         | Parâmetro      |
| ---------------------------------- | ------------------------------------- | -------------- |
| `conv-i16-h16-t00-o4-m04-stream00` | `conv-i16-h16-t00-o4-m04-stream00.sv` | fixo em 4 MACs |
| `conv-i16-h16-t04-o4-m04-stream04` | `conv-i16-h16-t04-o4-m04-stream04.sv` | fixo em 4 MACs |
| `conv-i16-h16-t00-o4-m08-stream00` | `conv-i16-h16-t00-o4-m08-stream00.sv` | fixo em 8 MACs |

As listas da campanha apontavam para `rtl/conv2x2/synthesis/stream12`, de modo
que os logs daquele layout não comprovavam a síntese do RTL desta pasta. O
`testbench-file.txt` também foi corrigido para apontar ao testbench
compartilhado local, e o topo foi definido como `Conv`, respeitando
maiúsculas e minúsculas do SystemVerilog.

Essa etapa corrigiu a origem dos arquivos, mas não gerou, por si só, uma nova
síntese. Os resultados de cada campanha só comprovam o RTL identificado pelo
commit registrado nos respectivos logs.

### 10. Campanha gate-level anterior à simplificação da FSM (`f71dd2a2`)

Esta é a primeira das duas campanhas usadas para registrar a simplificação da
FSM. Os resultados são históricos e pertencem aos commits e às configurações
indicados aqui; não descrevem o estado atual de todas as fontes.

Depois da correção dos nomes SDF, foi executada uma campanha completa no
Paxos. As três sínteses usaram o mesmo commit de RTL (`e112a460`) e os mesmos
scripts locais desta árvore. O commit desta seção (`f71dd2a2`) altera somente o
testbench e a biblioteca de trabalho da anotada; portanto não foi necessário
repetir a síntese lógica. Os valores abaixo são os resultados efetivamente
gerados, não estimativas baseadas na contagem de declarações SystemVerilog.

| Variante             | Células | Área total (um2) | Flip-flops | Slack nominal (ps) | Power total (mW) |
| -------------------- | ------: | ---------------: | ---------: | -----------------: | ---------------: |
| `tcn4-02mac`         |   5.391 |        9.309,779 |      1.111 |                235 |         0,620796 |
| `stream4/tcn4-04mac` |   8.325 |       12.083,943 |      1.027 |                240 |         0,653916 |
| `stream4/tcn4-08mac` |  11.628 |       16.780,670 |      1.025 |                242 |         0,839179 |

O slack é positivo no view nominal de 2 ns (`analysis_view_0p90v_25c_captyp_nominal`).
O power foi calculado pelo Joules a partir do `dut.shm` da simulação anotada,
com o resultado consolidado em `power_evaluation.txt`. A tabela abaixo registra
a mesma campanha gate-level, agora compilada em bibliotecas Xcelium novas
(`work_gate_final`) e sem os módulos comportamentais `Conv` da lista RTL:

| Variante             | SDF errors | SDF warnings | Inverse tiles | Ciclos totais | Ciclos ativos | Escritas válidas |
| -------------------- | ---------: | -----------: | ------------: | ------------: | ------------: | ---------------: |
| `tcn4-02mac`         |          0 |        1.194 |         2.025 |        37.850 |        20.250 |            8.100 |
| `stream4/tcn4-04mac` |          0 |        1.107 |         2.025 |        29.750 |        12.150 |            8.100 |
| `stream4/tcn4-08mac` |          0 |        1.108 |         2.025 |        25.700 |         8.100 |            8.100 |

O Xcelium reportou warnings `SDFINF` de instâncias sem atraso anotável (por
exemplo, células removidas ou reescritas pelo Genus), mas nenhum erro de SDF.
Os warnings não invalidam a equivalência funcional, mas significam que nem
todo atraso individual foi associado a uma instância homônima no netlist.
O uso de uma biblioteca de trabalho nova e a ausência do RTL comportamental
eliminam a contaminação por módulos compilados de rodadas anteriores. A
execução de 2 MACs agora mostra 20.250 ciclos ativos, em vez dos 12.150 da
rodada contaminada, confirmando que cada netlist está sendo simulado de forma
independente.

Os caminhos citados nos logs pertencem ao layout daquela campanha e não devem
ser interpretados como o inventário atual. Desde então, as fontes m04 foram
movidas para `archive/m04/`, e a variante de 2 MACs foi removida. Portanto,
estes números servem para comparar aquela campanha com a campanha seguinte,
não para afirmar quais configurações estão ativas hoje.

### 11. Campanha seguinte: simplificação da FSM

Depois da campanha anterior, as variantes stream simplificaram a FSM para
refletir o caminho real do datapath. Naquela revisão, os arquivos fixos
`conv-i16-h16-t00-o4-m04-stream00.sv` e
`conv-i16-h16-t00-o4-m08-stream00.sv` passaram a usar somente os estados
necessários. A variante de 2 MACs mostrada na campanha anterior já não é uma
configuração suportada.

#### 11.1 Motivo arquitetural

`Transform` continua sendo um módulo combinacional necessário: a matriz C
inteira fica disponível em `w_conv_transform` enquanto cada ciclo seleciona a
faixa de produtos correspondente. O estado FSM `TRANSFORM`, porém, não
executava a matriz; ele apenas inseria um ciclo para inicializar acumuladores e
índices. Essa inicialização foi movida para `w_hadamard_start`, detectado na
transição em que a entrada termina e o primeiro ciclo HADAMARD começa.

O estado FSM `INVERSE` também não executava uma inversa completa. O último
ciclo HADAMARD já calcula `w_output_acc_next`, grava `r_output_write` e pode
gerar o término da janela. O novo sinal `w_hadamard_last` substitui o antigo
salto para `INVERSE` e aciona `w_conv_end` e `w_conv_input_release` diretamente.
`InverseRow` e `InverseRowAccumulate` permanecem no caminho, pois são as
operações incrementais de A1 e A0 que reduzem a necessidade de registrar a
matriz M x M inteira.

#### 11.2 Mudanças de controle

Antes, a sequência era:

```text
WAIT_CONV -> TRANSFORM -> HADAMARD x N -> INVERSE -> WAIT_CONV
```

Agora ela é:

```text
WAIT_CONV -- w_hadamard_start --> HADAMARD x N -- w_hadamard_last --> WAIT_CONV
```

Nos núcleos mantidos, a enum passou de quatro estados para dois, reduzindo o
registrador de estado de dois bits para um bit. O contador de produtos continua
sendo inicializado antes do primeiro Hadamard, e o último resultado continua
sendo capturado no mesmo ciclo da última acumulação.

#### 11.3 Verificação RTL após a remoção

As duas variantes fixas da tabela passaram pelo mesmo `testbench.sv`, com golden,
contagem de tiles e contagem de escritas:

| Variante                              | Inverse tiles | Ciclos totais | Ciclos ativos | Escritas válidas |
| ------------------------------------- | ------------: | ------------: | ------------: | ---------------: |
| `conv-i16-h16-t00-o4-m04-stream00.sv` |         2.025 |        27.724 |         8.100 |            8.100 |
| `conv-i16-h16-t00-o4-m08-stream00.sv` |         2.025 |        23.674 |         4.050 |            8.100 |

Os resultados mostram a remoção dos dois ciclos de controle por janela sem
alterar os dados: todos os golden checks passaram, não houve escrita fora da
faixa e cada variante manteve 2.025 tiles e 8.100 escritas. A campanha única
de Genus, anotada e Joules foi então executada no Paxos a partir deste RTL.
Os números abaixo substituem os da campanha anterior para esta microarquitetura:

| Variante             | Células | Área total (um2) | Flip-flops | Slack nominal (ps) | Power total (mW) |
| -------------------- | ------: | ---------------: | ---------: | -----------------: | ---------------: |
| `stream4/tcn4-04mac` |   8.473 |       12.127,770 |      1.024 |                243 |         0,684856 |
| `stream4/tcn4-08mac` |  11.818 |       16.855,605 |      1.023 |                206 |         0,918483 |

A anotada final usou os netlists desta mesma campanha e a biblioteca
`work_gate_final`, sem compilar o RTL comportamental junto com o netlist:

| Variante             | SDF errors | SDF warnings | Inverse tiles | Ciclos totais | Ciclos ativos | Escritas válidas |
| -------------------- | ---------: | -----------: | ------------: | ------------: | ------------: | ---------------: |
| `stream4/tcn4-04mac` |          0 |          950 |         2.025 |        27.725 |         8.100 |            8.100 |
| `stream4/tcn4-08mac` |          0 |          866 |         2.025 |        23.675 |         4.050 |            8.100 |

O power foi calculado pelo Joules a partir do `dut.shm` de cada anotada. Os
warnings `SDFINF` continuam sendo informativos: não houve erro de anotação,
mas algumas células não possuem atraso individual associável após a
otimização do Genus. A redução do estado da convolução também aparece no
relatório: foram sintetizados 1.024 e 1.023 flip-flops nos cores mantidos de 4
e 8 MACs, respectivamente.

### 12. Comparativo geral das variantes Conv2x2

As duas entradas anteriores preservam campanhas históricas ligadas à evolução
da FSM. Esta tabela muda o foco: compara entre si os resultados gate-level
disponíveis para as variantes m08 da linha principal. A potência é a média do
`power_evaluation.txt`; a energia foi calculada para o workload da simulação
anotada. As variantes que hoje só existem em `archive/` são identificadas no
Anexo A e entram no relatório agregado apenas com `--include-archived`.

| Variante                                | Fonte                                                                  | Anotada | Células | Área total (um2) | Ciclos | Power (mW) | Energia (nJ) |
| --------------------------------------- | ---------------------------------------------------------------------- | :-----: | ------: | ---------------: | -----: | ---------: | -----------: |
| Conv std 8 MACs                         | `conv-i16-h16-t16-o4-m08-std.sv`                                       |  PASS   |   8.874 |       15.675,268 | 23.675 |   0,863333 |      204,416 |
| Stream08 8 MACs                         | `conv-i16-h16-t08-o4-m08-stream08.sv`                                  |  PASS   |  10.254 |       15.660,389 | 25.699 |   0,664592 |      170,810 |
| Stream04 8 MACs                         | `conv-i16-h16-t04-o4-m08-stream04.sv`                                  |  PASS   |  10.338 |       15.755,807 | 23.675 |   0,758305 |      179,540 |
| Stream00 8 MACs                         | `conv-i16-h16-t00-o4-m08-stream00.sv`                                  |  PASS   |  11.818 |       16.855,605 | 23.675 |   0,918483 |      217,465 |
| Conv all 16 MACs                        | `conv-i16-h16-t00-o4-m16-all.sv`                                       |  PASS   |  15.200 |       23.129,636 | 23.672 |   0,650788 |      154,071 |
| Stream08 wstream4 8 MACs                | `conv-i16-h13-t08-o4-m08-stream08-wstream4.sv`                         |  PASS   |  11.778 |       18.673,687 | 25.654 |   0,672691 |      172,589 |
| Stream08 rowconst4 8 MACs               | `conv-i16-h13-t08-o4-m08-stream08-rowconst4.sv`                        |  PASS   |  11.959 |       18.885,876 | 25.654 |   0,671548 |      172,294 |
| Prefetch4 8 MACs                        | `conv-i20-h16-t08-o4-m08-stream08-prefetch4.sv`                        |  PASS   |  10.506 |       16.073,141 | 21.919 |   0,776661 |      170,256 |
| Prefetch4 rowconst4 8 MACs              | `conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4.sv`              |  PASS   |  12.222 |       19.311,310 | 21.892 |   0,776556 |      170,023 |
| Prefetch4 rowconst4 latch-single 8 MACs | `conv-i20-h13-t08-o4-m08-stream08-prefetch4-rowconst4-latch-single.sv` |  PASS   |  12.372 |       19.019,773 | 27.688 |   0,641520 |      177,624 |

#### 12.1 Leitura dos resultados

- A sequência de redução é `std` (72 palavras), `stream08` (48), `stream04`
  (44) e `stream00` (40). Menos palavras, porém, não garantem menor área,
  potência ou latência.
- Entre os baselines de oito MACs, `stream08` tem a menor área total
  (15.660,389 um2) e a menor potência (0,664592 mW). É o melhor compromisso
  PPA desse grupo para continuar a exploração dos pesos, embora não tenha a
  menor latência: são 25.699 ciclos, contra 23.675 em `stream04` e `stream00`.
- O `all` tem potência ligeiramente menor (0,650788 mW) e latência menor
  (23.672 ciclos), mas usa 16 MACs e tem área total bem maior
  (23.129,636 um2); por isso é uma referência paralela, não a base escolhida
  para a série `stream08-*`.
- As variantes seguintes testam os pesos: `stream08-wstream4` tem potência
  de 0,672691 mW; o prefetch reduz a latência para 21.892--21.919 ciclos, mas
  adiciona estado de entrada.
- O `temporal1` preserva os mesmos 21.892 ciclos e o mesmo contrato funcional
  do baseline `prefetch4-rowconst4`, porém a captura temporal de quatro linhas
  aumenta a área para 20.432,097 um2 e a potência para 0,984856 mW. Portanto,
  esta tentativa não é uma vitória de PPA; ela fica documentada como
  experimento arquivado.
- As comparações devem manter separadas fonte HDL, netlist, SDF e anotada. Uma
  linha arquivada só entra no comparativo quando o report é gerado com
  `--include-archived`.

Os artefatos canônicos ficam em `synthesis/<configuracao>/`. A fonte e os
artefatos completos de `rowconst4-exact` e `temporal1` foram movidos para
`archive/m08/`, sem apagar os resultados. A proveniência do HDL usado pelo
Genus e da simulação anotada permanece nos respectivos `logical/genus.log` e
`sim/xrun.log`.
