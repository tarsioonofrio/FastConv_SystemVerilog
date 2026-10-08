#!/usr/bin/env python3
"""Prepare isolated ASIC configurations for the Cin=3, Cout=12 workload."""

from __future__ import annotations

import hashlib
import json
import re
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SUFFIX = "-cin3-cout12"
FAST_CONVOLUTION_RTL_REVISION = "5c021aabc87136efb03a329d86f3e833af1abd42"


def active_configs() -> list[tuple[str, Path, str, int]]:
    configs: list[tuple[str, Path, str, int]] = []

    for path in sorted((ROOT / "rtl/conv2x2/synthesis").iterdir()):
        if path.is_dir() and not path.name.endswith(SUFFIX):
            configs.append(
                (
                    "conv2x2",
                    path,
                    "rtl/conv2x2/data/tcn4/sim/"
                    "sim-032-3-12-normal-trunc-nbits16/pack_data.sv",
                    16,
                )
            )

    for path in sorted((ROOT / "rtl/conv3x3/synthesis").iterdir()):
        if not path.is_dir() or path.name.endswith(SUFFIX):
            continue
        if "ifn9" in path.name:
            algorithm = "ifn9"
        elif "tcn9" in path.name:
            algorithm = "tcn9"
        else:
            continue
        configs.append(
            (
                "conv3x3",
                path,
                f"rtl/conv3x3/data/{algorithm}/sim/"
                "sim-032-3-12-normal-trunc-nbits16/pack_data.sv",
                16,
            )
        )

    conv4x4 = ROOT / "rtl/conv4x4/synthesis"
    for path in sorted(conv4x4.iterdir()):
        if not path.is_dir() or path.name.endswith(SUFFIX):
            continue
        if path.name.startswith("conv-wpn16") and path.name.endswith("-nbits16"):
            package = (
                "rtl/conv4x4/data/wpn16/sim/"
                "sim-032-3-12-normal-trunc-nbits16/pack_data.sv"
            )
            nbits = 16
        elif path.name.startswith("conv-tcn16") and "pretransformed-column" in path.name:
            package = (
                "rtl/conv4x4/data/tcn16/sim/"
                "sim-032-3-12-normal-trunc-nbits20/pack_data.sv"
            )
            nbits = 20
        elif path.name.startswith("conv-tcn16") and "trunc-frac6-column" in path.name:
            package = (
                "rtl/conv4x4/data/tcn16/sim/"
                "sim-032-3-12-normal-trunc-frac6-nbits20/pack_data.sv"
            )
            nbits = 20
        else:
            continue
        configs.append(("conv4x4", path, package, nbits))

    return configs


def copy_static_config(source: Path, destination: Path) -> None:
    if destination.exists():
        if not (destination / "WORKLOAD.md").is_file():
            raise FileExistsError(f"refusing to overwrite {destination}")
        return
    destination.mkdir(parents=True)

    root_files = (
        "list-define.txt",
        "list-file.txt",
        "rtl-top-file.txt",
        "testbench-file.txt",
        "top-module.txt",
        "top-parameters.txt",
    )
    for name in root_files:
        source_file = source / name
        if source_file.is_file():
            shutil.copy2(source_file, destination / name)

    for directory, names in {
        "scripts": None,
        "logical": ("run.sh", "logical_synthesis.tcl"),
        "sim": ("run.sh", "args.txt", "sdf_cmd.cmd"),
        "power": ("run.sh", "power.tcl"),
    }.items():
        source_dir = source / directory
        if not source_dir.is_dir():
            continue
        target_dir = destination / directory
        target_dir.mkdir(parents=True, exist_ok=True)
        if names is None:
            shutil.copytree(source_dir, target_dir, dirs_exist_ok=True)
        else:
            for name in names:
                source_file = source_dir / name
                if source_file.is_file():
                    shutil.copy2(source_file, target_dir / name)


