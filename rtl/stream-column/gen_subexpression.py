#!/usr/bin/env python3
"""Deriva a variante subexpression de um RTL rowconst (2026-11-05): troca os HADAMARD_SIZE módulos WeightTransformRowConst
(uma soma de 9 pesos por saída, um módulo por linha) por uma transformada separável (subexpression).

Passada 1: t[r] = Σ_c a[p][c]·g[c][r] para a linha ativa p (AND-OR por enable). Passada 2: sum[k] = Σ_r a[k][r]·t[r].
a = S1·(matriz de pesos 1D), inteira, com S1² = WEIGHT_SCALE. Sem arredondamento entre as passadas: sum[k] é a mesma soma
inteira do rowconst, então a saída é idêntica bit a bit e o controle não muda (mesma latência, mesmo golden). O mux de
linhas sai junto: w_weight_batch tem só ROWS_PER_CYCLE linhas.

Toom-Cook (WEIGHT_SCALE = 576, sem deslocamento): a divisão fica depois da passada 2, uma por saída em vez de uma por
saída de cada linha. ``--magic`` troca o operador / por recíproco exato: floor(x/576) = floor((x >> 6)/9), com y = (x >> 6)
+ 9·2^K ≥ 0, K = NBITS + F − 1, e floor(y·M / 2^s), M = (2^s − 1)/9 + 1, exato para y < 2^(s−3) (9·M − 2^s = 8); s múltiplo
de 6 (30 ou 36). Como M − 1 = 7·(1 + 2^6 + ... + 2^(s−6)), o produto são poucas somas. ``check_magic`` confere todos os
valores possíveis.

    python rtl/stream-column/gen_subexpression.py [--magic] rtl/conv4x4/conv-wpn16-...-rowconst8-round-column.sv
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


def check_magic(nbits, frac):
    """Compara o recíproco com floor(x/576) para toda soma possível (|sum| <= 576·2^(nbits−1)), com o viés de arredondamento."""
    import numpy as np
    K = nbits + frac - 1
    S = 30 if nbits + frac + 4 <= 27 else 36
    M = (2**S - 1) // 9 + 1
    lim = 576 * 2 ** (nbits - 1)
    step = 1 << 24
    for lo in range(-lim, lim + 1, step):
        s = np.arange(lo, min(lo + step, lim + 1), dtype=np.int64)
        x = s * 2**frac + 288
        y = (x >> 6) + 9 * 2**K
        assert y.min() >= 0 and y.max() < 2 ** (S - 3) and int(y.max()) * M < 2**63
        q = ((y * M) >> S) - 2**K
        assert (q == np.floor_divide(x, 576)).all(), lo


def module(a, H, guard, scale, shift, magic=False):
    def expr(row, name):
        t = [f"({v} * {name(i)})" for i, v in enumerate(row) if v]
        return " + ".join(t) if t else "'0"
    L = [f"""// -----------------------------------------------------------------------------
// Subexpression (separable) weight transform (derived by rtl/stream-column/gen_subexpression.py).
// Pass 1 applies the active row to the columns of the raw kernel, pass 2 applies
// all rows to that result. Both passes stay exact, so the single rounding below
// gives the same bits as the row-constant transform.
// -----------------------------------------------------------------------------
(* use_dsp = "no" *)
module WeightTransformSubexpression #(
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
{{DIV}}
  always_comb begin: WEIGHT_TRANSFORM_SUBEXPRESSION_BLOCK
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
    final = f"pout[k] = scaled[k] >>> {shift};" if shift else "pout[k] = f_div(scaled[k]);"
    L.append(f"""    for (int unsigned k = 0; k < {H}; k++) begin
      scaled[k] = (sum[k] <<< WEIGHT_FRAC_BITS) + WEIGHT_ROUND_BIAS;
      {final}
    end
  end
endmodule
""")
    if shift:
        div = ""
    elif magic:
        div = """
  // Exact floor division by 576 (see gen_subexpression.py): y = (x >> 6) + 9*2^K >= 0, then floor(y*M / 2^S).
  localparam int K = NBITS + WEIGHT_FRAC_BITS - 1;
  localparam int S = (NBITS + WEIGHT_FRAC_BITS + 4 <= 27) ? 30 : 36;
  localparam int PW = K + 5 + S;
  function automatic logic [NBITS+WEIGHT_FRAC_BITS-1:0] f_div(
      input logic signed [TRANSFORM_WIDTH-1:0] value);
    logic signed [TRANSFORM_WIDTH-1:0] shifted;
    logic [PW-1:0] y, y7, a, c, d, e, q;
    begin
      shifted = (value >>> 6) + (TRANSFORM_WIDTH'(9) <<< K);
      y = PW'(unsigned'(shifted[K+4:0]));
      y7 = (y << 3) - y;
      a = y7 + (y7 << 6);
      c = a + (a << 12);
      d = c + (y7 << 24);
      if (S == 36)
        d = d + (y7 << 30);
      e = d + y;
      q = (e >> S) - (PW'(1) << K);
      f_div = q[NBITS+WEIGHT_FRAC_BITS-1:0];
    end
  endfunction
"""
    else:
        div = f"""
  function automatic logic [NBITS+WEIGHT_FRAC_BITS-1:0] f_div(
      input logic signed [TRANSFORM_WIDTH-1:0] value);
    logic signed [TRANSFORM_WIDTH-1:0] quotient;
    begin
      quotient = value / {scale};
      if ((value % {scale}) < 0)
        quotient = quotient - 1;
      f_div = quotient[NBITS+WEIGHT_FRAC_BITS-1:0];
    end
  endfunction
"""
    return "\n".join(L).replace("{DIV}", div)


