#!/usr/bin/env python3
"""Collect reproducible quality metrics and provenance for simulation datasets."""

import csv
import hashlib
import json
import math
import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
METRIC_FIELDS = [
    "size",
    "algorithm",
    "architecture",
    "dataset",
    "dataset_mode",
    "generation_seed",
    "generator_revision",
    "nbits",
    "weight_nbits",
    "quant_bits",
    "weight_transform_scale",
    "exact_scaled_weights",
    "truncated_weight_transform",
    "raw_spatial_weights",
    "image_side",
    "input_height",
    "input_width",
    "input_depth",
    "output_height",
    "output_width",
    "output_depth",
    "kernel_size_h",
    "kernel_size_w",
    "stride",
    "pad_size_h",
    "pad_size_w",
    "dataset_scale",
    "relu",
    "bias_enabled",
    "count",
    "quantized_count",
    "reference_count",
    "mae",
    "rmse",
    "max_abs",
    "max_rel",
    "r2_computed",
    "r2_library",
    "float_reference_mismatch_count",
    "float_reference_mismatch_rate",
    "quantized_golden_count",
    "quantized_golden_source_count",
    "quantized_golden_mae_codes",
    "quantized_golden_rmse_codes",
    "quantized_golden_max_abs_codes",
    "quantized_golden_mismatch_count",
    "quantized_golden_mismatch_rate",
    "naive_convolutions",
    "naive_multiplications",
    "naive_additions",
    "fast_convolutions",
    "fast_multiplications",
    "fast_additions",
    "pack_data_sha256",
    "s_sha256",
    "s_default_sha256",
]