def set_sdf_scope(config: Path) -> None:
    """Match the timing annotation scope to the configured testbench top."""
    testbench_entry = next(
        (
            line.strip()
            for line in (config / "testbench-file.txt").read_text().splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        ),
        None,
    )
    if testbench_entry is None:
        raise RuntimeError(f"no testbench entry in {config / 'testbench-file.txt'}")
    testbench_path = Path(testbench_entry)
    if not testbench_path.is_absolute():
        testbench_path = ROOT / testbench_path
    source = testbench_path.read_text()
    match = re.search(r"(?m)^\s*module\s+(tb_[A-Za-z0-9_$]+)\b", source)
    if match is None:
        raise RuntimeError(f"cannot find testbench top module in {testbench_path}")
    scope = f"{match.group(1)}.dut"

    sdf_command = config / "sim/sdf_cmd.cmd"
    text = sdf_command.read_text()
    updated, replacements = re.subn(
        r"(?m)^\s*SCOPE\s*=\s*[^;]+;",
        f"SCOPE = {scope};",
        text,
    )
    if replacements != 1:
        raise RuntimeError(f"expected one SCOPE entry in {sdf_command}")
    sdf_command.write_text(updated)


def wrap_long_vector_lines(package_path: Path) -> None:
    """Keep generated one-dimensional array rows below simulator token limits."""
    result = []
    changed = False
    for line in package_path.read_text().splitlines():
        stripped = line.strip()
        if len(line) <= 10000:
            result.append(line)
            continue
        if not re.fullmatch(r"-?\d+(?:,\s*-?\d+)*", stripped):
            raise RuntimeError(f"cannot safely reflow long SV line in {package_path}")
        values = [value.strip() for value in stripped.split(",")]
        for offset in range(0, len(values), 16):
            chunk = values[offset : offset + 16]
            suffix = "," if offset + len(chunk) < len(values) else ""
            result.append("    " + ", ".join(chunk) + suffix)
        changed = True
    if changed:
        package_path.write_text("\n".join(result) + "\n")


