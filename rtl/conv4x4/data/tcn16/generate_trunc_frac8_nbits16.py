#!/usr/bin/env python3
"""Regenerate a TCN16 fractional-weight golden with configurable channels.

Requires the fast-convolution-rtl Python package used by this repository.
The source tree and CLI are not modified; this script substitutes only the
fixed-point core model for the duration of the generation process.
"""

from pathlib import Path
import os

import numpy as np

from fast_convolution import cli, simulation


WEIGHT_FRAC_BITS = int(os.environ.get("WEIGHT_FRAC_BITS", "8"))
NBITS = int(os.environ.get("NBITS", "16"))
CHANNEL_IN = int(os.environ.get("CHANNEL_IN", "3"))
CHANNEL_OUT = int(os.environ.get("CHANNEL_OUT", "3"))
REPO_ROOT = Path(__file__).resolve().parent
DATASET = os.environ.get(
    "DATASET",
    f"sim-032-{CHANNEL_IN}-{CHANNEL_OUT}-normal-trunc-frac{WEIGHT_FRAC_BITS}-nbits{NBITS}",
)


def fractional_truncated_core(payload, weight_quant, output_shape, quant_bits):
    """Run the 2-D core with high-resolution floor-truncated weights."""
    if payload.dim != 2 or not payload.truncated_weight_transform:
        raise ValueError("This generator only supports truncated 2-D TCN16")

    channel_in = payload.channel_in
    channel_out = payload.channel_out
    _, c, b, a, q = simulation.read_build_2d(payload.repo)
    bg = simulation._compute_bg_2d(
        weight_quant, q, b, channel_out, channel_in
    )
    scale = simulation._weight_transform_scale_2d(q)
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
    output_fast = np.sum(output_fast_by_input, axis=1)
    bias = payload.bias_quant if payload.quant_data else payload.bias
    output_fast = simulation._apply_bias(output_fast, bias)
    output_fast = simulation._wrap_signed(output_fast, NBITS)
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
    marker = "  localparam int WEIGHT_TRANSFORM_SCALE = 576;\n"
    if marker not in source:
        raise RuntimeError(f"expected scale declaration was not found in {pack}")
    source = source.replace(
        marker,
        marker + f"  localparam int WEIGHT_TRANSFORM_FRAC_BITS = {WEIGHT_FRAC_BITS};\n",
        1,
    )
    pack.write_text(source)
    sim_report = REPO_ROOT / "sim" / DATASET / "sim.txt"
    with sim_report.open("a") as stream:
        stream.write(f"Weight transform fractional bits: {WEIGHT_FRAC_BITS}\n")


if __name__ == "__main__":
    main()
