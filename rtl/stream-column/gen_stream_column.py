#!/usr/bin/env python3
"""Generate the streaming truncated-column Conv RTL for one fast-convolution algorithm.

The control structure is shared (conv_stream_column_core.svtmpl).  Everything that
depends on the algorithm is derived from its build.json:

* WeightTransformRowConst: row r of the 2-D weight transform, computed from the nine raw
  spatial weights with integer coefficients and divided by the weight scale (floor).
* InverseRow / InverseRowAccumulate: row-streamed inverse transform.

Usage: gen_stream_column.py <build.json> <algo-name> <output.sv> [num-mult]
num-mult defaults to the Hadamard size (one complete row per cycle). Larger
values must be whole multiples of the Hadamard size and process multiple rows
in parallel per cycle.
"""
import json
import math
import sys
from fractions import Fraction
from pathlib import Path

KERNEL = 3


def load_build(path):
    data = json.loads(Path(path).read_text())
    to_int = lambda m: [[int(v) for v in row] for row in m]
    c = [to_int(m) for m in data["c"]]
    a = [to_int(m) for m in data["a"]]
    b = [to_int(m) for m in data["b"]]
    q = [[Fraction(p, d) for p, d in axis] for axis in data["q"]]
    return c, a, b, q


def axis_scale(q_axis):
    scale = 1
    for value in q_axis:
        scale = math.lcm(scale, value.denominator)
    return scale


def term(coef, name):
    """Return ('+' | '-', text) for coef*name, or None when the coefficient is zero."""
    if coef == 0:
        return None
    sign = "-" if coef < 0 else "+"
    mag = abs(coef)
    return sign, (name if mag == 1 else f"({mag} * {name})")


def join_terms(terms):
    terms = [t for t in terms if t is not None]
    if not terms:
        return "'0"
    first_sign, first_text = terms[0]
    text = ("-" if first_sign == "-" else "") + first_text
    for sign, body in terms[1:]:
        text += f" {sign} {body}"
    return text


