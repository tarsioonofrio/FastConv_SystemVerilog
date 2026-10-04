#!/usr/bin/env python3
"""Create isolated Genus/Xcelium/Joules configs for the 3x3/4x4 ASIC sweep."""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def config_spec(
    conv: str, algo: str, macs: str, dataset: str
) -> tuple[Path, list[str], str, list[str]]:
    base = ROOT / "rtl" / conv
    name = f"asic-sweep-20261003-{algo}-m{macs.zfill(2)}"
    # Prepared but unexecuted configurations are kept out of synthesis/, which
    # contains only directories with actual ASIC result artifacts.
    # Parameterized conv.sv sweep configurations are grouped separately from
    # configurations that target dedicated RTL files.
    config = base / "asic_configs" / "conv" / name
    mux_suffix = macs.zfill(2)
    hdl = [
        "rtl/csa/csa_lib.sv",
        "rtl/multip/multip.sv",
        f"rtl/{conv}/data/{algo}/sim/{dataset}/pack_data.sv",
        f"rtl/{conv}/pack-param/{algo}/pack_param.sv",
        f"rtl/{conv}/mux-mult/{algo}/mux_mult_{mux_suffix}.sv",
        f"rtl/{conv}/mult-matrices/{algo}/mult_matrices.sv",
        f"rtl/{conv}/archive/conv.sv",
        "rtl/mem/mem.sv",
    ]
    if conv == "conv4x4":
        hdl.insert(2, "contrib/rtl/pack-def/pack_def.sv")
    tb = f"rtl/{conv}/testbench.sv"
    mux_path = ROOT / f"rtl/{conv}/mux-mult/{algo}/mux_mult_{mux_suffix}.sv"
    mux_text = mux_path.read_text()
    parameters = {}
    for name in ("NUM_MULT", "STATE_MULT"):
        match = re.search(
            rf"parameter\s+int\s+{name}\s*=\s*(\d+)\s*;", mux_text
        )
        if not match:
            raise ValueError(f"{mux_path} does not define {name}")
        parameters[name] = int(match.group(1))
    if parameters["NUM_MULT"] != int(macs):
        raise ValueError(
            f"{mux_path} declares NUM_MULT={parameters['NUM_MULT']}, expected {macs}"
        )
    top_parameters = [f"NUM_MULT={parameters['NUM_MULT']}",
                      f"STATE_MULT={parameters['STATE_MULT']}"]
    pack_param_path = ROOT / f"rtl/{conv}/pack-param/{algo}/pack_param.sv"
    pack_param_text = pack_param_path.read_text()
    pack_parameters = dict(
        re.findall(
            r"localparam\s+int\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([^;]+)\s*;",
            pack_param_text,
        )
    )

    def resolve_pack_parameter(parameter_name: str) -> int:
        expression = pack_parameters.get(parameter_name, "").strip()
        if expression.isdecimal():
            return int(expression)
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", expression):
            return resolve_pack_parameter(expression)
        raise ValueError(
            f"cannot resolve {parameter_name}={expression!r} in {pack_param_path}"
        )

    for parameter_name in ("CONV_OUTPUT_SIZE", "CONV_INPUT_SIZE", "HADAMARD_SIZE"):
        top_parameters.append(
            f"{parameter_name}={resolve_pack_parameter(parameter_name)}"
        )
    return config, hdl, tb, top_parameters


