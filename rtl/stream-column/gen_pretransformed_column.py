#!/usr/bin/env python3
"""Generate integer pretransformed-weight variants from active column RTL."""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
VARIANTS = {
    "tcn9": (
        ROOT / "conv3x3/conv-tcn9-i40-h14-t10-o9-m05-stream10-prefetch15-rowconst5-trunc-column.sv",
        ROOT / "conv3x3/conv-tcn9-i40-h14-t10-o9-m05-stream10-prefetch15-pretransformed-column.sv",
        "tcn9",
        "5x5",
    ),
    "ifn9-m18": (
        ROOT / "conv3x3/conv-ifn9-i40-h27-t36-o9-m18-stream12-prefetch15-rowconst6-trunc-column.sv",
        ROOT / "conv3x3/conv-ifn9-i40-h27-t36-o9-m18-stream12-prefetch15-pretransformed-column.sv",
        "ifn9",
        "6x6",
    ),
    "tcn4-m08": (
        ROOT / "conv2x2/conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc-column.sv",
        ROOT / "conv2x2/conv-i24-h13-t08-o4-m08-stream08-prefetch8-pretransformed-column.sv",
        "tcn4",
        "4x4",
    ),
}


def replace_once(text: str, old: str, new: str) -> str:
    count = text.count(old)
    if count != 1:
        raise ValueError(f"expected one match, found {count}: {old[:100]!r}")
    return text.replace(old, new, 1)


def replace_section(text: str, start: str, end: str, new: str) -> str:
    begin = text.index(start)
    finish = text.index(end, begin)
    return text[:begin] + new + text[finish:]


def rewrite_comment_run(text: str, marker: str, replacement: str) -> str:
    lines = text.splitlines()
    for index, line in enumerate(lines):
        if marker not in line:
            continue
        end = index + 1
        while end < len(lines) and lines[end].lstrip().startswith("//"):
            end += 1
        indent = line[: len(line) - len(line.lstrip())]
        lines[index:end] = [indent + "// " + replacement]
        return "\n".join(lines) + "\n"
    return text


def update_architecture_comments(text: str) -> str:
    """Remove row-constant/raw-weight comments inherited from source RTL."""
    comment_updates = (
        ("Raw 3x3 spatial weights are", "The transformed Hadamard matrix is stored after the feature maps."),
        ("Raw spatial weights are retained", "The transformed Hadamard matrix is stored after the feature maps."),
        ("The nine spatial weights are retained", "The complete transformed weight tile is cached; the MAC bank holds only the active Hadamard batch."),
        ("The spatial weights are retained", "The complete transformed weight tile is cached; the MAC bank holds only the active Hadamard batch."),
        ("Four constant-row transforms are instantiated below.", "Cached transformed coefficients are exposed as row vectors for the MAC lanes."),
        ("One constant-row transform per Hadamard row.", "Cached transformed coefficients are exposed as row vectors for the MAC lanes."),
        ("The row-constant variant loads its nine spatial weights", "The cached transformed weights are ready before input prefetch overlaps."),
        ("The first tile remains here while the nine raw weights are read.", "The first tile waits here until its pretransformed weights are cached; later windows reuse the cache."),
        ("The first tile remains here while raw spatial weights are read.", "The first tile waits here until its pretransformed weights are cached; later windows reuse the cache."),
        ("Capture the first transformed weight row only after the raw", "The transformed weight tile is cached before the first Hadamard batch."),
        ("Capture the first transformed weight batch after the raw spatial", "The transformed weight tile is cached before the first Hadamard batch."),
    )
    for marker, replacement in comment_updates:
        text = rewrite_comment_run(text, marker, replacement)

    text = re.sub(
        r"  // Raw (?:3x3 spatial|spatial) weights are [^\n]*\n"
        r"(?:  //[^\n]*\n)*(?=  localparam int RAW_WEIGHT_WORDS)",
        "  // The transformed Hadamard matrix is stored after the feature maps.\n",
        text,
        count=1,
    )
    text = re.sub(
        r"  //[^\n]*(?:spatial weights|spatial tile)[^\n]*\n"
        r"(?:  //[^\n]*\n)*(?=  logic signed \[NBITS-1:0\] r_weight_spatial)",
        "  // The complete transformed weight tile is cached; the MAC bank holds\n"
        "  // only the coefficients consumed by the active Hadamard batch.\n",
        text,
        count=1,
    )
    text = re.sub(
        r"  // (?:Four constant-row transforms are instantiated below\.|One constant[- ]row transform per Hadamard row\.)[^\n]*\n"
        r"(?:  //[^\n]*\n)*(?=  logic \[NBITS-1:0\] w_weight_row)",
        "  // Cached transformed coefficients are exposed as row vectors for the MAC lanes.\n",
        text,
        count=1,
    )
    text = re.sub(
        r"(?m)^      // The row-constant variant[^\n]*\n"
        r"(?:      //[^\n]*\n)*(?=      if \(st_input_current == CONV_INPUT)",
        "      // The cached transformed weights are ready before input prefetch overlaps.\n",
        text,
        count=1,
    )
    text = re.sub(
        r"(?m)^        // The first tile remains here while[^\n]*\n"
        r"(?:        //[^\n]*\n)*(?=        if \(r_weight_tile_valid\))",
        "        // The first tile waits here until its pretransformed weights are cached.\n"
        "        // Later windows reuse the cached tile and proceed to Hadamard.\n",
        text,
        count=1,
    )
    text = re.sub(
        r"(?m)^          // Capture the first transformed weight[^\n]*\n"
        r"(?:          //[^\n]*\n)*(?=          if \(r_weight_tile_valid\))",
        "          // The transformed weight tile is cached before the first Hadamard batch.\n",
        text,
        count=1,
    )
    # The transform module is removed below, so its preceding explanatory
    # comments must not be left attached to the next module (typically inverse).
    module_start = text.find("module WeightTransformRowConst")
    if module_start >= 0:
        comment_start = text.rfind("\n// Constant-row transform", 0, module_start)
        if comment_start >= 0:
            text = text[:comment_start] + "\n" + text[module_start:]
    return text