def weight_module(c, a, b, q, hadamard):
    scale0, scale1 = axis_scale(q[0]), axis_scale(q[1])
    scale = scale0 * scale1
    # coefficient of weight g[i][j] in output U[r][col]: (s0*q0[r]*b0[r][i]) * (s1*q1[col]*b1[col][j])
    coef = {}
    max_abs_sum = 0
    for r in range(hadamard):
        for col in range(hadamard):
            row_terms = {}
            for i in range(KERNEL):
                for j in range(KERNEL):
                    left = q[0][r] * scale0 * b[0][r][i]
                    right = q[1][col] * scale1 * b[1][col][j]
                    value = left * right
                    assert value.denominator == 1, (r, col, i, j, value)
                    row_terms[(i, j)] = int(value)
            coef[(r, col)] = row_terms
            max_abs_sum = max(max_abs_sum, sum(abs(v) for v in row_terms.values()))
    guard = max_abs_sum.bit_length() + 1
    pow2 = scale & (scale - 1) == 0
    shift = scale.bit_length() - 1

    lines = []
    lines.append("// -----------------------------------------------------------------------------")
    lines.append("// Constant-row transform of the 3x3 spatial kernel.")
    lines.append("//")
    lines.append(f"// One instance per transformed row (ROW_INDEX), each producing {hadamard} values.")
    lines.append("// The row-th equations are elaboration-time constants, so only the selected row")
    lines.append("// remains after constant propagation.  Disabled rows drive zero (operand isolation).")
    lines.append("// The exact transform is an integer combination of the raw weights.")
    if scale == 1:
        lines.append("// WEIGHT_SCALE = 1, so the numerator is already the transformed weight.")
    elif pow2:
        lines.append(f"// WEIGHT_SCALE = {scale}; arithmetic right shift by {shift} computes the floor.")
        lines.append("// The result is wrapped to NBITS, matching the truncated golden dataset.")
    else:
        lines.append(f"// WEIGHT_SCALE = {scale}; divide by a constant and correct toward floor.")
        lines.append("// The result is wrapped to NBITS, matching the truncated golden dataset.")
        lines.append("// SystemVerilog '/' truncates toward zero, so negative remainders decrement the quotient.")
    lines.append("// -----------------------------------------------------------------------------")
    lines.append("// Keep constant-transform arithmetic in fabric; reserve DSPs for the MAC lanes.")
    lines.append("(* use_dsp = \"no\" *)")
    lines.append("module WeightTransformRowConst #(")
    lines.append("    parameter int NBITS = 20,")
    lines.append("    parameter int ROW_INDEX = 0")
    lines.append("  ) (")
    lines.append("    input  logic signed [NBITS-1:0] pin [8:0],")
    lines.append("    input  logic                    enable,")
    lines.append(f"    output logic        [NBITS-1:0] pout [{hadamard - 1}:0]")
    lines.append("  );")
    lines.append("  timeunit 1ns;")
    lines.append("  timeprecision 1ps;")
    lines.append("")
    lines.append(f"  // The largest sum of absolute coefficients is {max_abs_sum}; keep guard bits so the")
    lines.append("  // exact numerator never overflows before the division.")
    lines.append(f"  localparam int TRANSFORM_WIDTH = NBITS + {guard};")
    lines.append(f"  localparam int WEIGHT_SCALE = {scale};")
    lines.append("")
    lines.append("  logic signed [TRANSFORM_WIDTH-1:0] weight [0:8];")
    lines.append(f"  logic signed [TRANSFORM_WIDTH-1:0] sum [0:{hadamard - 1}];")
    lines.append(f"  logic signed [TRANSFORM_WIDTH-1:0] truncated [0:{hadamard - 1}];")
    lines.append("")
    if scale != 1 and not pow2:
        lines.append("  function automatic logic signed [TRANSFORM_WIDTH-1:0] f_floor_div(")
        lines.append("      input logic signed [TRANSFORM_WIDTH-1:0] value);")
        lines.append("    logic signed [TRANSFORM_WIDTH-1:0] quotient;")
        lines.append("    begin")
        lines.append("      quotient = value / WEIGHT_SCALE;")
        lines.append("      if ((value % WEIGHT_SCALE) < 0)")
        lines.append("        quotient = quotient - 1;")
        lines.append("      f_floor_div = quotient;")
        lines.append("    end")
        lines.append("  endfunction")
        lines.append("")
    lines.append("  always_comb begin: WEIGHT_TRANSFORM_ROW_CONST_BLOCK")
    lines.append("    for (int unsigned k = 0; k < 9; k++)")
    lines.append("      weight[k] = '0;")
    lines.append(f"    for (int unsigned k = 0; k < {hadamard}; k++) begin")
    lines.append("      sum[k] = '0;")
    lines.append("      truncated[k] = '0;")
    lines.append("      pout[k] = '0;")
    lines.append("    end")
    lines.append("")
    lines.append("    if (enable) begin")
    lines.append("      // Sign-extend before arithmetic so additions do not overflow at NBITS.")
    lines.append("      for (int unsigned k = 0; k < 9; k++)")
    lines.append("        weight[k] = {{(TRANSFORM_WIDTH-NBITS){pin[k][NBITS-1]}}, pin[k]};")
    lines.append("")
    lines.append("      // ROW_INDEX is constant per instance.  This is intentionally not a run-time case")
    lines.append("      // on a signal: only one row's equations remain after elaboration.")
    for r in range(hadamard):
        keyword = "if" if r == 0 else "end else if"
        lines.append(f"      {keyword} (ROW_INDEX == {r}) begin")
        for col in range(hadamard):
            terms = [
                term(coef[(r, col)][(i, j)], f"weight[{i * KERNEL + j}]")
                for i in range(KERNEL)
                for j in range(KERNEL)
            ]
            lines.append(f"        sum[{col}] = {join_terms(terms)};")
    lines.append("      end")
    lines.append("")
    if scale == 1:
        lines.append("      // Weight scale is one: the numerator is already the transformed weight.")
        for col in range(hadamard):
            lines.append(f"      truncated[{col}] = sum[{col}];")
    elif pow2:
        lines.append("      // Arithmetic shift is the floor of the division by the power-of-two scale.")
        for col in range(hadamard):
            lines.append(f"      truncated[{col}] = sum[{col}] >>> {shift};")
    else:
        lines.append("      // Floor division by the constant weight scale.")
        for col in range(hadamard):
            lines.append(f"      truncated[{col}] = f_floor_div(sum[{col}]);")
    lines.append("")
    lines.append("      // The output slice preserves the NBITS wrap contract of the datapath.")
    for col in range(hadamard):
        lines.append(f"      pout[{col}] = truncated[{col}][NBITS-1:0];")
    lines.append("    end")
    lines.append("  end")
    lines.append("endmodule")
    return "\n".join(lines), scale, max_abs_sum, guard


