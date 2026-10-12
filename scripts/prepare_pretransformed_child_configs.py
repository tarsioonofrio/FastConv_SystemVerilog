#!/usr/bin/env python3
"""Prepare isolated Cin=3/Cout=12 ASIC configs for pretransformed children."""

from __future__ import annotations

import re
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TB = "rtl/stream-column/testbench_stream_column.sv"

VARIANTS = (
    {
        "arch": "conv3x3",
        "template": "rtl/conv3x3/synthesis/conv-tcn9-i40-h14-t10-o9-m05-stream10-prefetch15-rowconst5-trunc-column-nbits16-cin3-cout12",
        "config": "rtl/conv3x3/synthesis/conv-tcn9-i40-h14-t10-o9-m05-stream10-prefetch15-pretransformed-frac6-column-cin3-cout12",
        "rtl": "rtl/conv3x3/conv-tcn9-i40-h14-t10-o9-m05-stream10-prefetch15-pretransformed-frac6-column.sv",
        "package": "rtl/conv3x3/data/tcn9/sim/sim-032-3-12-normal-trunc-frac6-nbits20/pack_data.sv",
        "nbits": 20,
        "macs": 5,
    },
    {
        "arch": "conv3x3",
        "template": "rtl/conv3x3/synthesis/conv-ifn9-i40-h27-t36-o9-m18-stream12-prefetch15-rowconst6-trunc-column-nbits16-cin3-cout12",
        "config": "rtl/conv3x3/synthesis/conv-ifn9-i40-h27-t36-o9-m18-stream12-prefetch15-pretransformed-column-nbits16-cin3-cout12",
        "rtl": "rtl/conv3x3/conv-ifn9-i40-h27-t36-o9-m18-stream12-prefetch15-pretransformed-column.sv",
        "package": "rtl/conv3x3/data/ifn9/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv",
        "nbits": 16,
        "macs": 18,
    },
    {
        "arch": "conv2x2",
        "template": "rtl/conv2x2/synthesis/conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc-column-nbits16-cin3-cout12",
        "config": "rtl/conv2x2/synthesis/conv-i24-h13-t08-o4-m08-stream08-prefetch8-pretransformed-column-nbits16-cin3-cout12",
        "rtl": "rtl/conv2x2/conv-i24-h13-t08-o4-m08-stream08-prefetch8-pretransformed-column.sv",
        "package": "rtl/conv2x2/data/tcn4/sim/sim-032-3-12-normal-trunc-nbits16/pack_data.sv",
        "nbits": 16,
        "macs": 8,
    },
)


def copy_static_config(source: Path, destination: Path) -> None:
    if destination.exists():
        if not (destination / "WORKLOAD.md").is_file():
            raise FileExistsError(f"refusing to overwrite {destination}")
        return
    destination.mkdir(parents=True)
    for name in (
        "list-define.txt",
        "list-file.txt",
        "rtl-top-file.txt",
        "testbench-file.txt",
        "top-module.txt",
        "top-parameters.txt",
    ):
        path = source / name
        if path.is_file():
            shutil.copy2(path, destination / name)
    for name in ("scripts",):
        path = source / name
        if path.is_dir():
            shutil.copytree(path, destination / name)
    for directory, names in {
        "logical": ("run.sh", "logical_synthesis.tcl"),
        "sim": ("run.sh", "args.txt", "sdf_cmd.cmd"),
        "power": ("run.sh", "power.tcl"),
    }.items():
        (destination / directory).mkdir(exist_ok=True)
        for name in names:
            path = source / directory / name
            if path.is_file():
                shutil.copy2(path, destination / directory / name)


def prepare(item: dict[str, str | int]) -> None:
    template = ROOT / str(item["template"])
    config = ROOT / str(item["config"])
    rtl = str(item["rtl"])
    package = str(item["package"])
    nbits = int(item["nbits"])
    macs = int(item["macs"])
    for required in (template / "list-file.txt", ROOT / rtl, ROOT / package):
        if not required.is_file():
            raise FileNotFoundError(required)

    copy_static_config(template, config)
    list_file = config / "list-file.txt"
    lines = list_file.read_text().splitlines()
    replacements = []
    found_package = found_rtl = False
    for line in lines:
        if line.endswith("pack_data.sv"):
            replacements.append(package)
            found_package = True
        elif line.endswith(".sv") and Path(line).name.startswith("conv-"):
            replacements.append(rtl)
            found_rtl = True
        else:
            replacements.append(line)
    if not found_package or not found_rtl:
        raise RuntimeError(f"could not replace package/RTL in {list_file}")
    list_file.write_text("\n".join(replacements) + "\n")
    (config / "rtl-top-file.txt").write_text(rtl + "\n")
    (config / "testbench-file.txt").write_text(TB + "\n")

    # The 2x2 rowconst template still invokes its legacy testbench top.
    # The new child configs all use the shared column testbench instead.
    sim_args = config / "sim/args.txt"
    sim_args_text = sim_args.read_text()
    sim_args_text, runner_count = re.subn(
        r"(?<=-top )tb_prefetch8_column\b",
        "tb_stream_column",
        sim_args_text,
    )
    if runner_count > 1 or (str(item["arch"]) == "conv2x2" and runner_count != 1):
        raise RuntimeError(f"unexpected simulation top in {sim_args}")
    sim_args.write_text(sim_args_text)

    defines = [
        line for line in (config / "list-define.txt").read_text().splitlines()
        if not line.startswith((
            "-define ASIC_NUM_MULT",
            "-define NBITS=",
            "-define NBITS16",
            "-define PRETRANSFORMED_WEIGHTS",
        ))
    ]
    defines.extend((
        f"-define NBITS={nbits}",
        "-define PRETRANSFORMED_WEIGHTS",
        f"-define ASIC_NUM_MULT={macs}",
    ))
    (config / "list-define.txt").write_text("\n".join(defines) + "\n")

    parameters_path = config / "top-parameters.txt"
    parameters = parameters_path.read_text().splitlines() if parameters_path.exists() else []
    parameters = [
        line for line in parameters
        if not line.startswith(("NUM_MULT=", "NBITS=", "N_CHANNEL_IN=", "N_CHANNEL_OUT="))
    ]
    parameters.extend((
        f"NUM_MULT={macs}",
        f"NBITS={nbits}",
        "N_CHANNEL_IN=3",
        "N_CHANNEL_OUT=12",
    ))
    parameters_path.write_text("\n".join(parameters) + "\n")

    sdf_file = config / "sim/sdf_cmd.cmd"
    sdf_text = sdf_file.read_text()
    sdf_text, count = re.subn(
        r"(?m)^\s*SCOPE\s*=\s*[^;]+;",
        "SCOPE = tb_stream_column.dut;",
        sdf_text,
    )
    if count != 1:
        raise RuntimeError(f"expected one SDF SCOPE in {sdf_file}")
    sdf_file.write_text(sdf_text)

    (config / "WORKLOAD.md").write_text(
        "# ASIC workload: pretransformed Cin=3, Cout=12\n\n"
        f"Source RTL: `{rtl}`.\n\n"
        f"Dataset: `{package}`.\n\n"
        f"Parameters: NBITS={nbits}, NUM_MULT={macs}, Cin=3, Cout=12.\n\n"
        "The pretransformed weights are stored after the feature maps in the "
        "canonical package. The dedicated stream-column testbench checks every "
        "logical output word against the package golden. Run logical synthesis, "
        "SDF simulation, and Joules power in tmux.\n"
    )


def main() -> None:
    for variant in VARIANTS:
        prepare(variant)


if __name__ == "__main__":
    main()
