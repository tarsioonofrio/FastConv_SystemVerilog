#!/usr/bin/env python3
"""Generate the TCN9 frac6 package used by the pretransformed column RTL.

The feature/activation datapath remains 20-bit Q8. The transformed weights
retain six extra fractional bits and are stored sign-extended through the
20-bit memory interface, matching the TCN16 frac6 pretransformed convention.
"""

from pathlib import Path
import hashlib
import json
import os
import re

import numpy as np

from fast_convolution import cli, simulation


WEIGHT_FRAC_BITS = 6
NBITS = 20
CHANNEL_IN = int(os.environ.get("CHANNEL_IN", "3"))
CHANNEL_OUT = int(os.environ.get("CHANNEL_OUT", "12"))
REPO_ROOT = Path(__file__).resolve().parent
DATASET = os.environ.get(
    "DATASET",
    f"sim-032-{CHANNEL_IN}-{CHANNEL_OUT}-normal-trunc-frac{WEIGHT_FRAC_BITS}-nbits{NBITS}",
)


def fractional_truncated_core(payload, weight_quant, output_shape, quant_bits):
    """Use floor-truncated, fraction-preserving TCN9 transformed weights."""
    if payload.dim != 2 or not payload.truncated_weight_transform:
        raise ValueError("This generator requires a truncated 2-D workload")

    channel_in = payload.channel_in
    channel_out = payload.channel_out
    _, c, b, a, q = simulation.read_build_2d(payload.repo)
    bg = simulation._compute_bg_2d(
        weight_quant, q, b, channel_out, channel_in
    )
    scale = simulation._weight_transform_scale_2d(q)
    if scale != 36:
        raise ValueError(f"TCN9 frac6 expects weight scale 36, got {scale}")
    bg_numerator = simulation._matrix_to_exact_int(
        np.asarray(bg, dtype=object) * scale
    )
    bg_frac = simulation._truncate_scaled_weight_transform(
        bg_numerator * (1 << WEIGHT_FRAC_BITS),
        scale,
        bits=NBITS + WEIGHT_FRAC_BITS,
    )

    fast_conv = simulation._fast_convolutions_2d(
        bg_frac,
        channel_out,
        channel_in,
        c,
        a,
        quant_bits + WEIGHT_FRAC_BITS,
        nbits=NBITS,
        product_nbits=NBITS,
    )
    output_fast_by_input = np.array(
        [
            [
                simulation.fast.filter2d_slide2d(
                    fast_conv[cout][cin],
                    payload.feature_quant[0][cin],
                    output_shape,
                    payload.c_len,
                    payload.a_len,
                )
                for cin in range(channel_in)
            ]
            for cout in range(channel_out)
        ]
    )
    output_fast = simulation._wrap_signed(
        np.sum(output_fast_by_input, axis=1), NBITS
    )
    feat_windows, out_windows = simulation._collect_windows_2d(
        payload, output_fast, output_shape
    )
    count_nest = np.prod(out_windows.shape[:-1])
    count_mult = int(
        count_nest
        * np.prod([np.prod(np.asarray(q[0]).shape), np.prod(np.asarray(q[1]).shape)])
    )
    return simulation.SimulationCore(
        output_fast=output_fast,
        feat_list_sv=feat_windows,
        out_feat_list_sv=out_windows,
        bg_quant=bg_frac,
        bg=bg,
        count_nest=count_nest,
        count_mult=count_mult,
        weight_scale=scale,
    )


def main():
    simulation._simulate_core = fractional_truncated_core
    cli.main(
        [
            "-p", str(REPO_ROOT), "sim", "normal",
            "--image-side", "32", "-i", str(CHANNEL_IN),
            "-o", str(CHANNEL_OUT), "-d", "0",
            "--truncated-weight-transform", "--nbits", str(NBITS), "--no-c",
            "-n", DATASET.removeprefix("sim-"),
        ]
    )

    pack = REPO_ROOT / "sim" / DATASET / "pack_data.sv"
    source = pack.read_text()
    marker = "  localparam int WEIGHT_TRANSFORM_SCALE = 36;\n"
    if marker not in source:
        raise RuntimeError(f"expected TCN9 scale declaration was not found in {pack}")
    source = source.replace(
        marker,
        marker + f"  localparam int WEIGHT_TRANSFORM_FRAC_BITS = {WEIGHT_FRAC_BITS};\n",
        1,
    )
    pack.write_text(source)
    sim_report = REPO_ROOT / "sim" / DATASET / "sim.txt"
    with sim_report.open("a") as stream:
        stream.write(f"Weight transform fractional bits: {WEIGHT_FRAC_BITS}\n")
    summary = sim_report.read_text()
    r2_match = re.search(r"^R2:\s*(\S+)", summary, re.MULTILINE)
    metadata = {
        "workload": {
            "image_side": 32,
            "channel_in": CHANNEL_IN,
            "channel_out": CHANNEL_OUT,
            "kernel_size": 3,
            "seed": 0,
            "quant_bits": 8,
            "nbits": NBITS,
            "weight_transform_scale": 36,
            "weight_transform_frac_bits": WEIGHT_FRAC_BITS,
            "truncated_weight_transform": True,
        },
        "generator": {
            "project": "fast-convolution-rtl",
            "revision": "5c021aabc87136efb03a329d86f3e833af1abd42",
            "method": "generate_trunc_frac6_nbits20.py (TCN9 scale-36 extension)",
        },
        "artifacts": {
            "pack_data_sha256": hashlib.sha256(pack.read_bytes()).hexdigest(),
            "library_r2": float(r2_match.group(1)) if r2_match else None,
        },
    }
    (pack.parent / "generation.json").write_text(
        json.dumps(metadata, indent=2, sort_keys=True) + "\n"
    )
    (pack.parent / "README.md").write_text(
        "# TCN9 Cin=3, Cout=12 frac6 dataset\n\n"
        "Canonical workload: 32x32 input, Cin=3, Cout=12, 3x3 kernel, seed=0, "
        "NBITS=20 and QUANT_BITS=8. The scale-36 transformed weights retain "
        "six fractional bits with arithmetic-floor truncation.\n\n"
        "This package is intended for the matching TCN9 pretransformed-frac6 "
        "RTL. `generation.json` records the source revision and package hash.\n\n"
        f"Library-reported R2: {metadata['artifacts']['library_r2']}.\n"
    )


if __name__ == "__main__":
    main()
