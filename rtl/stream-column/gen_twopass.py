#!/usr/bin/env python3
"""Deriva a variante twopass de um RTL rowconst (2026-11-05): troca os HADAMARD_SIZE módulos WeightTransformRowConst
(uma soma de 9 pesos por saída, um módulo por linha) por uma transformada separável em duas passadas.

Passada 1: t[r] = Σ_c a[p][c]·g[c][r] para a linha ativa p (AND-OR por enable). Passada 2: sum[k] = Σ_r a[k][r]·t[r].
a = S1·(matriz de pesos 1D), inteira, com S1² = WEIGHT_SCALE. Sem arredondamento entre as passadas: sum[k] é a mesma soma
inteira do rowconst, então a saída é idêntica bit a bit e o controle não muda (mesma latência, mesmo golden). O mux de
linhas sai junto: w_weight_batch tem só ROWS_PER_CYCLE linhas.

    python rtl/stream-column/gen_twopass.py rtl/conv4x4/conv-wpn16-...-rowconst8-round-column.sv
"""
import math
import pathlib
import re
import sys


def coeffs(text, H):
    """M[p][k][i] = numerador do peso i na saída k da linha p."""
    body = text[text.index("module WeightTransformRowConst"):]
    body = body[:body.index("endmodule")]
    M = [[[0] * 9 for _ in range(H)] for _ in range(H)]
    if "ROW_INDEX ==" in body:
        for p, blk in enumerate(re.split(r"ROW_INDEX == \d+\)", body)[1:]):
            for k, eq in re.findall(r"sum\[(\d+)\] = (.*?);", blk):
                for sign, c, i, j in re.findall(r"([+-]?)\s*(?:\((\d+) \* weight\[(\d+)\]\)|weight\[(\d+)\])", eq):
                    M[p][int(k)][int(i or j)] = (-1 if sign == "-" else 1) * int(c or 1)
        return M, None
    S = int(re.search(r"WEIGHT_SCALE = (\d+);", body).group(1))
    QD = [int(v) for v in re.search(r"QD \[.*?'\{(.*?)\}", body).group(1).split(",")]
    B = [[int(x) for x in r.split(",")] for r in re.findall(r"'\{\s*(-?\d+,\s*-?\d+,\s*-?\d+)\}", body)]
    assert len(B) == H and len(QD) == H
    for p in range(H):
        for k in range(H):
            for c in range(3):
                for r in range(3):
                    M[p][k][c * 3 + r] = S // (QD[p] * QD[k]) * B[p][c] * B[k][r]
    return M, None


def factor(M, H):
    """a (H × 3) com M[p][k][3c + r] = a[p][c]·a[k][r] (posto 1, conferido)."""
    a = [[0] * 3 for _ in range(H)]
    for p in range(H):
        for c in range(3):
            d = M[p][p][c * 3 + c]
            assert d >= 0 and math.isqrt(d) ** 2 == d, (p, c, d)
            a[p][c] = math.isqrt(d)
    # sinais: fixa a primeira entrada não nula de a[0] e propaga pelas razões
    p0, c0 = next((p, c) for p in range(H) for c in range(3) if a[p][c])
    for k in range(H):
        for r in range(3):
            v = M[p0][k][c0 * 3 + r]
            assert abs(v) == a[p0][c0] * a[k][r], (k, r)
            a[k][r] = v // a[p0][c0]
    for p in range(H):
        for k in range(H):
            for c in range(3):
                for r in range(3):
                    assert M[p][k][c * 3 + r] == a[p][c] * a[k][r], (p, k, c, r)
    return a


