# `tro16`: a identidade do `trn16` com sinais e ordem dos termos escolhidos para baixa atividade

Mesmas matrizes do `trn16` (F(4,3) ternária, 8 produtos), a menos de duas liberdades que não mudam a identidade: a
ordem dos termos (linhas do Hadamard) e os sinais por termo, (A_p, B_p, C_p) -> (a·A_p, a·c·B_p, c·C_p). No RTL, a lane q
recebe a coluna q do tile transformado e a linha p avança a cada ciclo; os sinais e a ordem mudam os bits que trocam entre
operandos consecutivos dos multiplicadores. `sinais_ordem.py` (hub, `frentes/precisao-quantizada/piloto`) escolheu sinais
e ordem por busca local sobre a atividade com os dados reais e escreveu `identidade.json` (verificada em frações).

Para que serve: isolar o termo de energia do modelo de custo. Os coeficientes das transformadas são os mesmos (a menos
de sinal), então a área deve mudar pouco e a potência dos multiplicadores deve cair.

## Previsão (registrada em 2026-11-08, antes da síntese)

Duas passadas, carga real `cin16-cout16-l10c1`, contra o `trn16` (22.037 µm², 125,6 pJ/saída, multiplicadores 0,991 mW):

| | `trn16` | `tro16` previsto |
|---|---|---|
| V·U (atividade dos operandos) | 26,3 | 15,2 (−42%) |
| potência dos multiplicadores | 0,991 mW | 0,572 mW (−0,419) |
| transformada de entrada | 98 operadores | 84 (−529 µm²: menos negações) |
| transformada de pesos | 24 operadores | 28 (+173 µm²) |
| área total | 22.037 µm² | cerca de 21,7 mil (−1,6%) |
| energia por saída | 125,6 pJ | cerca de 111 pJ (−12%) |

O V·U previu a potência dos multiplicadores com diferenças de até 12% (`bsc16`/`trn16`); aqui a diferença é de 42%, fora da
faixa calibrada. Critério: se a potência dos multiplicadores cair pelo menos metade do previsto (−0,21 mW), o mecanismo
está confirmado; se cair menos, o modelo de atividade não extrapola.

## Como foi gerado (2026-11-08)

`gera.sh` (na raiz do repositório, no tmux): os passos do `trn16` (`reproduz.sh`) com `identidade.json`
(`from_result.py` com o molde do `trn16`, `fast-conv`, `gen_stream_column.py` e `derive_rtl.py` sobre o RTL do
`wpn16`, `gen_twopass.py`, `derive_configs.sh`, golden da carga real).
`identidade.json`: `sinais_ordem.py --rtl trn16 --json-output <aqui>` (venv do piloto). Fluxo:
`bash -l scripts/run_flow_list.sh rtl/conv4x4/data/tro16/flow.list <logs>` (só as duas configs da carga real).

## Resultado (2026-11-08)

As duas configs passaram na simulação RTL, no fluxo ASIC (folga ≥ 0) e na simulação de portas. Tabelas no hub:
`frentes/precisao-quantizada/piloto/teste_sinais.md` (`teste_sinais.py`, potência por bloco de `potencia_hier/tro-two.txt`)
e `duas_passadas.md`. Duas passadas, carga real:

| | `trn16` | `tro16` previsto | `tro16` medido |
|---|---|---|---|
| área total (µm²) | 22.037 | cerca de 21,7 mil | 22.133 (+0,4%) |
| transformada de entrada (µm²) | 3.972 | 3.443 | 3.628 |
| transformada de pesos (µm²) | 883 | 1.056 | 1.089 |
| multiplicadores (mW) | 0,991 | 0,572 | 0,885 (−0,106) |
| inversa (mW) | 0,383 | igual | 0,493 (+0,109) |
| energia por saída (pJ) | 125,6 | cerca de 111 (−12%) | 125,2 (−0,3%) |
| rowconst: área, energia | 26.428, 128,2 | — | 26.634, 126,6 |

**A previsão falhou.** O V·U caiu 42%, mas a potência dos multiplicadores caiu só 11% (−0,106 mW, metade do critério de
−0,21 mW). A inversa subiu 0,109 mW e anulou o ganho: a energia por saída ficou igual. O V·U ordenou bem RTLs com
diferenças de até 12%, mas não extrapola para uma reescrita feita para minimizá-lo. Dois indicadores calculados depois
não explicam a alta da inversa: as trocas de bit dos produtos caem (8,04 → 7,38) e as das somas parciais da inversa
ficam iguais (3,03 → 3,05). A causa está em aberto. Sinais e ordem dos termos não são um ganho de energia com este
controle.