def main():
    magic = "--magic" in sys.argv
    src = pathlib.Path([v for v in sys.argv[1:] if not v.startswith("--")][0])
    text = src.read_text()
    H = int(re.search(r"parameter int unsigned HADAMARD_SIZE\s*=\s*(\d+)", text).group(1))
    M, _ = coeffs(text, H)
    a = factor(M, H)
    body = text[text.index("module WeightTransformRowConst"):]
    guard = int(re.search(r"TRANSFORM_WIDTH = NBITS \+ (\d+)", body).group(1))
    scale = int(re.search(r"WEIGHT_SCALE = (\d+);", body).group(1))
    m = re.search(r"WEIGHT_SHIFT = (\d+);", body)
    shift = int(m.group(1)) if m else 0
    if magic:
        assert scale == 576 and not shift
        for nbits in (16, 20):
            check_magic(nbits, 6)
        print("recíproco exato conferido")
    assert max(abs(v) for r in a for v in r) ** 2 <= scale
    print(src.name, "a =", a)

    # módulo antigo, com o comentário que o precede, sai; o novo entra no lugar
    head_end = text.rindex("// ----", 0, text.rindex("// ----", 0, text.index("module WeightTransformRowConst")))
    tail = text.index("endmodule", text.index("module WeightTransformRowConst")) + len("endmodule\n")
    out = text[:head_end] + module(a, H, guard, scale, shift, magic) + text[tail:]

    rpc = "ROWS_PER_CYCLE" if "ROWS_PER_CYCLE =" in text else "1"
    out, n = re.subn(r"logic \[WEIGHT_NBITS-1:0\] w_weight_row \[HADAMARD_SIZE-1:0\]\[HADAMARD_SIZE-1:0\];",
                     f"logic [WEIGHT_NBITS-1:0] w_weight_batch [{rpc}-1:0][HADAMARD_SIZE-1:0];", out)
    assert n == 1
    if rpc == "1":  # controle do Toom-Cook: uma linha por ciclo, leituras por índice de linha
        out, n = re.subn(r"w_weight_row\[(0|row)\]\[lane\]", "w_weight_batch[0][lane]", out)
        assert n == 2
    else:
        out, n = re.subn(r"w_weight_row\[lane / HADAMARD_SIZE\]\[lane % HADAMARD_SIZE\]",
                         "w_weight_batch[lane / HADAMARD_SIZE][lane % HADAMARD_SIZE]", out)
        assert n == 1
        out, n = re.subn(r"w_weight_row\[\(\(int'\(r_conv_multiply_count\) \+ 1\) \* ROWS_PER_CYCLE\) \+\s*"
                         r"\(lane / HADAMARD_SIZE\)\]\[lane % HADAMARD_SIZE\]",
                         "w_weight_batch[lane / HADAMARD_SIZE][lane % HADAMARD_SIZE]", out)
        assert n == 1, "leitura da próxima linha"
    out, n = re.subn(r"for \(genvar row = 0; row < HADAMARD_SIZE; row\+\+\) begin: WEIGHT_TRANSFORM_ROWS.*?\n  end\n",
                     f"for (genvar group = 0; group < {rpc}; group++) begin: WEIGHT_TRANSFORM_ROWS\n"
                     "    WeightTransformSubexpression #(.NBITS(NBITS), .WEIGHT_FRAC_BITS(WEIGHT_FRAC_BITS),\n"
                     f"                             .GROUP(group), .GROUPS({rpc}), .ROUND(ROUND)) weight_trf (\n"
                     "      .pin(r_weight_spatial), .enable(w_weight_row_enable), .pout(w_weight_batch[group]));\n"
                     "  end\n", out, flags=re.S)
    assert n == 1
    assert "w_weight_row[" not in out.replace("w_weight_row_enable[", "")
    tag = "subexpressionmagic" if magic else "subexpression"
    dst = src.with_name(re.sub(r"(rowconst\d+)-", rf"\1-{tag}-", src.name, count=1))
    dst.write_text(out)
    print("->", dst)


if __name__ == "__main__":
    main()
