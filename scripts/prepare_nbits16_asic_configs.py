#!/usr/bin/env python3
"""Create isolated 16-bit ASIC configs while pinning existing configs to 20 bits."""

from __future__ import annotations

import shutil
import hashlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ARCHITECTURES = ("conv2x2", "conv3x3", "conv4x4")
IGNORE_DIRS = {
    "results",
    "diagnostics",
    "work",
    "work_gate",
    "work_gate_final",
    "xcelium.d",
    "INCA_libs",
    "waves.shm",
}
IGNORE_FILES = {
    "genus.log",
    "genus.cmd",
    "xrun.log",
    "power_evaluation.txt",
    "dut.shm",
    "dump.vcd",
    "dump.fst",
    "FLOW_STATUS.md",
    "flow.log",
    "execution_time.txt",
    "sdf_log.log",
    "power_evaluation.invalid_before_p_end_fix.txt",
    "xrun_nosdf.log",
    "rtl_verilator.log",
    "execution_time_gate.txt",
    "args_nosdf_diag.txt",
}


def ignore_generated(_directory: str, names: list[str]) -> set[str]:
    return {
        name
        for name in names
        if name in IGNORE_DIRS
        or name in IGNORE_FILES
        or name.endswith(".log")
        or name.endswith(".cmd")
    }


def read_first(path: Path) -> str:
    for line in path.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            return line
    raise ValueError(f"no active entry in {path}")


def write_parameter(path: Path, name: str, value: int) -> None:
    lines = path.read_text().splitlines() if path.exists() else []
    output = []
    found = False
    for line in lines:
        if line.strip().startswith(f"{name}="):
            if not found:
                output.append(f"{name}={value}")
                found = True
        else:
            output.append(line)
    if not found:
        output.append(f"{name}={value}")
    path.write_text("\n".join(output).rstrip() + "\n")


def replace_define(path: Path, name: str, value: int) -> None:
    lines = path.read_text().splitlines() if path.exists() else []
    output = []
    found = False
    for line in lines:
        stripped = line.strip()
        if stripped.startswith(f"-define {name}=") or stripped.startswith(f"{name}="):
            if not found:
                output.append(f"-define {name}={value}")
                found = True
        else:
            output.append(line)
    if not found:
        output.append(f"-define {name}={value}")
    path.write_text("\n".join(output).rstrip() + "\n")


def remove_define(path: Path, name: str) -> None:
    if not path.exists():
        return
    lines = [
        line
        for line in path.read_text().splitlines()
        if not line.strip().startswith(f"-define {name}=")
        and not line.strip().startswith(f"{name}=")
    ]
    path.write_text("\n".join(lines).rstrip() + "\n")


def dataset_for(architecture: str, algorithm: str) -> Path:
    if architecture == "conv2x2":
        family = "tcn4"
    else:
        family = algorithm
    path = ROOT / "rtl" / architecture / "data" / family / "sim" / (
        "sim-032-3-3-normal-trunc-nbits16"
    ) / "pack_data.sv"
    if not path.is_file():
        raise FileNotFoundError(path)
    return path


def config_for_source(architecture: str, source: Path, configs: list[Path]) -> Path:
    expected_stem = source.stem
    matches = [path for path in configs if path.name == expected_stem]
    if matches:
        return matches[0]
    if architecture == "conv3x3" and "tcn9" in source.name:
        # The prefetch-10 RTL shares the same flow scripts and dataset contract
        # as the already configured prefetch-15 TCN9 source.
        matches = [path for path in configs if path.name.startswith("conv-tcn9-")]
        if matches:
            return matches[0]
    if architecture == "conv2x2":
        # The active 2x2 column RTL did not yet have its own ASIC config.
        matches = sorted(
            (ROOT / "rtl" / "conv3x3" / "synthesis").glob("conv-tcn9-*")
        )
        if matches:
            return matches[0]
    raise FileNotFoundError(f"no config template for {source}")


def prepare_20bit_pins(architecture: str, configs: list[Path]) -> None:
    source_names = {
        path.name for path in (ROOT / "rtl" / architecture).glob("conv-*.sv")
    }
    for config in configs:
        if config.name.endswith("-nbits16"):
            continue
        list_file = config / "list-file.txt"
        if not list_file.exists():
            continue
        entries = [line.strip() for line in list_file.read_text().splitlines()]
        if not any(Path(entry).name in source_names for entry in entries if entry and not entry.startswith("#")):
            continue
        write_parameter(config / "top-parameters.txt", "NBITS", 20)


