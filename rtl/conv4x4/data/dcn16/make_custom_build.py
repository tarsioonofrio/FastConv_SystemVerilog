#!/usr/bin/env python3
"""Materialise the dcn16 F(4,3) build artifacts from ``config/build.json``.

This is the dcn16 adaptation of ``../bsn16/make_custom_build.py``.  The dcn16
matrices already live in the canonical ``config/build.json``, so this helper
reuses them instead of duplicating a second copy in Python.  It performs only
the constructor-side work that ``fast-conv build 2d <generator>`` normally
does: the LaTeX decomposition, the C headers and ``sv/pack_param.sv``.  The
subsequent ``fast-conv build 2d bind nest`` step is run through the unmodified
CLI.

``config/build.json`` and ``config/gen.json`` are intentionally not replaced:
the dcn16 generator description is custom and must survive the build.
"""
from __future__ import annotations

import json
from pathlib import Path

import sympy as sy

from fast_convolution.build import build2d
from fast_convolution.config import header_init, read_init
from fast_convolution.repo import Repo


def _axis(data, key, index):
    return sy.Matrix(data[key][index])


def main() -> None:
    repo = Repo(Path(__file__).resolve().parent)
    dim, c_len, b_len, a_len = read_init(repo)
    if (dim, c_len, b_len, a_len) != (2, [6, 6], [3, 3], [4, 4]):
        raise SystemExit("dcn16 expects init.json with C=6x6, B=3x3, A=4x4")

    data = json.loads(repo.file_build.read_text())
    c1, c2 = _axis(data, "c", 0), _axis(data, "c", 1)
    b1, b2 = _axis(data, "b", 0), _axis(data, "b", 1)
    a1, a2 = _axis(data, "a", 0), _axis(data, "a", 1)
    q1 = sy.Matrix([sy.Rational(p, q) for p, q in data["q"][0]])
    q2 = sy.Matrix([sy.Rational(p, q) for p, q in data["q"][1]])
    p1, p2 = data["p"][0], data["p"][1]

    build2d(
        repo,
        p2,
        p1,
        a1,
        b1,
        c1,
        q1,
        a2,
        b2,
        c2,
        q2,
        b_len,
        c_len,
    )
    header_init(repo, dim, a_len[0], b_len[0], c_len[0], len(q1))


if __name__ == "__main__":
    main()