def module(a, H, guard, scale, shift):
    def expr(row, name):
        t = [f"({v} * {name(i)})" for i, v in enumerate(row) if v]
        return " + ".join(t) if t else "'0"
    L = [f"""// -----------------------------------------------------------------------------
// Two-pass separable weight transform (derived by rtl/stream-column/gen_twopass.py).
// Pass 1 applies the active row to the columns of the raw kernel, pass 2 applies
// all rows to that result. Both passes stay exact, so the single rounding below
// gives the same bits as the row-constant transform.
// -----------------------------------------------------------------------------
(* use_dsp = "no" *)
module WeightTransformTwoPass #(
    parameter int NBITS = 20,
    parameter int WEIGHT_FRAC_BITS = 0,
    parameter int GROUP = 0,
    parameter int GROUPS = 1,
    parameter bit ROUND = 1'b0
  ) (
    input  logic signed [NBITS-1:0] pin [8:0],
    input  logic [{H-1}:0]              enable,
    output logic        [NBITS+WEIGHT_FRAC_BITS-1:0] pout [{H-1}:0]
  );
  timeunit 1ns;
  timeprecision 1ps;

  localparam int TRANSFORM_WIDTH = NBITS + {guard} + WEIGHT_FRAC_BITS;
  localparam logic signed [TRANSFORM_WIDTH-1:0] WEIGHT_ROUND_BIAS =
      ROUND ? ({scale} / 2) : '0;

  logic signed [TRANSFORM_WIDTH-1:0] weight [0:8];
  logic signed [TRANSFORM_WIDTH-1:0] t [0:2];
  logic signed [TRANSFORM_WIDTH-1:0] sum [0:{H-1}];
  logic signed [TRANSFORM_WIDTH-1:0] scaled [0:{H-1}];

  always_comb begin: WEIGHT_TRANSFORM_TWO_PASS_BLOCK
    for (int unsigned k = 0; k < 9; k++)
      weight[k] = {{{{(TRANSFORM_WIDTH-NBITS){{pin[k][NBITS-1]}}}}, pin[k]}};
    for (int unsigned r = 0; r < 3; r++)
      t[r] = '0;"""]
    for p in range(H):
        L.append(f"    if (({p} % GROUPS) == GROUP && enable[{p}]) begin")
        for r in range(3):
            L.append(f"      t[{r}] = t[{r}] | ({expr(a[p], lambda c: f'weight[{c*3+r}]')});")
        L.append("    end")
    for k in range(H):
        L.append(f"    sum[{k}] = {expr(a[k], lambda r: f't[{r}]')};")
    L.append(f"""    for (int unsigned k = 0; k < {H}; k++) begin
      scaled[k] = (sum[k] <<< WEIGHT_FRAC_BITS) + WEIGHT_ROUND_BIAS;
      pout[k] = scaled[k] >>> {shift};
    end
  end
endmodule
""")
    return "\n".join(L)


def main():
    src = pathlib.Path(sys.argv[1])
    text = src.read_text()
    H = int(re.search(r"parameter int unsigned HADAMARD_SIZE\s*=\s*(\d+)", text).group(1))
    M, _ = coeffs(text, H)
    a = factor(M, H)
    body = text[text.index("module WeightTransformRowConst"):]
    guard = int(re.search(r"TRANSFORM_WIDTH = NBITS \+ (\d+)", body).group(1))
    scale = int(re.search(r"WEIGHT_SCALE = (\d+);", body).group(1))
    shift = int(re.search(r"WEIGHT_SHIFT = (\d+);", body).group(1))
    assert max(abs(v) for r in a for v in r) ** 2 <= scale
    print(src.name, "a =", a)

    # módulo antigo, com o comentário que o precede, sai; o novo entra no lugar
    head_end = text.rindex("// ----", 0, text.rindex("// ----", 0, text.index("module WeightTransformRowConst")))
    tail = text.index("endmodule", text.index("module WeightTransformRowConst")) + len("endmodule\n")
    out = text[:head_end] + module(a, H, guard, scale, shift) + text[tail:]

    out, n = re.subn(r"logic \[WEIGHT_NBITS-1:0\] w_weight_row \[HADAMARD_SIZE-1:0\]\[HADAMARD_SIZE-1:0\];",
                     "logic [WEIGHT_NBITS-1:0] w_weight_batch [ROWS_PER_CYCLE-1:0][HADAMARD_SIZE-1:0];", out)
    assert n == 1
    out, n = re.subn(r"w_weight_row\[lane / HADAMARD_SIZE\]\[lane % HADAMARD_SIZE\]",
                     "w_weight_batch[lane / HADAMARD_SIZE][lane % HADAMARD_SIZE]", out)
    assert n == 1
    out, n = re.subn(r"w_weight_row\[\(\(int'\(r_conv_multiply_count\) \+ 1\) \* ROWS_PER_CYCLE\) \+\s*"
                     r"\(lane / HADAMARD_SIZE\)\]\[lane % HADAMARD_SIZE\]",
                     "w_weight_batch[lane / HADAMARD_SIZE][lane % HADAMARD_SIZE]", out)
    assert n == 1, "leitura da próxima linha"
    out, n = re.subn(r"for \(genvar row = 0; row < HADAMARD_SIZE; row\+\+\) begin: WEIGHT_TRANSFORM_ROWS.*?\n  end\n",
                     "for (genvar group = 0; group < ROWS_PER_CYCLE; group++) begin: WEIGHT_TRANSFORM_ROWS\n"
                     "    WeightTransformTwoPass #(.NBITS(NBITS), .WEIGHT_FRAC_BITS(WEIGHT_FRAC_BITS),\n"
                     "                             .GROUP(group), .GROUPS(ROWS_PER_CYCLE), .ROUND(ROUND)) weight_trf (\n"
                     "      .pin(r_weight_spatial), .enable(w_weight_row_enable), .pout(w_weight_batch[group]));\n"
                     "  end\n", out, flags=re.S)
    assert n == 1
    assert "w_weight_row[" not in out.replace("w_weight_row_enable[", "")
    dst = src.with_name(re.sub(r"(rowconst\d+)-", r"\1-twopass-", src.name, count=1))
    dst.write_text(out)
    print("->", dst)


if __name__ == "__main__":
    main()
