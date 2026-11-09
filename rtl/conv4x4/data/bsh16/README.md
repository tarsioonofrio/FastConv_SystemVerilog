# `bsh16`: F(4,3) bit-shift de 7 produtos escolhida pelo custo calibrado

Mesma forma do `bsn16` e do `bsc16` (7 produtos, pesos com fatores 1, 1/2 e 1/4, entrada e saída em -1, 0, 1), com a
identidade de menor custo calibrado na síntese achada pela campanha `hw-20261107` do `winograd-identities`:
`results/searches/hw-20261107/F4-3-bs-hw7.result.json` (`--objective hw`, 4 h, 3 workers; custo 12.658 contra 13.644 da
identidade do `bsn16`; limite inferior 8.395, então não está provada mínima). Não zeros de A (pesos), B (saída) e C
(entrada): 14, 20, 20 (`bsn16` 14, 18, 22; `bsc16` 15, 18, 20).

Para que serve: é o teste fora da amostra do modelo de custo do hub (`frentes/precisao-quantizada/piloto/custo_calibra.md`).
O modelo foi calibrado nos 7 RTLs já sintetizados; esta identidade foi escolhida por ele antes de existir RTL.

## Previsão (registrada em 2026-11-08, antes da síntese)

Versão de duas passadas, carga real `cin16-cout16-l10c1`, contra o `bsn16` (29.289 µm², 127,5 pJ/saída) e o `bsc16`
(28.947 µm², 131,4 pJ/saída). `custo_candidatos.md` no hub:

| | `bsn16` | `bsc16` | `bsh16` |
|---|---|---|---|
| transformada de entrada prevista (µm²) | 7.371 | 6.388 | 6.388 |
| transformada de pesos prevista (µm²) | 1.658 | 1.848 | 1.658 |
| atividade dos multiplicadores (V·U) | 25,6 | 28,6 | 26,7 |
| erro na carga real | 0,0131 | 0,0129 | 0,0133 |

- **Área:** a do `bsn16` menos 983 µm² pelo modelo bruto (28,3 mil, −3,4%). O modelo errou o `bsc16` para mais (previu −793
  e o medido foi −342 nas duas transformadas); corrigindo pelo que o `bsc16` mediu (entrada como a do `bsc16`, pesos como
  os do `bsn16`), cerca de 28,7 mil (−2%). Em qualquer caso, menor que o `bsc16` e o `bsn16`.
- **Energia:** multiplicadores +4,3% sobre o `bsn16` pela atividade (cerca de +0,03 mW) e transformada de entrada menor
  (cerca de −0,05 mW): energia por saída igual à do `bsn16` com folga de ±1% (126 a 129 pJ), abaixo da do `bsc16`.

Se a área sair menor que a dos dois e a energia ficar abaixo da do `bsc16`, o modelo ordenou certo.

## Como foi gerado (2026-11-08)

`gera.sh` (na raiz do repositório, no tmux) faz os passos do `bsc16` com outra identidade:

0. `from_result.py` escreve `make_custom_build.py` a partir do `.result.json`, com o do `bsc16` como molde, e confere a
   identidade em frações. Aplicado ao resultado do `bsc16`, reproduz as matrizes do `make_custom_build.py` dele.
1. `fast-conv init`, `quant shift -b 8`, `make_custom_build.py` e `build 2d bind nest` (com `gen.json` trocado por
   `tolimlin_4x3` durante o comando).
2. `sv/` copiado para `mult-matrices/bsh16`, `mux-mult/bsh16` e `pack-param/bsh16`.
3. `derive_rtl.py` (cópia do `bsc16` com o nome trocado) sobre o RTL rowconst round do `bsn16`; `gen_twopass.py`.
4. `derive_configs.sh`: as 4 configs (rowconst e duas passadas × `cin3-cout12` e `cin16-cout16-l10c1`).
5. Goldens: `fast-conv sim normal` (aleatório) e `gen_real_workload.py --alg bsh16 --nbits 16 --cin 16 --cout 16` (hub).

Depois: `bash -l scripts/run_flow_list.sh rtl/conv4x4/data/bsh16/flow.list <pasta de logs>`, no tmux
(`fastconv-flow-bsh16-20261108`).

Python: o do `fast-convolution-rtl` (`.venv`) nos passos 1 e 5; `frentes/precisao-quantizada/piloto/.venv` no passo 3.

## Resultado (2026-11-08)