def main() -> None:
    configs = active_configs()
    if len(configs) != 19:
        raise RuntimeError(f"expected 19 active ASIC configs, found {len(configs)}")

    for arch, source, package, nbits in configs:
        package_path = ROOT / package
        if not package_path.is_file():
            raise FileNotFoundError(package_path)
        if not (source / "list-file.txt").is_file():
            raise FileNotFoundError(source / "list-file.txt")

    packages = {package for _, _, package, _ in configs}
    for package in packages:
        wrap_long_vector_lines(ROOT / package)

    manifest_rows = []
    for arch, source, package, nbits in configs:
        destination = source.with_name(source.name + SUFFIX)
        copy_static_config(source, destination)
        set_sdf_scope(destination)

        list_file = destination / "list-file.txt"
        lines = list_file.read_text().splitlines()
        replaced = [
            package if "/data/" in line and line.rstrip().endswith("pack_data.sv") else line
            for line in lines
        ]
        if replaced == lines and package not in lines:
            raise RuntimeError(f"no pack_data.sv entry in {list_file}")
        list_file.write_text("\n".join(replaced) + "\n")

        parameter_file = destination / "top-parameters.txt"
        parameters = parameter_file.read_text().splitlines() if parameter_file.exists() else []
        parameters = [
            line
            for line in parameters
            if not line.startswith(("N_CHANNEL_IN=", "N_CHANNEL_OUT="))
        ]
        parameters.extend(("N_CHANNEL_IN=3", "N_CHANNEL_OUT=12"))
        parameter_file.write_text("\n".join(parameters) + "\n")

        (destination / "WORKLOAD.md").write_text(
            "# ASIC workload: Cin=3, Cout=12\n\n"
            f"Source configuration: `{source.relative_to(ROOT)}`.\n\n"
            f"Workload package: `{package}`.\n\n"
            f"Top overrides: `NBITS={nbits}`, `N_CHANNEL_IN=3`, `N_CHANNEL_OUT=12`.\n\n"
            "This is a separate configuration so the original Cin=3, Cout=3 "
            "netlist, simulation, and power evidence remain unchanged. Run the "
            "full flow with `make flow ARCH="
            f"{arch} CONFIG={destination.name}` inside tmux.\n"
        )

        package_sha = hashlib.sha256((ROOT / package).read_bytes()).hexdigest()
        manifest_rows.append(
            f"| `{destination.relative_to(ROOT)}` | `{package}` | {nbits} | `{package_sha}` |"
        )

    for package in sorted(packages):
        dataset_dir = (ROOT / package).parent
        package_text = (ROOT / package).read_text()
        sim_text = (dataset_dir / "sim.txt").read_text()
        nbits_match = re.search(r"\bNBITS\s*=\s*(\d+)", package_text)
        scale_match = re.search(r"Weight transform scale:\s*(\d+)", sim_text)
        r2_match = re.search(r"^R2:\s*(\S+)", sim_text, re.MULTILINE)
        frac_match = re.search(r"\bWEIGHT_TRANSFORM_FRAC_BITS\s*=\s*(\d+)", package_text)
        frac_bits = int(frac_match.group(1)) if frac_match else 0
        metadata = {
            "workload": {
                "image_side": 32,
                "channel_in": 3,
                "channel_out": 12,
                "kernel_size": 3,
                "seed": 0,
                "quant_bits": 8,
                "nbits": int(nbits_match.group(1)) if nbits_match else None,
                "weight_transform_scale": int(scale_match.group(1)) if scale_match else None,
                "weight_transform_frac_bits": frac_bits,
                "truncated_weight_transform": True,
            },
            "generator": {
                "project": "fast-convolution-rtl",
                "revision": FAST_CONVOLUTION_RTL_REVISION,
                "method": (
                    "generate_trunc_frac8_nbits16.py with WEIGHT_FRAC_BITS=6"
                    if frac_bits
                    else "fast_convolution.cli sim normal"
                ),
            },
            "artifacts": {
                "pack_data_sha256": hashlib.sha256((ROOT / package).read_bytes()).hexdigest(),
                "library_r2": float(r2_match.group(1)) if r2_match else None,
            },
        }
        (dataset_dir / "generation.json").write_text(
            json.dumps(metadata, indent=2, sort_keys=True) + "\n"
        )
        frac_description = (
            f" The TCN16 transformed weights retain {frac_bits} fractional bits."
            if frac_bits
            else ""
        )
        (dataset_dir / "README.md").write_text(
            "# Cin=3, Cout=12 workload package\n\n"
            "Canonical workload: 32x32 input, Cin=3, Cout=12, 3x3 kernel, "
            f"seed=0, NBITS={metadata['workload']['nbits']}, QUANT_BITS=8. "
            f"The transformed weights use scale {metadata['workload']['weight_transform_scale']} "
            f"with arithmetic-floor truncation.{frac_description}\n\n"
            "`pack_data.sv` is the package consumed by Xcelium. `sim.txt` records "
            "the library simulation summary; `generation.json` stores the workload, "
            "generator revision, R2, and package SHA-256.\n\n"
            f"Library-reported R2: {metadata['artifacts']['library_r2']}.\n"
        )

    package_rows = []
    for package in sorted(packages):
        pack_path = ROOT / package
        package_rows.append(
            f"| `{package}` | {hashlib.sha256(pack_path.read_bytes()).hexdigest()} |"
        )
    manifest = [
        "# Cin=3, Cout=12 ASIC power campaign",
        "",
        "The existing Cin=3, Cout=3 datasets and synthesis results are retained. "
        "This campaign creates a separate config for each active architecture/MAC "
        "variant, with explicit channel overrides and a matching generated pack.",
        "",
        "Common workload: image 32x32, Cin=3, Cout=12, seed=0, quantization=8 bits.",
        "",
        "## Dataset packages",
        "",
        "| Package | SHA-256 |",
        "| --- | --- |",
        *package_rows,
        "",
        "## New ASIC configurations",
        "",
        "| Config | Dataset | NBITS | pack_data SHA-256 |",
        "| --- | --- | ---: | --- |",
        *manifest_rows,
        "",
        "Run the full logical synthesis, gate-level SDF simulation, and Joules power "
        "flow in tmux with `scripts/run_cin3_cout12_asic_campaign.sh`.",
        "",
    ]
    (ROOT / "rtl/CIN3_COUT12_ASIC_CAMPAIGN.md").write_text("\n".join(manifest))
    print(f"Prepared {len(configs)} new configurations and {len(packages)} datasets.")


if __name__ == "__main__":
    main()