def prepare_16bit_config(architecture: str, source: Path, template: Path) -> Path:
    config = ROOT / "rtl" / architecture / "synthesis" / f"{source.stem}-nbits16"
    package = dataset_for(architecture, source.name.split("-")[1])
    peers = sorted(
        path
        for path in (ROOT / "rtl" / architecture / "synthesis").iterdir()
        if path.is_dir() and not path.name.endswith("-nbits16") and path != template
    )
    if config.exists():
        print(f"preserving existing config: {config.relative_to(ROOT)}")
        write_parameter(config / "top-parameters.txt", "NBITS", 16)
        dataset_hash = hashlib.sha256(package.read_bytes()).hexdigest()
        (config / "run-provenance.txt").write_text(
            "NBITS=16\n"
            "workload=32x32,Cin3,Cout3,kernel3x3,seed0,truncated-weight-transform\n"
            f"rtl={source.relative_to(ROOT)}\n"
            f"dataset={package.relative_to(ROOT)}\n"
            f"dataset_sha256={dataset_hash}\n"
            "generator_repository=fast-convolution-rtl\n"
            "generator_commit=cbe17748b9f18dd5dbe0312150dec5ed2e65d236 (dirty worktree)\n"
        )
        for stage in ("sim", "power"):
            if (config / stage / "run.sh").is_file():
                continue
            peer = next(
                (candidate for candidate in peers if (candidate / stage / "run.sh").is_file()),
                None,
            )
            if peer is not None:
                shutil.copytree(peer / stage, config / stage, ignore=ignore_generated)
        return config
    shutil.copytree(template, config, ignore=ignore_generated)

    # Some historical configs (notably the WPN pipelined variant) contain
    # only the synthesis stage. Reuse missing stage runners from a peer config.
    for stage in ("sim", "power"):
        if (config / stage / "run.sh").is_file():
            continue
        peer = next(
            (candidate for candidate in peers if (candidate / stage / "run.sh").is_file()),
            None,
        )
        if peer is not None:
            shutil.copytree(peer / stage, config / stage, ignore=ignore_generated)

    list_file = config / "list-file.txt"
    lines = list_file.read_text().splitlines()
    mapped = []
    source_found = False
    package_found = False
    for line in lines:
        entry = line.strip()
        if not entry or entry.startswith("#"):
            mapped.append(line)
            continue
        if Path(entry).name.startswith("conv-") and Path(entry).suffix == ".sv":
            mapped.append(str(source.relative_to(ROOT)))
            source_found = True
        elif Path(entry).name == "pack_data.sv":
            mapped.append(str(package.relative_to(ROOT)))
            package_found = True
        else:
            mapped.append(line)
    if not source_found:
        raise ValueError(f"template did not contain a Conv source: {template}")
    if not package_found:
        raise ValueError(f"template did not contain pack_data.sv: {template}")
    list_file.write_text("\n".join(mapped) + "\n")

    write_parameter(config / "top-parameters.txt", "NBITS", 16)
    remove_define(config / "list-define.txt", "NBITS")
    if architecture == "conv2x2":
        mac_count = 4 if "-m04-" in source.name else 8
        (config / "list-file.txt").write_text(
            "\n".join(
                [
                    str(dataset_for(architecture, "tcn4").relative_to(ROOT)),
                    "rtl/conv2x2/pack-param/tcn4/pack_param.sv",
                    "rtl/conv2x2/mult-matrices/stream/tcn4/mult_matrices.sv",
                    "rtl/csa/csa_lib.sv",
                    "rtl/multip/multip.sv",
                    "rtl/mem/mem.sv",
                    str(source.relative_to(ROOT)),
                ]
            )
            + "\n"
        )
        write_parameter(config / "top-parameters.txt", "NUM_MULT", mac_count)
        (config / "testbench-file.txt").write_text(
            "rtl/conv2x2/testbench_prefetch8_column.sv\n"
        )
        (config / "sim" / "args.txt").write_text(
            (config / "sim" / "args.txt").read_text().replace(
                "-top tb_stream_column", "-top tb_prefetch8_column"
            )
        )
        define_file = config / "list-define.txt"
        defines = [
            line
            for line in define_file.read_text().splitlines()
            if not line.strip().startswith("-define ASIC_NUM_MULT=")
        ]
        with define_file.open("w") as stream:
            stream.write("\n".join(defines).rstrip() + "\n")
            stream.write("-define NBITS16\n")
            stream.write(f"-define ASIC_NUM_MULT={mac_count}\n")
    dataset_hash = hashlib.sha256(package.read_bytes()).hexdigest()
    (config / "run-provenance.txt").write_text(
        "NBITS=16\n"
        "workload=32x32,Cin3,Cout3,kernel3x3,seed0,truncated-weight-transform\n"
        f"rtl={source.relative_to(ROOT)}\n"
        f"dataset={package.relative_to(ROOT)}\n"
        f"dataset_sha256={dataset_hash}\n"
        "generator_repository=fast-convolution-rtl\n"
        "generator_commit=cbe17748b9f18dd5dbe0312150dec5ed2e65d236 (dirty worktree)\n"
    )
    return config


def main() -> None:
    generated = []
    for architecture in ARCHITECTURES:
        synthesis_root = ROOT / "rtl" / architecture / "synthesis"
        configs = sorted(path for path in synthesis_root.iterdir() if path.is_dir())
        prepare_20bit_pins(architecture, configs)
        sources = sorted((ROOT / "rtl" / architecture).glob("conv-*.sv"))
        for source in sources:
            template = config_for_source(architecture, source, configs)
            generated.append(prepare_16bit_config(architecture, source, template))
    for config in generated:
        print(config.relative_to(ROOT))
    print(f"created={len(generated)}")


if __name__ == "__main__":
    main()