As 4 configs passaram na simulação RTL, no fluxo ASIC (folga ≥ 0) e na simulação de portas. Tabelas no hub:
`frentes/precisao-quantizada/piloto/duas_passadas.md` (`duas_passadas.py`) e `teste_bsh16.md` (`teste_bsh16.py`, com a
potência por bloco de `potencia_hier/bsh-two.txt`). Carga real, duas passadas:

| | `bsn16` | `bsc16` | `bsh16` | previsto para o `bsh16` |
|---|---|---|---|---|
| área total (µm²) | 29.289 | 28.947 | **28.432** (−2,9%) | 28,3 a 28,7 mil |
| transformada de entrada (µm²) | 7.906 | 7.326 | 6.891 | −983 sobre o `bsn16`; medido −1.016 |
| transformada de pesos (µm²) | 1.751 | 1.950 | 1.837 | igual ao `bsn16`; medido +86 |
| potência dos multiplicadores (mW) | 0,764 | 0,858 | 0,820 | 0,797 |
| energia por saída (pJ) | 127,5 | 131,4 | **128,8** (+1,0%) | 126 a 129 |
| rowconst: área, energia | 36.208, 127,9 | 36.012, 129,9 | 34.670, 130,1 | — |

O modelo acertou a ordem: o `bsh16` tem a menor área dos três e energia entre a do `bsn16` e a do `bsc16`. A soma das duas
transformadas caiu 929 µm² contra 983 previstos (no `bsc16`, o modelo tinha previsto 785 e o medido foi 382). A potência dos
multiplicadores subiu 7,3% sobre o `bsn16`, contra 4,3% previstos pela atividade. A energia ficou 1% acima da do `bsn16`,
no limite da faixa prevista: a identidade troca área por um pouco de energia, e o `bsn16` continua o bit-shift de menor
energia.

## Dois estados de multiplicação: 25 multiplicadores (2026-11-09)

**Pergunta:** em uma variante de no máximo 2 estados de multiplicação, compensa dividir uma linha do Hadamard entre os estados, com 25 multiplicadores em vez de 28?

**RTL:** `gen_m25.py` gera `conv-bsh16-...-m25-2state-...` a partir do RTL de 7 multiplicadores em duas passadas. O estado 0 faz as linhas 0 a 2 e as colunas 0 a 3 da linha 3;
o estado 1 faz as linhas 4 a 6 e as colunas 4 a 6 da linha 3, e a lane 24 fica parada. Uma pilha de 4 palavras (`r_row3_hold`) guarda a primeira parte da linha 3 até a inversa.

**Fluxo:** `derive_configs_m25.sh` cria as configs; `run_m25.sh` faz a simulação RTL com os defines da síntese (`scripts/rtl_sim_config.sh`, porque `run_flow_list.sh` simula com NUM_MULT = 7, que este RTL rejeita) e o fluxo:

    bash rtl/conv4x4/data/bsh16/derive_configs_m25.sh
    tmux new-session -d -s fastconv-m25-<carga>-20261109 "bash -l rtl/conv4x4/data/bsh16/run_m25.sh rtl/conv4x4/data/bsh16/flow-m25-<carga>.list <logs>"

**Resultado** (tabela no hub, `frentes/precisao-quantizada/piloto/estados_f43.md`): as 4 configs passam na simulação RTL, no fluxo (folga ≥ 0) e na simulação de portas.

| carga | versão | área (µm²) | ciclos | E/saída (pJ) |
|---|---|---|---|---|
| sintética | 7 mult. | 28.390 | 33.096 | 37,1 |
| sintética | 28 mult., 2 estados | 49.580 | 21.576 | 41,4 |
| sintética | 25 mult., 2 estados | 46.403 | 21.576 | 39,7 |
| real | 7 mult. | 28.432 | 235.056 | 128,8 |
| real | 28 mult., 2 estados | 49.566 | 153.136 | 144,2 |
| real | 25 mult., 2 estados | 46.451 | 153.136 | 142,9 |

- 25 contra 28: mesmos ciclos, área −6,3% a −6,4%, energia −0,9% a −3,9%.
- 25 contra 7: 3,57 vezes os multiplicadores e só 1,53 vez a vazão, porque cada tile leva 9,36 ciclos em vez de 14,36. Saem 5 ciclos de multiplicação e ficam 7,36 ciclos por tile que não dependem do número de multiplicadores (leitura, transformada, inversa, escrita).
