# `bsc16`: F(4,3) bit-shift-ternary de 7 produtos, custo 458

Mesma forma do `bsn16` (7 produtos, pesos com fatores 1, 1/2 e 1/4, entrada e saída em -1, 0, 1), com a identidade de menor
custo de transformadas achada pela campanha `reducao-20261105` do `winograd-identities`:
`results/searches/reducao-20261105/F4-3-bs-cost7.result.json`. Custo (N+P)·nnz(C) + (P+m)·nnz(B) = 458, contra 484 do
`bsn16`; a transformada de entrada tem 20 não zeros (22 no `bsn16`).

## Mapeamento das matrizes

| Busca | `make_custom_build.py` | Papel |
|---|---|---|
| `C` | `C` | entrada |
| `A` = `Q`·`B` | `Q`, `B` | pesos (cada linha de `A` dividida pelo maior valor absoluto, que vira o fator `Q`) |
| `B` | `A` | saída |

`make_custom_build.py` foi gerado a partir do `.result.json` e confere a identidade em frações antes de gravar.

## Como foi gerado (2026-11-07)

1. Em `data/bsc16`: `fast-conv init 2d -o 4 -w 3`, `fast-conv quant shift -b 8` e `python make_custom_build.py`.
2. `fast-conv -p . build 2d bind nest`, com `config/gen.json` trocado por `tolimlin_4x3` durante o comando (o CLI só aceita
   geradores conhecidos) e restaurado depois. O mesmo procedimento com o `make_custom_build.py` do `bsn16` reproduz o
   `sv/` versionado do `bsn16` byte a byte.
3. `sv/` copiado para `mult-matrices/bsc16`, `mux-mult/bsc16` e `pack-param/bsc16`.
4. `derive_rtl.py <RTL rowconst7 round do bsn16> make_custom_build.py <destino>`: troca as tabelas QN, QD, B e A e o nome.
   Aplicado à identidade do `bsn16`, reproduz o RTL do `bsn16`.
5. `rtl/stream-column/gen_subexpression.py` deriva a versão subexpression.
6. `derive_configs.sh` cria as 4 configs (rowconst e subexpression × `cin3-cout12` e `cin16-cout16-l10c1`) a partir das
   configs `bsn16`.
7. Goldens: `fast-conv -p . sim normal --image-side 32 -i 3 -o 12 -d 0 --truncated-weight-transform --rounding nearest
   --weight-frac-bits 0 --extra-frac-bits 0 --nbits 16`, com `sim/sim` renomeada para
   `sim/sim-032-3-12-normal-trunc-frac0-extra0-round-nbits16`, e `gen_real_workload.py --alg bsc16 --nbits 16 --cin 16
   --cout 16` (hub, `frentes/precisao-quantizada/piloto`).
8. `bash -l scripts/run_flow_list.sh rtl/conv4x4/data/bsc16/flow.list <pasta de logs>`, no tmux
   (`fastconv-flow-bsc16-20261107`). As 4 simulações RTL passaram antes do fluxo ASIC.

Python: o do `fast-convolution-rtl` (`.venv`) nos passos 1, 2 e 7; `frentes/precisao-quantizada/piloto/.venv` nos passos
4 e 5.

## Resultado (2026-11-07)

As 4 configs passaram na simulação de portas, com folga ≥ 0. Tabela completa em
`frentes/precisao-quantizada/piloto/subexpression.md`, no hub, gerada por `subexpression.py`. Na carga real (ResNet-18,
16 x 16 canais, 16 bits):

| Versão | `bsn16` (custo 484) | `bsc16` (custo 458) |
|---|---|---|
| rowconst: área, energia por saída | 36.208 µm², 127,9 pJ | 36.012 µm², 129,9 pJ |
| subexpression: área, energia por saída | 29.289 µm², 127,5 pJ | 28.947 µm², 131,4 pJ |
| transformada de entrada (`trf`), subexpression | 7.906 µm² | 7.326 µm² |
| transformada de pesos, subexpression | 1.751 µm² | 1.950 µm² |
| erro relativo (`erro_carga_real.py`) | 0,0131 | 0,0129 |

O custo 458 mede só as transformadas de entrada e saída. A de entrada encolheu 7%, mas a de pesos cresceu, porque a nova
identidade tem mais não zeros nos pesos. No total, a área cai 1% e a energia sobe de 2% a 3%.
