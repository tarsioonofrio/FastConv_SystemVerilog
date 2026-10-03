#!/usr/bin/env python3
"""Create isolated Genus/Xcelium/Joules configs for the 3x3/4x4 ASIC sweep."""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def config_spec(conv: str, algo: str, macs: str, dataset: str) -> tuple[Path, list[str], str]:
    base = ROOT / "rtl" / conv
    name = f"asic-sweep-20261003-{algo}-m{macs.zfill(2)}"
    config = base / "synthesis" / name
    mux_suffix = macs.zfill(2)
    hdl = [
        "rtl/csa/csa_lib.sv",
        "rtl/multip/multip.sv",
        f"rtl/{conv}/data/{algo}/sim/{dataset}/pack_data.sv",
        f"rtl/{conv}/pack-param/{algo}/pack_param.sv",
        f"rtl/{conv}/mux-mult/{algo}/mux_mult_{mux_suffix}.sv",
        f"rtl/{conv}/mult-matrices/{algo}/mult_matrices.sv",
        f"rtl/{conv}/conv.sv",
        "rtl/mem/mem.sv",
    ]
    if conv == "conv4x4":
        hdl.insert(2, "contrib/rtl/pack-def/pack_def.sv")
    tb = f"rtl/{conv}/testbench.sv"
    return config, hdl, tb


def build_config(config: Path, hdl: list[str], tb: str, conv: str) -> None:
    if config.exists():
        raise FileExistsError(f"refusing to overwrite existing config: {config}")
    source_config = ROOT / "rtl" / conv / "synthesis" / (
        "ifn9-06mac" if conv == "conv3x3" else "tcn16-18mac"
    )

    config.mkdir(parents=True)
    for directory in ("logical", "sim", "power", "scripts"):
        (config / directory).mkdir()

    for name in ("logical/run.sh", "logical/logical_synthesis.tcl", "sim/run.sh",
                 "sim/args.txt", "sim/sdf_cmd.cmd", "scripts/constraints.sdc",
                 "scripts/logical_synthesis_body.tcl", "scripts/mmmc_tsmc_28_bv.tcl",
                 "scripts/power.tcl", "power/run.sh", "power/power.tcl"):
        shutil.copy2(source_config / name, config / name)

    module_replacements = {
        "module load genus": "module load cadence/genus/211",
        "module load xcelium": "module load cadence/xcelium/2303",
        "module load ddi": "module load cadence/genus/211",
    }
    for relative in ("logical/run.sh", "sim/run.sh", "power/run.sh"):
        path = config / relative
        text = path.read_text()
        for old, new in module_replacements.items():
            text = text.replace(old, new)
        path.write_text(text)

    (config / "list-file.txt").write_text("\n".join(hdl) + "\n")
    define_lines = ["-define NADDR=16", "-define NBITS=20", "-define LATENCY=1"]
    if conv == "conv4x4":
        define_lines.append("-define QUANT=8")
    (config / "list-define.txt").write_text("\n".join(define_lines) + "\n")
    (config / "top-module.txt").write_text("conv\n")
    (config / "testbench-file.txt").write_text(tb + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    points = [
        ("conv3x3", "ifn9", "6", "sim-032-3-3-normal"),
        ("conv3x3", "ifn9", "12", "sim-032-3-3-normal"),
        ("conv3x3", "ifn9", "18", "sim-032-3-3-normal"),
        ("conv3x3", "tcn9", "5", "sim-032-3-3-normal"),
        ("conv4x4", "tcn16", "6", "sim-032-3-3-normal"),
        ("conv4x4", "tcn16", "12", "sim-032-3-3-normal"),
        ("conv4x4", "tcn16", "18", "sim-032-3-3-normal"),
        ("conv4x4", "wpn16", "8", "sim-032-3-3-normal"),
        ("conv4x4", "wpn16", "16", "sim-032-3-3-normal"),
        ("conv4x4", "wpn16", "32", "sim-032-3-3-normal"),
    ]
    for conv, algo, macs, dataset in points:
        config, hdl, tb = config_spec(conv, algo, macs, dataset)
        missing = [str(ROOT / path) for path in hdl + [tb] if not (ROOT / path).is_file()]
        if missing:
            raise FileNotFoundError("missing flow inputs:\n" + "\n".join(missing))
        print(f"{config.relative_to(ROOT)}")
        if not args.dry_run:
            build_config(config, hdl, tb, conv)


if __name__ == "__main__":
    main()