def inverse_modules(a, hadamard, out):
    lines = []
    lines.append("// -----------------------------------------------------------------------------")
    lines.append("// Row-streamed inverse transform.  With M the Hadamard product matrix, the")
    lines.append("// output is Y = A0^T * M * A1.  InverseRow computes one row of M * A1 and")
    lines.append("// InverseRowAccumulate adds A0[row][i] times that row to output row i.")
    lines.append("// All arithmetic wraps at NBITS (modular), matching the golden model.")
    lines.append("// -----------------------------------------------------------------------------")
    lines.append("module InverseRow #(")
    lines.append("    parameter int NBITS = 20,")
    lines.append(f"    parameter int HADAMARD_SIZE = {hadamard},")
    lines.append(f"    parameter int CONV_OUTPUT_SIZE = {out}")
    lines.append("  ) (")
    lines.append("    input  logic [NBITS-1:0] inverse_input_row [HADAMARD_SIZE-1:0],")
    lines.append("    output logic [NBITS-1:0] inverse_partial [CONV_OUTPUT_SIZE-1:0]")
    lines.append("  );")
    lines.append("  timeunit 1ns;")
    lines.append("  timeprecision 1ps;")
    lines.append("")
    for j in range(out):
        terms = [term(a[1][c][j], f"inverse_input_row[{c}]") for c in range(hadamard)]
        lines.append(f"  assign inverse_partial[{j}] = {join_terms(terms)};")
    lines.append("endmodule")
    lines.append("")
    lines.append("module InverseRowAccumulate #(")
    lines.append("    parameter int NBITS = 20,")
    lines.append(f"    parameter int HADAMARD_SIZE = {hadamard},")
    lines.append(f"    parameter int CONV_OUTPUT_SIZE = {out},")
    lines.append("    parameter int ROWS_PER_CYCLE = 1,")
    lines.append("    parameter int ROW_INDEX_WIDTH = (HADAMARD_SIZE <= 1) ? 1 : $clog2(HADAMARD_SIZE)")
    lines.append("  ) (")
    lines.append("    input  logic [ROW_INDEX_WIDTH-1:0] inverse_row_idx,")
    lines.append("    input  logic [NBITS-1:0] accumulator_in [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0],")
    lines.append("    input  logic [NBITS-1:0] inverse_partial [ROWS_PER_CYCLE*CONV_OUTPUT_SIZE-1:0],")
    lines.append("    output logic [NBITS-1:0] accumulator_out [CONV_OUTPUT_SIZE*CONV_OUTPUT_SIZE-1:0]")
    lines.append("  );")
    lines.append("  timeunit 1ns;")
    lines.append("  timeprecision 1ps;")
    lines.append("")
    lines.append("  localparam int OUTPUT_PIXELS = CONV_OUTPUT_SIZE * CONV_OUTPUT_SIZE;")
    lines.append("")
    lines.append("  // Decode the batch base once, then select one statically expanded sum.")
    lines.append("  // This avoids both a runtime row-index adder per batch and a procedural")
    lines.append("  // read-modify-write chain on accumulator_out, which Vivado mis-mapped for")
    lines.append("  // some multi-row configurations in post-synthesis functional simulation.")
    lines.append("  generate")
    for rows_per_cycle in range(1, hadamard + 1):
        if hadamard % rows_per_cycle != 0:
            continue
        keyword = "if" if rows_per_cycle == 1 else "else if"
        lines.append(
            f"    {keyword} (ROWS_PER_CYCLE == {rows_per_cycle}) begin: INVERSE_SUM_{rows_per_cycle}"
        )
        lines.append("      always_comb begin: INVERSE_ROW_ACCUMULATE_BLOCK")
        for pixel in range(out * out):
            lines.append(f"        accumulator_out[{pixel}] = accumulator_in[{pixel}];")
        lines.append("        case (inverse_row_idx)")
        for row_base in range(0, hadamard, rows_per_cycle):
            lines.append(f"          {row_base}: begin")
            for i in range(out):
                for j in range(out):
                    pixel = i * out + j
                    terms = [("+", f"accumulator_in[{pixel}]")]
                    for batch in range(rows_per_cycle):
                        coef = a[0][row_base + batch][i]
                        terms.append(
                            term(coef, f"inverse_partial[{batch * out + j}]")
                        )
                    lines.append(
                        f"            accumulator_out[{pixel}] = {join_terms(terms)};"
                    )
            lines.append("          end")
        lines.append("          default: begin end")
        lines.append("        endcase")
        lines.append("      end")
        lines.append("    end")
    lines.append("    else begin: INVERSE_SUM_UNSUPPORTED")
    lines.append("      always_comb begin: INVERSE_ROW_ACCUMULATE_BLOCK")
    lines.append("        for (int unsigned i = 0; i < OUTPUT_PIXELS; i++)")
    lines.append("          accumulator_out[i] = accumulator_in[i];")
    lines.append("      end")
    lines.append("    end")
    lines.append("  endgenerate")
    lines.append("endmodule")
    return "\n".join(lines)


