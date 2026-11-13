# `trn16`: F(4,3) ternária de 8 produtos

Pesos, entrada e saída usam só -1, 0 e 1, com escala 1. A identidade vem de
`winograd-identities/results/searches/evencost-20261104/F4-3-bit-shift-8.result.json` (custo 340). Resultados em
`frentes/precisao-quantizada/piloto/subexpression.md`, no hub.

## Mapeamento das matrizes

| Busca | `make_custom_build.py` | Papel |
|---|---|---|
| `C` | `C` | entrada |
| `A` | `B` | pesos |
| `B` | `A` | saída |

O fator de cada produto é 1 (`Q`). Em `make_custom_build.py` a identidade fica escrita por extenso.

## Como foi gerado

O `fast-conv` não tem gerador para matrizes arbitrárias, e `gen_stream_column.py` não gera a variante round. Por isso:

1. `fast-conv init 2d -o 4 -w 3`, `fast-conv quant shift -b 8` e `make_custom_build.py` escrevem `config/`, `sv/` e `clib/`.
2. `fast-conv -p . build 2d bind nest` gera o CSA. O CLI só aceita geradores conhecidos, então `config/gen.json` passa por
   `tolimlin_4x3` nesse comando e depois volta a `manual_ternary_f4_3`.
3. `sv/` é copiado para `mult-matrices/trn16`, `mux-mult/trn16` e `pack-param/trn16`.
4. `gen_stream_column.py data/trn16/config/build.json trn16 <saída> 8 4` gera o RTL, e `derive_rtl.py` transplanta a parte
   da identidade no RTL round do `wpn16`.
5. `gen_subexpression.py` deriva a versão subexpression.
6. `derive_configs.sh` cria as 4 configs a partir das configs `wpn16`.
7. Goldens: `fast-conv -p . sim normal --image-side 32 -i 3 -o 12 -d 0 --truncated-weight-transform --rounding nearest
   --weight-frac-bits 0 --extra-frac-bits 0 --nbits 16`, com a pasta `sim/sim` renomeada para
   `sim/sim-032-3-12-normal-trunc-frac0-extra0-round-nbits16`, e `gen_real_workload.py --alg trn16 --nbits 16 --cin 16
   --cout 16`, no hub.
8. `bash -l scripts/run_flow_list.sh rtl/conv4x4/data/trn16/flow.list <pasta de logs>`, no tmux.

## Conferência

`reproduz.sh` refaz os passos 1, 2, 4, 5, 6 e 7 e compara com o versionado, sem ferramentas EDA:

```bash
bash rtl/conv4x4/data/trn16/reproduz.sh   # na raiz do repositório, dentro do tmux; termina com FALHAS: 0
```

## Vazão e camadas da ResNet-18 (2026-11-07)

14 configs rowconst-round a mais, para pôr o `trn16` nas varreduras de vazão e de camadas do hub
(`frentes/precisao-quantizada/piloto`, seções "Vazão máxima e memória" e "Camadas da ResNet-18"):

- `NUM_MULT` = 16 e 32 (`-mult16`, `-mult32`) em `cin16-cout16-l10c1`;
- 1, 2 e 4 lotes nas camadas layer1.0.conv1, layer2.1.conv1, layer3.1.conv1 e layer4.1.conv1, no mapa inteiro
  (sufixos `-l10c1-s42`, `-l21c1-s22`, `-l31c1-s12`, `-l41c1-s7`).

Como foi gerado:

1. Goldens: `gen_real_workload.py --alg trn16 --nbits 16 --layer <camada> --side 0` (hub, Python do `fast-convolution-rtl`)
   para as 4 camadas: `sim/sim-042-…-l10c1-…`, `sim-022-…-l21c1-…`, `sim-012-…-l31c1-…`, `sim-007-…-l41c1-…`.
2. Configs: `prep_camadas.py` (hub, venv do piloto), que copia a config `cin16-cout16-l10c1` e troca `NUM_MULT` e a carga.
3. `bash -l scripts/run_flow_list.sh` sobre `flow-vazao-camadas.list`, dividida em duas listas de linhas alternadas e
   rodada em duas sessões tmux em paralelo (`fastconv-flow-trn16-vazao-{a,b}-20261107`).

Resultado: as 14 passaram na simulação RTL, com folga ≥ 0 e na simulação de portas. Comparação com WP e bit-shift-ternary em
`trn_vazao.md` (hub, `trn_vazao.py`): com o mesmo número de multiplicadores e a mesma vazão que o WP, 11% a 13% menos área
lógica e de 5% a 20% menos energia lógica por saída.
