# `bso16`: a identidade do `bsn16` com sinais e ordem dos termos escolhidos para baixa atividade

Mesmas matrizes do `bsn16` (F(4,3) bit-shift, 7 produtos), a menos de duas liberdades que não mudam a identidade: a
ordem dos termos (linhas do Hadamard) e os sinais por termo, (A_p, B_p, C_p) -> (a·A_p, a·c·B_p, c·C_p). No RTL, a lane q
recebe a coluna q do tile transformado e a linha p avança a cada ciclo; os sinais e a ordem mudam os bits que trocam entre
operandos consecutivos dos multiplicadores. `sinais_ordem.py` (hub, `frentes/precisao-quantizada/piloto`) escolheu sinais
e ordem por busca local sobre a atividade com os dados reais e escreveu `identidade.json` (verificada em frações).

Para que serve: isolar o termo de energia do modelo de custo. Os coeficientes das transformadas são os mesmos (a menos
de sinal), então a área deve mudar pouco e a potência dos multiplicadores deve cair.

## Previsão (registrada em 2026-11-08, antes da síntese)

Duas passadas, carga real `cin16-cout16-l10c1`, contra o `bsn16` (29.289 µm², 127,5 pJ/saída, multiplicadores 0,764 mW):

| | `bsn16` | `bso16` previsto |
|---|---|---|
| V·U (atividade dos operandos) | 25,6 | 18,4 (−28%) |
| potência dos multiplicadores | 0,764 mW | 0,551 mW (−0,213) |
| transformada de entrada | 195 operadores | 208 (+491 µm²: os sinais escolhidos pedem mais negações) |
| transformada de pesos | 35 operadores | 35 |
| área total | 29.289 µm² | cerca de 29,8 mil (+1,7%) |
| energia por saída | 127,5 pJ | cerca de 121 pJ (−5%) |

O V·U previu a potência dos multiplicadores com diferenças de até 12% (`bsc16`/`bsn16`); aqui a diferença é de 28%, fora da
faixa calibrada. Critério: se a potência dos multiplicadores cair pelo menos metade do previsto (−0,11 mW), o mecanismo
está confirmado; se cair menos, o modelo de atividade não extrapola.

## Como foi gerado (2026-11-08)

`gera.sh` (na raiz do repositório, no tmux): os passos do `bsh16` com `identidade.json` no lugar do `.result.json`
(`from_result.py`, `fast-conv`, `derive_rtl.py` sobre o RTL do `bsn16`, `gen_twopass.py`, `derive_configs.sh`, goldens).
`identidade.json`: `sinais_ordem.py --rtl bsn16 --json-output <aqui>` (venv do piloto). Fluxo:
`bash -l scripts/run_flow_list.sh rtl/conv4x4/data/bso16/flow.list <logs>` (só as duas configs da carga real).

## Resultado (2026-11-08)

As duas configs passaram na simulação RTL, no fluxo ASIC (folga ≥ 0) e na simulação de portas. Tabelas no hub:
`frentes/precisao-quantizada/piloto/teste_sinais.md` (`teste_sinais.py`, potência por bloco de `potencia_hier/bso-two.txt`)
e `duas_passadas.md`. Duas passadas, carga real:

| | `bsn16` | `bso16` previsto | `bso16` medido |
|---|---|---|---|
| área total (µm²) | 29.289 | cerca de 29,8 mil | 30.083 (+2,7%) |
| multiplicadores (mW) | 0,764 | 0,551 | 0,677 (−0,087) |
| inversa (mW) | 0,525 | igual | 0,690 (+0,166) |
| energia por saída (pJ) | 127,5 | cerca de 121 (−5%) | 130,3 (+2,2%) |
| rowconst: área, energia | 36.208, 127,9 | — | 36.353, 132,8 |

**A previsão falhou.** A potência dos multiplicadores caiu 0,087 mW, menos que o critério (−0,11 mW). A inversa, que o
modelo não via, subiu 0,166 mW. A energia por saída subiu 2,2%. Ver o README do `tro16`, que teve o mesmo resultado, e a
seção do piloto no hub.