def update_weight_registers(text: str) -> str:
    text = replace_once(
        text,
        "  localparam int RAW_WEIGHT_WORDS = CONV_KERNEL_SIZE * CONV_KERNEL_SIZE;\n"
        "  localparam int RAW_WEIGHT_COUNT_WIDTH = f_width_min1(RAW_WEIGHT_WORDS);\n"
        "  localparam int RAW_WEIGHT_BASE = (N_CHANNEL_IN * FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH) +\n"
        "                                   (N_CHANNEL_IN * N_CHANNEL_OUT * WEIGHT_CYCLES);",
        "  // The integer-truncated Hadamard weight tile is stored immediately after\n"
        "  // the feature maps and cached locally. Reads use the existing column port.\n"
        "  localparam int PRETRANSFORMED_WEIGHT_WORDS = WEIGHT_CYCLES;\n"
        "  localparam int PRETRANSFORMED_WEIGHT_READ_BEATS =\n"
        "      (PRETRANSFORMED_WEIGHT_WORDS + CONV_INPUT_SIZE - 1) / CONV_INPUT_SIZE;\n"
        "  localparam int PRETRANSFORMED_WEIGHT_LAST_OFFSET =\n"
        "      (PRETRANSFORMED_WEIGHT_READ_BEATS - 1) * CONV_INPUT_SIZE;\n"
        "  localparam int PRETRANSFORMED_WEIGHT_COUNT_WIDTH =\n"
        "      f_width_min1(PRETRANSFORMED_WEIGHT_WORDS + CONV_INPUT_SIZE);\n"
        "  localparam int PRETRANSFORMED_WEIGHT_BASE =\n"
        "      N_CHANNEL_IN * FEAT_INPUT_SIZE * FEAT_INPUT_WIDTH;",
    )
    text = replace_once(
        text,
        "  logic signed [NBITS-1:0] r_weight_spatial[RAW_WEIGHT_WORDS-1:0];",
        "  logic signed [NBITS-1:0] r_weight_pretransformed[PRETRANSFORMED_WEIGHT_WORDS-1:0];",
    )
    text = replace_once(
        text,
        "  localparam WEIGHT_ROW_COUNT_WIDTH = RAW_WEIGHT_COUNT_WIDTH;",
        "  localparam WEIGHT_ROW_COUNT_WIDTH = PRETRANSFORMED_WEIGHT_COUNT_WIDTH;",
    )
    return text


def direct_weight_rows(algorithm: str, hadamard: str) -> str:
    size = int(hadamard.split("x")[0])
    if algorithm == "tcn4":
        assigns = []
        for row in range(size):
            for col in range(size):
                assigns.append(
                    f"  assign w_weight_row{row}[{col}] = "
                    f"r_weight_pretransformed[{row * size + col}];"
                )
        return "\n".join(assigns) + "\n\n"
    return """  // Present the cached transformed coefficients as a row/column matrix.
  for (genvar row = 0; row < HADAMARD_SIZE; row++) begin: PRETRANSFORMED_WEIGHT_ROWS
    for (genvar column = 0; column < HADAMARD_SIZE; column++) begin: PRETRANSFORMED_WEIGHT_COLUMNS
      assign w_weight_row[row][column] =
          r_weight_pretransformed[row * HADAMARD_SIZE + column];
    end
  end

"""


