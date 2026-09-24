#!/usr/bin/env python3
"""Convert the canonical generated pack_data package into XPM .mem files."""

from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path

DATA_WORDS = 20
FEATURE_WORDS = 32 * 32 * 3
TRANSFORMED_WEIGHT_WORDS = 16 * 3 * 3
RAW_SPATIAL_WEIGHT_WORDS = 3 * 3 * 3 * 3
OUTPUT_WORDS = 30 * 30 * 3
CRC32_MPEG2_POLY = 0x04C11DB7
CRC32_INIT = 0xFFFFFFFF
CRC32_XOROUT = 0


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def parse_const_data(path: Path) -> list[int]:
    source = path.read_text(encoding="ascii")
    match = re.search(
        r"const\s+int\s+const_data\s*\[\s*\d+\s*\]\s*=\s*'\s*\{(.*?)\};",
        source,
        flags=re.DOTALL,
    )
    if match is None:
        raise ValueError(f"cannot find const_data initializer in {path}")
    values = [int(token) for token in re.findall(r"-?\d+", match.group(1))]
    expected = FEATURE_WORDS + TRANSFORMED_WEIGHT_WORDS + RAW_SPATIAL_WEIGHT_WORDS
    if len(values) != expected:
        raise ValueError(f"const_data has {len(values)} words; expected {expected}")
    return values


def parse_const_feat_out(path: Path) -> list[int]:
    source = path.read_text(encoding="ascii")
    match = re.search(
        r"const\s+int\s+const_feat_out\s*\[\s*\d+\s*\]\s*=\s*'\s*\{(.*?)\};",
        source,
        flags=re.DOTALL,
    )
    if match is None:
        raise ValueError(f"cannot find const_feat_out initializer in {path}")
    values = [int(token) for token in re.findall(r"-?\d+", match.group(1))]
    if len(values) != OUTPUT_WORDS:
        raise ValueError(f"const_feat_out has {len(values)} words; expected {OUTPUT_WORDS}")
    return values


def crc32_mpeg2_words(values: list[int]) -> int:
    """CRC-32/MPEG-2 over each 20-bit word, MSB first, in address order."""
    crc = CRC32_INIT
    mask = (1 << DATA_WORDS) - 1
    for value in values:
        word = value & mask
        for bit_index in range(DATA_WORDS - 1, -1, -1):
            feedback = ((crc >> 31) & 1) ^ ((word >> bit_index) & 1)
            crc = (crc << 1) & 0xFFFFFFFF
            if feedback:
                crc ^= CRC32_MPEG2_POLY
    return crc ^ CRC32_XOROUT


def write_mem(path: Path, values: list[int]) -> None:
    mask = (1 << DATA_WORDS) - 1
    path.write_text("".join(f"{value & mask:05x}\n" for value in values), encoding="ascii")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pack-data", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    args = parser.parse_args()

    pack_data = args.pack_data.resolve()
    out_dir = args.out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    values = parse_const_data(pack_data)
    expected_output = parse_const_feat_out(pack_data)
    output_crc32 = crc32_mpeg2_words(expected_output)
    repo_root = Path(__file__).resolve().parents[6]
    try:
        pack_data_id = pack_data.relative_to(repo_root).as_posix()
    except ValueError:
        pack_data_id = pack_data.name

    features = values[:FEATURE_WORDS]
    weights = values[FEATURE_WORDS : FEATURE_WORDS + TRANSFORMED_WEIGHT_WORDS]
    output_zeros = [0] * OUTPUT_WORDS
    write_mem(out_dir / "input_features.mem", features)
    write_mem(out_dir / "transformed_weights.mem", weights)
    write_mem(out_dir / "output_zero.mem", output_zeros)
    (out_dir / "output_signature_pkg.sv").write_text(
        "package output_signature_pkg;\n"
        "  localparam logic [31:0] EXPECTED_OUTPUT_CRC32 = 32'h"
        f"{output_crc32:08x};\n"
        "endpackage\n",
        encoding="ascii",
    )

    files = ["input_features.mem", "transformed_weights.mem", "output_zero.mem"]
    manifest = [
        f"canonical_pack_data={pack_data_id}",
        f"canonical_pack_data_sha256={sha256(pack_data)}",
        f"feature_words={len(features)}",
        f"transformed_weight_words={len(weights)}",
        f"output_zero_words={len(output_zeros)}",
        f"expected_output_words={len(expected_output)}",
        "output_signature=CRC-32/MPEG-2 over 20-bit words, MSB-first, ascending address",
        f"output_signature_poly={CRC32_MPEG2_POLY:08x}",
        f"output_signature_init={CRC32_INIT:08x}",
        f"output_signature_xorout={CRC32_XOROUT:08x}",
        "output_signature_refin=false",
        "output_signature_refout=false",
        "output_signature_word_width_bits=20",
        f"expected_output_crc32={output_crc32:08x}",
        f"unused_raw_spatial_weight_words={RAW_SPATIAL_WEIGHT_WORDS}",
    ]
    manifest.extend(f"{name}_sha256={sha256(out_dir / name)}" for name in files)
    manifest.append(f"output_signature_pkg.sv_sha256={sha256(out_dir / 'output_signature_pkg.sv')}")
    (out_dir / "memory_manifest.txt").write_text("\n".join(manifest) + "\n", encoding="ascii")
    print("\n".join(manifest))


if __name__ == "__main__":
    main()
