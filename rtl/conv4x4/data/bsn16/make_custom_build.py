#!/usr/bin/env python3
"""Materialise the bsn16 F(4,3) build from explicit matrices.

The upstream CLI has no constructor for arbitrary (C, q, B, A) matrices, so
this helper performs only the constructor-side work that ``build 2d
<generator>`` would normally do: write ``config/build.json``, the LaTeX
decomposition, the C headers and ``sv/pack_param.sv``.  The subsequent
``fast-conv build 2d bind nest`` step is run through the unmodified CLI.
"""
from __future__ import annotations

import json
from pathlib import Path

import sympy as sy

from fast_convolution.build import build2d
from fast_convolution.config import header_init, read_init
from fast_convolution.repo import Repo

C = [
    [1, 0, 0, 0, 0, 0, 0],
    [0, 1, -1, -1, 1, -1, -1],
    [0, 1, 1, -1, 0, 1, 0],
    [0, 1, -1, 1, -1, 1, 0],
    [-1, 1, 1, 1, 0, -1, 0],
    [0, 0, 0, 0, 0, 0, 1],
]
Q = [[1, 1], [1, 4], [1, 4], [1, 2], [1, 2], [1, 2], [1, 1]]
B = [
    [1, 0, 0],
    [1, 1, 1],
    [1, -1, 1],
    [1, 0, -1],
    [1, 1, -1],
    [0, 1, 0],
    [0, 0, 1],
]
A = [
    [1, 0, 0, 0],
    [1, 1, 1, 1],
    [1, -1, 1, -1],
    [1, 0, -1, 0],
    [1, 1, -1, -1],
    [0, 1, 0, -1],
    [0, 0, 0, 1],
]


def main() -> None:
    repo = Repo(Path(__file__).resolve().parent)
    dim, c_len, b_len, a_len = read_init(repo)
    if (dim, c_len, b_len, a_len) != (2, [6, 6], [3, 3], [4, 4]):
        raise SystemExit("run `fast-conv init 2d -o 4 -w 3` first")

    q = sy.Matrix([sy.Rational(num, den) for num, den in Q])
    build2d(
        repo,
        [1],
        [1],
        sy.Matrix(A),
        sy.Matrix(B),
        sy.Matrix(C),
        q,
        sy.Matrix(A),
        sy.Matrix(B),
        sy.Matrix(C),
        q,
        b_len,
        c_len,
    )
    header_init(repo, dim, a_len[0], b_len[0], c_len[0], len(Q))
    with open(repo.file_gen, "w", encoding="utf-8") as handle:
        json.dump({"generator": "manual_bitshift_f4_3"}, handle, indent=4)


if __name__ == "__main__":
    main()
