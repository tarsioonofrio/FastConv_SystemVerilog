#!/usr/bin/env python3
"""Derive TCN9 frac6 pretransformed RTL from the integer column variant."""

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "conv3x3/conv-tcn9-i40-h14-t10-o9-m05-stream10-prefetch15-pretransformed-column.sv"
DESTINATION = ROOT / "conv3x3/conv-tcn9-i40-h14-t10-o9-m05-stream10-prefetch15-pretransformed-frac6-column.sv"


def replace_once(text: str, old: str, new: str) -> str:
    count = text.count(old)
    if count != 1:
        raise ValueError(f"expected one occurrence, found {count}: {old!r}")
    return text.replace(old, new, 1)


def convert() -> None:
    text = SOURCE.read_text()
    text = replace_once(
        text,
        "TCN9 streaming column convolution with integer\n   pretransformed Hadamard weights (5x5).",
        "TCN9 streaming column convolution with frac6\n   pretransformed Hadamard weights (5x5, scale 36).",
    )
    text = replace_once(
        text,
        "  localparam int unsigned FIXED_NUM_MULT = HADAMARD_SIZE;",
        "  localparam int unsigned FIXED_NUM_MULT = HADAMARD_SIZE;\n"
        "  localparam int unsigned WEIGHT_FRAC_BITS = 6;\n"
        "  localparam int unsigned WEIGHT_NBITS = NBITS + WEIGHT_FRAC_BITS;",
    )
    text = replace_once(
        text,
        "  logic signed [NBITS-1:0] r_weight_pretransformed[PRETRANSFORMED_WEIGHT_WORDS-1:0];\n"
        "  logic [NBITS-1:0] r_input_weight[FIXED_NUM_MULT-1:0];",
        "  logic signed [WEIGHT_NBITS-1:0] r_weight_pretransformed[PRETRANSFORMED_WEIGHT_WORDS-1:0];\n"
        "  logic [WEIGHT_NBITS-1:0] r_input_weight[FIXED_NUM_MULT-1:0];",
    )
    text = replace_once(
        text,
        "  logic [NBITS-1:0] w_weight_row [HADAMARD_SIZE-1:0][HADAMARD_SIZE-1:0];",
        "  logic [WEIGHT_NBITS-1:0] w_weight_row [HADAMARD_SIZE-1:0][HADAMARD_SIZE-1:0];",
    )
    text = replace_once(
        text,
        "          r_weight_pretransformed[int'(r_weight_row_count) + lane] <=\n"
        "              $signed(p_input_data[lane*NBITS +: NBITS]);",
        "          r_weight_pretransformed[int'(r_weight_row_count) + lane] <=\n"
        "              {{WEIGHT_FRAC_BITS{p_input_data[lane*NBITS + NBITS - 1]}},\n"
        "               $signed(p_input_data[lane*NBITS +: NBITS])};",
    )
    text = replace_once(
        text,
        "    Multip #(.QUANT(QUANT), .NBITS(NBITS)) multip(\n"
        "      .feature(w_transform_feature[lane]), .weight(r_input_weight[lane]), .product(w_conv_product[lane]));",
        "    MultipWideWeight #(\n"
        "      .QUANT(QUANT + WEIGHT_FRAC_BITS),\n"
        "      .NBITS(NBITS),\n"
        "      .WEIGHT_NBITS(WEIGHT_NBITS)\n"
        "    ) multip(\n"
        "      .feature(w_transform_feature[lane]), .weight(r_input_weight[lane]),\n"
        "      .product(w_conv_product[lane]));",
    )
    if "Multip #(.QUANT(QUANT), .NBITS(NBITS)) multip(" in text:
        raise RuntimeError("the integer multiplier instance was not converted")
    DESTINATION.write_text(text)


if __name__ == "__main__":
    convert()