def main():
    if len(sys.argv) not in (4, 5):
        raise SystemExit("usage: gen_stream_column.py <build.json> <algo-name> <output.sv> [num-mult]")
    build_json, algo, output = sys.argv[1:4]
    num_mult = int(sys.argv[4]) if len(sys.argv) == 5 else None
    c, a, b, q = load_build(build_json)
    in_size = len(c[0])
    hadamard = len(c[0][0])
    out = len(a[0][0])
    num_mult = hadamard if num_mult is None else num_mult
    assert in_size == out + KERNEL - 1, (in_size, out)
    assert len(b[0]) == hadamard and len(a[0]) == hadamard
    assert num_mult >= hadamard and num_mult % hadamard == 0, (num_mult, hadamard)
    assert hadamard * hadamard % num_mult == 0, (num_mult, hadamard)
    weight_text, scale, max_abs_sum, guard = weight_module(c, a, b, q, hadamard)
    generated = weight_text + "\n\n" + inverse_modules(a, hadamard, out)
    template = (Path(__file__).parent / "conv_stream_column_core.svtmpl").read_text()
    text = (
        template.replace("@ALGO@", algo)
        .replace("@IN@", str(in_size))
        .replace("@H@", str(hadamard))
        .replace("@OUT@", str(out))
        .replace("@NUM_MULT@", str(num_mult))
        .replace("@@GENERATED_MODULES@@", generated)
    )
    Path(output).write_text(text)
    print(
        f"{algo}: IN={in_size} H={hadamard} OUT={out} NUM_MULT={num_mult} scale={scale} "
        f"max_abs_coef_sum={max_abs_sum} guard_bits={guard} -> {output}"
    )


if __name__ == "__main__":
    main()