def convert(source: Path, destination: Path, algorithm: str, hadamard: str) -> None:
    text = source.read_text()
    header_start = text.index("/*")
    header_end = text.index("*/", header_start) + 2
    text = (
        text[:header_start]
        + f"/*\n   {algorithm.upper()} streaming column convolution with integer\n"
        + f"   pretransformed Hadamard weights ({hadamard}).\n"
        + "   Generated by rtl/stream-column/gen_pretransformed_column.py.\n*/"
        + text[header_end:]
    )

    text = update_architecture_comments(text)
    text = update_weight_registers(text)
    text = text.replace("RAW_WEIGHT_BASE", "PRETRANSFORMED_WEIGHT_BASE")
    text = text.replace("RAW_WEIGHT_WORDS", "PRETRANSFORMED_WEIGHT_WORDS")
    text = text.replace(
        "r_input_addr_kernel <= r_input_addr_kernel + NADDR'(CONV_KERNEL_SIZE);",
        "r_input_addr_kernel <= r_input_addr_kernel + NADDR'(CONV_INPUT_SIZE);",
    )
    text = text.replace(
        "WEIGHT_ROW_COUNT_WIDTH'(PRETRANSFORMED_WEIGHT_WORDS - CONV_KERNEL_SIZE)",
        "WEIGHT_ROW_COUNT_WIDTH'(PRETRANSFORMED_WEIGHT_LAST_OFFSET)",
    )
    text = text.replace(
        "r_weight_row_count <= r_weight_row_count + WEIGHT_ROW_COUNT_WIDTH'(CONV_KERNEL_SIZE);",
        "r_weight_row_count <= r_weight_row_count + WEIGHT_ROW_COUNT_WIDTH'(CONV_INPUT_SIZE);",
    )
    text = text.replace("raw spatial words read for the active weight tile",
                        "pretransformed weight words read for the active tile")
    text = text.replace("raw-weight vector", "pretransformed-weight tile")
    text = text.replace("raw spatial tile", "pretransformed-weight tile")
    text = text.replace("raw spatial weights", "pretransformed weights")
    text = text.replace("nine raw weights", "the pretransformed weight tile")

    weight_reg_start = "  always_ff @(posedge clk or posedge reset) begin: WEIGHT_REG_BLOCK"
    conv_state_start = "  always_ff @(posedge clk or posedge reset) begin: CONV_STATE_REG_BLOCK"
    weight_reg = """  always_ff @(posedge clk or posedge reset) begin: PRETRANSFORMED_WEIGHT_REG_BLOCK
    if (reset) begin
      for (int unsigned i = 0; i < PRETRANSFORMED_WEIGHT_WORDS; i++)
        r_weight_pretransformed[i] <= '0;
    end else if (st_input_current == READ_WEIGHTS && p_input_valid) begin
      for (int unsigned lane = 0; lane < CONV_INPUT_SIZE; lane++) begin
        if ((int'(r_weight_row_count) + lane) < PRETRANSFORMED_WEIGHT_WORDS)
          r_weight_pretransformed[int'(r_weight_row_count) + lane] <=
              $signed(p_input_data[lane*NBITS +: NBITS]);
      end
    end
  end

"""
    text = replace_section(text, weight_reg_start, conv_state_start, weight_reg)

    post_transform = text.index("  ) trf (")
    start_candidates = (
        "  // The multiply counter selects",
        "  // Enable the constant weight-transform rows",
        "  // The existing multiply counter selects",
    )
    starts = [text.find(candidate, post_transform) for candidate in start_candidates]
    starts = [position for position in starts if position >= 0]
    if len(starts) != 1:
        raise ValueError(f"could not uniquely find weight-transform region in {source}")
    start = starts[0]
    lane_marker = "  for (genvar lane = 0; lane < FIXED_NUM_MULT; lane++) begin:"
    end = text.index(lane_marker, start)
    text = text[:start] + direct_weight_rows(algorithm, hadamard) + text[end:]

    # Delete declarations for the now-unused enable signals.
    text = text.replace("  logic [HADAMARD_SIZE-1:0] w_weight_row_enable;\n", "")
    for row in range(4):
        text = text.replace(f"  logic w_weight_row_enable{row};\n", "")

    # The row-constant transform module is no longer instantiated in this
    # architecture; do not carry its unused definition into the generated RTL.
    module_start = text.find("module WeightTransformRowConst")
    if module_start >= 0:
        next_module = text.find("\nmodule ", module_start + 1)
        if next_module >= 0:
            text = (text[:module_start].rstrip() + "\n\n" +
                    text[next_module + 1:])
        else:
            text = text[:module_start].rstrip() + "\n"

    destination.write_text(text)
    print(destination)


def main() -> None:
    if len(sys.argv) != 2 or sys.argv[1] not in VARIANTS:
        options = ", ".join(VARIANTS)
        raise SystemExit(f"usage: {Path(sys.argv[0]).name} <{options}>")
    name = sys.argv[1]
    source, destination, algorithm, hadamard = VARIANTS[name]
    convert(source, destination, algorithm, hadamard)


if __name__ == "__main__":
    main()
