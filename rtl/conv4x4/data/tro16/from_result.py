#!/usr/bin/env python3
"""Escreve make_custom_build.py de um F(4,3) bit-shift-ternary a partir de um .result.json do winograd-identities, usando o
make_custom_build.py do bsc16 como molde (troca só as listas C, Q, B, A, o docstring e o nome do gerador).

Mapeamento (convenção da busca: sum_p A[p][i]·B[p][j]·C[k][p] = [k == i+j]):
  C (entrada)        = C da busca;
  Q, B (pesos)       = cada linha de A da busca dividida pelo maior valor absoluto, que vira o fator Q (fração);
  A (saída)          = B da busca.
Confere a identidade em frações (com Q·B no lugar de A) antes de gravar; B e C precisam ser ternárias.

    python from_result.py <F4-3-...result.json> <make_custom_build.py de saída> <nome do gerador> <docstring curto> [molde]

O molde padrão é o make_custom_build.py do bsc16 (bit-shift-ternary); para o ternário, use o do trn16 (mesma estrutura).
"""
import json
import re
import sys
from fractions import Fraction as Fr
from pathlib import Path

MOLDE = Path(__file__).resolve().parent.parent / "bsc16" / "make_custom_build.py"


def lst(M):
    return "[\n" + "".join(f"    {list(r)},\n" for r in M) + "]"


def main(res, out, gen, doc, molde=None):
    m = json.loads(Path(res).read_text())["matrices"]
    A = [[Fr(v) for v in r] for r in m["A"]]
    Bo = [[int(Fr(v)) for v in r] for r in m["B"]]
    C = [[int(Fr(v)) for v in r] for r in m["C"]]
    n = len(A)
    Q, Bw = [], []
    for r in A:
        q = max(abs(v) for v in r)
        row = [v / q for v in r]
        assert all(x in (-1, 0, 1) for x in row), r
        Q.append([q.numerator, q.denominator])
        Bw.append([int(x) for x in row])
    for M in (Bo, C):
        assert all(x in (-1, 0, 1) for r in M for x in r)
    for k in range(len(C)):  # identidade em frações
        for i in range(3):
            for j in range(len(Bo[0])):
                s = sum(Fr(Q[p][0], Q[p][1]) * Bw[p][i] * Bo[p][j] * C[k][p] for p in range(n))
                assert s == (1 if k == i + j else 0), (k, i, j, s)
    t = Path(molde or MOLDE).read_text()
    t = re.sub(r'^"""Materialise.*?\n\n', f'"""{doc}\n\n', t, count=1, flags=re.S | re.M)
    for nome, M in (("C", C), ("Q", Q), ("B", Bw), ("A", Bo)):
        t = re.sub(rf"^{nome} = \[\n.*?^\]", f"{nome} = {lst(M)}", t, count=1, flags=re.S | re.M)
    t = re.sub(r'"generator": "[^"]*"', f'"generator": "{gen}"', t)
    Path(out).write_text(t)
    print(f"ok: {n} produtos, identidade conferida, {out}")


if __name__ == "__main__":
    main(*sys.argv[1:6])