def build_config(
    config: Path,
    hdl: list[str],
    tb: str,
    conv: str,
    top_parameters: list[str],
) -> None:
    if config.exists():
        raise FileExistsError(f"refusing to overwrite existing config: {config}")
    source_config = ROOT / "rtl" / conv / "synthesis" / "conv" / (
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
    (config / "top-module.txt").write_text("Conv\n")
    (config / "top-parameters.txt").write_text("\n".join(top_parameters) + "\n")
    (config / "testbench-file.txt").write_text(tb + "\n")
    write_sdf_command(config, "Conv")


def write_sdf_command(config: Path, top_module: str) -> None:
    """Point Xcelium at the case-sensitive SDF filename emitted by Genus."""
    (config / "sim" / "sdf_cmd.cmd").write_text(
        "\n".join(
            (
                f'SDF_FILE = "../logical/results/gate_level/{top_module}_analysis_view_0p90v_25c_captyp_nominal.sdf",',
                'LOG_FILE = "./sdf_log.log",',
                "SCOPE = tb.dut;",
                'MTM_CONTROL = "MAXIMUM",',
                'SCALE_FACTORS = "1.0:1.0:1.0",',
                'SCALE_TYPE = "FROM_MAXIMUM";',
            )
        )
        + "\n"
    )


def refresh_elaboration_scripts(config: Path, conv: str) -> None:
    source_config = ROOT / "rtl" / conv / "synthesis" / "conv" / (
        "ifn9-06mac" if conv == "conv3x3" else "tcn16-18mac"
    )
    for relative in (
        "logical/logical_synthesis.tcl",
        "scripts/logical_synthesis_body.tcl",
    ):
        shutil.copy2(source_config / relative, config / relative)


def refresh_sim_annotation(config: Path, conv: str) -> None:
    top_module = (config / "top-module.txt").read_text().split()[0]
    write_sdf_command(config, top_module)
    source_config = ROOT / "rtl" / conv / "synthesis" / "conv" / (
        "ifn9-06mac" if conv == "conv3x3" else "tcn16-18mac"
    )
    sim_run = config / "sim" / "run.sh"
    shutil.copy2(source_config / "sim" / "run.sh", sim_run)
    sim_run.write_text(
        sim_run.read_text().replace(
            "module load xcelium", "module load cadence/xcelium/2303"
        )
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--update-parameters-only",
        action="store_true",
        help="write top-parameters.txt into existing generated sweep configs",
    )
    parser.add_argument(
        "--refresh-elaboration-scripts-only",
        action="store_true",
        help="refresh the two parameter-elaboration Tcl files in existing configs",
    )
    parser.add_argument(
        "--refresh-sim-annotation-only",
        action="store_true",
        help="refresh generated SDF command and preflight check in existing sweep configs",
    )
    args = parser.parse_args()
    if args.dry_run and (
        args.update_parameters_only
        or args.refresh_elaboration_scripts_only
        or args.refresh_sim_annotation_only
    ):
        parser.error("--dry-run cannot be combined with an update option")
    update_modes = sum(
        (args.update_parameters_only, args.refresh_elaboration_scripts_only, args.refresh_sim_annotation_only)
    )
    if update_modes > 1:
        parser.error("update options are mutually exclusive")

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
        config, hdl, tb, top_parameters = config_spec(conv, algo, macs, dataset)
        missing = [str(ROOT / path) for path in hdl + [tb] if not (ROOT / path).is_file()]
        if missing:
            raise FileNotFoundError("missing flow inputs:\n" + "\n".join(missing))
        print(f"{config.relative_to(ROOT)}: {' '.join(top_parameters)}")
        if args.update_parameters_only:
            if not config.is_dir():
                raise FileNotFoundError(f"config does not exist: {config}")
            (config / "top-parameters.txt").write_text(
                "\n".join(top_parameters) + "\n"
            )
        if args.refresh_elaboration_scripts_only:
            if not config.is_dir():
                raise FileNotFoundError(f"config does not exist: {config}")
            refresh_elaboration_scripts(config, conv)
        if args.refresh_sim_annotation_only:
            if not config.is_dir():
                raise FileNotFoundError(f"config does not exist: {config}")
            refresh_sim_annotation(config, conv)
        if not (
            args.update_parameters_only
            or args.refresh_elaboration_scripts_only
            or args.refresh_sim_annotation_only
            or args.dry_run
        ):
            build_config(config, hdl, tb, conv, top_parameters)


if __name__ == "__main__":
    main()