def _read_lines(path):
    return [line.strip() for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _sha256(path):
    if not path.is_file():
        return None
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def synthesis_architectures_for_datasets(root):
    """Map datasets used by executed configs in active conv?x?/synthesis."""
    root = Path(root).resolve()
    architectures = {}
    for architecture_root in sorted(root.glob("rtl/conv?x?")):
        if not architecture_root.is_dir():
            continue
        synthesis_root = architecture_root / "synthesis"
        if not synthesis_root.is_dir():
            continue
        for list_file in sorted(synthesis_root.rglob("list-file.txt")):
            project_dir = list_file.parent
            relative_parts = project_dir.relative_to(synthesis_root).parts
            if not relative_parts or any(
                part in {"source", "template"} for part in relative_parts
            ):
                continue
            if len(relative_parts) > 1 and not (
                relative_parts[0] == "conv" and len(relative_parts) == 2
            ):
                continue
            has_results = (
                (project_dir / "sim" / "xrun.log").is_file()
                or (project_dir / "power" / "power_evaluation.txt").is_file()
                or any((project_dir / "logical" / "results").rglob("*.rpt"))
                or any((project_dir / "logical" / "results").rglob("*_mapped.v"))
            )
            if not has_results:
                continue
            for entry in _read_lines(list_file):
                candidate = Path(entry)
                if not candidate.is_absolute():
                    candidate = root / candidate
                if candidate.name != "pack_data.sv":
                    continue
                dataset = candidate.resolve().parent
                if not dataset.is_relative_to(root):
                    continue
                dataset_name = dataset.relative_to(root).as_posix()
                architectures.setdefault(dataset_name, set()).add(project_dir.name)
    return architectures


def _parse_sim_summary(path):
    content = path.read_text(encoding="utf-8", errors="replace") if path.is_file() else ""
    summary = {}
    labels = {
        "Image side": "image_side",
        "Quantization bits": "quant_bits",
        "Exact scaled weight transform": "exact_scaled_weights",
        "Truncated weight transform": "truncated_weight_transform",
        "Weight transform scale": "weight_transform_scale",
        "Bias enabled": "bias_enabled",
        "R2": "r2_library",
    }
    for source, target in labels.items():
        match = re.search(rf"^{re.escape(source)}:\s*(.+?)\s*$", content, re.MULTILINE | re.IGNORECASE)
        if not match:
            continue
        value = match.group(1)
        if target in {"exact_scaled_weights", "truncated_weight_transform", "bias_enabled"}:
            summary[target] = value.lower() in {"true", "1", "yes"}
        elif target in {"image_side", "quant_bits", "weight_transform_scale"}:
            try:
                summary[target] = int(value)
            except ValueError:
                summary[target] = None
        else:
            try:
                summary[target] = float(value)
            except ValueError:
                summary[target] = None
    for section, prefix in (("Naive", "naive"), ("Fast", "fast")):
        section_match = re.search(rf"^{section}\s*$([\s\S]*?)(?=^(?:Naive|Fast)\s*$|\Z)", content, re.MULTILINE)
        if not section_match:
            continue
        for label in ("Convolutions", "Multiplications", "Additions"):
            match = re.search(rf"^{label}:\s*(\d+)\s*$", section_match.group(1), re.MULTILINE)
            if match:
                summary[f"{prefix}_{label.lower()}"] = int(match.group(1))
    return summary


def _package_constants(path):
    if not path.is_file():
        return {}
    content = path.read_text(encoding="utf-8", errors="replace")
    constants = {}
    for name in ("NBITS", "WEIGHT_NBITS", "QUANT_BITS", "WEIGHT_TRANSFORM_SCALE", "EXACT_SCALED_WEIGHTS", "TRUNCATED_WEIGHT_TRANSFORM", "RAW_SPATIAL_WEIGHTS"):
        match = re.search(rf"\b{name}\s*=\s*(-?\d+)\s*;", content)
        if match:
            constants[name.lower()] = int(match.group(1))
    return constants


def _compute_quality(sim_dir, summary, constants):
    quant_path = sim_dir / "s.txt"
    reference_path = sim_dir / "s_default.txt"
    if not quant_path.is_file() or not reference_path.is_file():
        return None
    quantized = [int(float(value)) for value in _read_lines(quant_path)]
    reference = [float(value) for value in _read_lines(reference_path)]
    count = min(len(quantized), len(reference))
    if count == 0:
        return None
    quantized = quantized[:count]
    reference = reference[:count]
    quant_bits = summary.get("quant_bits", constants.get("quant_bits"))
    if quant_bits is None:
        return None
    scale = 2**quant_bits
    estimates = [value / scale for value in quantized]
    errors = [estimate - target for estimate, target in zip(estimates, reference)]
    absolute = [abs(error) for error in errors]
    mae = sum(absolute) / count
    rmse = math.sqrt(sum(error * error for error in errors) / count)
    max_abs = max(absolute)
    max_rel = max(err / max(abs(target), 1e-9) for err, target in zip(absolute, reference))
    mean_reference = sum(reference) / count
    total_variance = sum((target - mean_reference) ** 2 for target in reference)
    r2 = None if total_variance == 0 else 1 - sum(error * error for error in errors) / total_variance
    mismatches = sum(value != math.trunc(target * scale) for value, target in zip(quantized, reference))
    result = {
        "count": count,
        "mae": mae,
        "rmse": rmse,
        "max_abs": max_abs,
        "max_rel": max_rel,
        "r2_computed": r2,
        "float_reference_mismatch_count": mismatches,
        "float_reference_mismatch_rate": mismatches / count,
        "quantized_count": len(_read_lines(quant_path)),
        "reference_count": len(_read_lines(reference_path)),
    }
    quantized_golden_path = sim_dir / "s_default_quant.txt"
    if quantized_golden_path.is_file():
        quantized_golden = [int(float(value)) for value in _read_lines(quantized_golden_path)]
        golden_count = min(len(quantized), len(quantized_golden))
        expected = [value // scale for value in quantized_golden[:golden_count]]
        golden_errors = [
            value - target
            for value, target in zip(quantized[:golden_count], expected)
        ]
        golden_absolute = [abs(value) for value in golden_errors]
        golden_mismatches = sum(
            value != target
            for value, target in zip(quantized[:golden_count], expected)
        )
        result.update(
            {
                "quantized_golden_count": golden_count,
                "quantized_golden_source_count": len(quantized_golden),
                "quantized_golden_mae_codes": (
                    sum(golden_absolute) / golden_count if golden_count else None
                ),
                "quantized_golden_rmse_codes": (
                    math.sqrt(sum(value * value for value in golden_errors) / golden_count)
                    if golden_count
                    else None
                ),
                "quantized_golden_max_abs_codes": (
                    max(golden_absolute) if golden_count else None
                ),
                "quantized_golden_mismatch_count": golden_mismatches,
                "quantized_golden_mismatch_rate": (
                    golden_mismatches / golden_count if golden_count else None
                ),
            }
        )
    else:
        result.update(
            {
                "quantized_golden_count": None,
                "quantized_golden_source_count": None,
                "quantized_golden_mae_codes": None,
                "quantized_golden_rmse_codes": None,
                "quantized_golden_max_abs_codes": None,
                "quantized_golden_mismatch_count": None,
                "quantized_golden_mismatch_rate": None,
            }
        )
    return result


def collect_dataset_metrics(root=REPO_ROOT, architecture=None, include_datasets=()):
    root = Path(root).resolve()
    synthesis_architectures = synthesis_architectures_for_datasets(root)
    dataset_architectures = {
        dataset: set(configurations)
        for dataset, configurations in synthesis_architectures.items()
    }
    for requested_dataset in include_datasets:
        requested_path = Path(requested_dataset)
        dataset_path = (
            requested_path.resolve()
            if requested_path.is_absolute()
            else (root / requested_path).resolve()
        )
        if not dataset_path.is_relative_to(root):
            raise ValueError(f"Dataset must be inside repository root: {requested_dataset}")
        if not dataset_path.is_dir():
            raise ValueError(f"Dataset directory does not exist: {requested_dataset}")
        dataset_name = dataset_path.relative_to(root).as_posix()
        required_files = ("pack_data.sv", "s.txt", "s_default.txt")
        if not all((dataset_path / name).is_file() for name in required_files):
            raise ValueError(
                f"Dataset needs pack_data.sv, s.txt, and s_default.txt: {dataset_name}"
            )
        dataset_architectures.setdefault(dataset_name, set())
    rows = []
    for dataset_name in sorted(dataset_architectures):
        sim_dir = root / dataset_name
        if not sim_dir.is_dir():
            continue
        arch = next(
            (
                part
                for part in Path(dataset_name).parts
                if re.fullmatch(r"conv\d+x\d+", part)
            ),
            None,
        )
        if arch is None:
            continue
        if architecture is not None and arch != architecture:
            continue
        algorithm = sim_dir.parents[1].name
        package = sim_dir / "pack_data.sv"
        sim_summary_path = sim_dir / "sim.txt"
        summary = _parse_sim_summary(sim_summary_path)
        constants = _package_constants(package)
        params_path = sim_dir / "winocnn" / "params.json"
        try:
            dataset_parameters = json.loads(params_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            dataset_parameters = {}
        generation_path = sim_dir / "generation.json"
        try:
            generation_metadata = json.loads(generation_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            generation_metadata = {}
        quality = _compute_quality(sim_dir, summary, constants)
        if quality is None:
            continue
        architecture_names = sorted(dataset_architectures.get(dataset_name, ()))
        row = {
            "size": arch.removeprefix("conv"),
            "algorithm": algorithm,
            "architecture": "; ".join(architecture_names)
            if architecture_names
            else "DATASET ONLY (not referenced by active synthesis)",
            "dataset": dataset_name,
            "dataset_mode": (
                "exact-scaled"
                if constants.get("exact_scaled_weights", summary.get("exact_scaled_weights", False))
                else "truncated"
                if constants.get("truncated_weight_transform", summary.get("truncated_weight_transform", False))
                else "standard"
            ),
            "generation_seed": generation_metadata.get("workload", {}).get("seed"),
            "generator_revision": generation_metadata.get("generator", {}).get("revision"),
            "nbits": constants.get("nbits"),
            "weight_nbits": constants.get("weight_nbits"),
            "quant_bits": summary.get("quant_bits", constants.get("quant_bits")),
            "weight_transform_scale": summary.get("weight_transform_scale", constants.get("weight_transform_scale")),
            "exact_scaled_weights": bool(constants.get("exact_scaled_weights", summary.get("exact_scaled_weights", False))),
            "truncated_weight_transform": bool(constants.get("truncated_weight_transform", summary.get("truncated_weight_transform", False))),
            "raw_spatial_weights": bool(constants.get("raw_spatial_weights", False)),
            "image_side": summary.get("image_side"),
            "input_height": dataset_parameters.get("input_height"),
            "input_width": dataset_parameters.get("input_width"),
            "input_depth": dataset_parameters.get("input_depth"),
            "output_height": dataset_parameters.get("output_height"),
            "output_width": dataset_parameters.get("output_width"),
            "output_depth": dataset_parameters.get("output_depth"),
            "kernel_size_h": dataset_parameters.get("kernel_size_h"),
            "kernel_size_w": dataset_parameters.get("kernel_size_w"),
            "stride": dataset_parameters.get("stride"),
            "pad_size_h": dataset_parameters.get("pad_size_h"),
            "pad_size_w": dataset_parameters.get("pad_size_w"),
            "dataset_scale": dataset_parameters.get("scale"),
            "relu": dataset_parameters.get("relu"),
            "bias_enabled": summary.get("bias_enabled"),
            **quality,
            "r2_library": summary.get("r2_library"),
            "naive_convolutions": summary.get("naive_convolutions"),
            "naive_multiplications": summary.get("naive_multiplications"),
            "naive_additions": summary.get("naive_additions"),
            "fast_convolutions": summary.get("fast_convolutions"),
            "fast_multiplications": summary.get("fast_multiplications"),
            "fast_additions": summary.get("fast_additions"),
            "pack_data_sha256": _sha256(package),
            "s_sha256": _sha256(sim_dir / "s.txt"),
            "s_default_sha256": _sha256(sim_dir / "s_default.txt"),
        }
        row["lengths_match"] = quality["quantized_count"] == quality["reference_count"]
        # Record every parsed simulation parameter and file summary beside the dataset.
        metrics_document = {
            "schema": "fastconv-dataset-metrics/v2",
            "dataset": row,
            "dataset_parameters": dataset_parameters,
            "generation_metadata": generation_metadata,
            "simulation_summary": summary,
            "simulation_summary_text": (
                sim_summary_path.read_text(encoding="utf-8", errors="replace")
                if sim_summary_path.is_file()
                else None
            ),
            "package_constants": constants,
            "source_hashes": {
                path.relative_to(sim_dir).as_posix(): _sha256(path)
                for path in sorted(sim_dir.rglob("*"))
                if path.is_file()
                and path.name != "metrics.json"
                and path.suffix.lower() in {".sv", ".txt", ".json", ".md"}
            },
            "metric_definition": {
                "reference": "s_default.txt",
                "estimate": "s.txt / 2**quant_bits",
                "float_reference_mismatch": "s.txt integer differs from trunc(s_default.txt * 2**quant_bits)",
                "quantized_golden": "s.txt integer compared with s_default_quant.txt arithmetic-shifted right by quant_bits; error metrics are in output integer codes",
                "relative_error_epsilon": 1e-9,
                "r2_computed": "1 - sum((estimate-reference)^2) / sum((reference-mean(reference))^2)",
            },
        }
        (sim_dir / "metrics.json").write_text(
            json.dumps(metrics_document, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        rows.append(row)
    return rows


def aggregate_dataset_quality(rows, root=REPO_ROOT):
    """Pool sample-level errors across datasets using each dataset's own scale.

    The aggregate is not an average of dataset metrics: each output sample has
    equal weight, and each dataset is dequantized with its own ``quant_bits``.
    """
    root = Path(root).resolve()
    references = []
    absolute_errors = []
    squared_error_sum = 0.0
    max_relative_error = 0.0
    mismatch_count = 0
    quantized_count = 0
    reference_count = 0
    golden_source_count = 0
    golden_count = 0
    golden_abs_sum = 0.0
    golden_squared_sum = 0.0
    golden_max_abs = 0
    golden_mismatch_count = 0

    for row in rows:
        sim_dir = root / row["dataset"]
        quantized = [int(float(value)) for value in _read_lines(sim_dir / "s.txt")]
        reference = [float(value) for value in _read_lines(sim_dir / "s_default.txt")]
        quantized_count += len(quantized)
        reference_count += len(reference)
        count = min(len(quantized), len(reference))
        if count == 0:
            continue

        scale = 2 ** int(row["quant_bits"])
        for value, target in zip(quantized[:count], reference[:count]):
            error = value / scale - target
            absolute = abs(error)
            references.append(target)
            absolute_errors.append(absolute)
            squared_error_sum += error * error
            max_relative_error = max(
                max_relative_error, absolute / max(abs(target), 1e-9)
            )
            mismatch_count += value != math.trunc(target * scale)

        golden_path = sim_dir / "s_default_quant.txt"
        if golden_path.is_file():
            golden = [int(float(value)) for value in _read_lines(golden_path)]
            golden_source_count += len(golden)
            paired = min(len(quantized), len(golden))
            for value, golden_value in zip(quantized[:paired], golden[:paired]):
                error_codes = value - (golden_value // scale)
                absolute_codes = abs(error_codes)
                golden_count += 1
                golden_abs_sum += absolute_codes
                golden_squared_sum += error_codes * error_codes
                golden_max_abs = max(golden_max_abs, absolute_codes)
                golden_mismatch_count += error_codes != 0

    count = len(references)
    if count == 0:
        raise ValueError("Cannot aggregate dataset metrics without paired samples")
    mae = math.fsum(absolute_errors) / count
    rmse = math.sqrt(squared_error_sum / count)
    mean_reference = math.fsum(references) / count
    total_variance = math.fsum(
        (value - mean_reference) ** 2 for value in references
    )
    r2 = None if total_variance == 0 else 1 - squared_error_sum / total_variance

    aggregate = {field: None for field in METRIC_FIELDS}
    aggregate.update(
        {
            "size": "ALL",
            "algorithm": "ALL",
            "architecture": "ALL",
            "dataset": "ALL (pooled)",
            "dataset_mode": "pooled",
            "count": count,
            "quantized_count": quantized_count,
            "reference_count": reference_count,
            "mae": mae,
            "rmse": rmse,
            "max_abs": max(absolute_errors),
            "max_rel": max_relative_error,
            "r2_computed": r2,
            "float_reference_mismatch_count": mismatch_count,
            "float_reference_mismatch_rate": mismatch_count / count,
            "quantized_golden_count": golden_count,
            "quantized_golden_source_count": golden_source_count,
            "quantized_golden_mae_codes": (
                golden_abs_sum / golden_count if golden_count else None
            ),
            "quantized_golden_rmse_codes": (
                math.sqrt(golden_squared_sum / golden_count)
                if golden_count
                else None
            ),
            "quantized_golden_max_abs_codes": (
                golden_max_abs if golden_count else None
            ),
            "quantized_golden_mismatch_count": golden_mismatch_count,
            "quantized_golden_mismatch_rate": (
                golden_mismatch_count / golden_count if golden_count else None
            ),
            "lengths_match": all(
                row.get("lengths_match", False) for row in rows
            ),
        }
    )
    return aggregate


def write_dataset_metrics(
    report_dir,
    root=REPO_ROOT,
    architecture=None,
    filename="functional-quality.csv",
    include_datasets=(),
):
    rows = collect_dataset_metrics(
        root=root, architecture=architecture, include_datasets=include_datasets
    )
    path = Path(report_dir) / filename
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = METRIC_FIELDS + ["lengths_match"]
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows({key: row.get(key) for key in fields} for row in rows)
    return rows, path
