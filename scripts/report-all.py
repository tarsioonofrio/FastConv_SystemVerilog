import argparse
import re
from pathlib import Path

import pandas as pd

EXCLUDED_PROJECTS = {"source", "template"}
REPO_ROOT = Path(__file__).resolve().parent.parent
SYS_NAIVE_PROJECT = "sys-naive"
SYS_NAIVE_SIDE = 32
SYS_NAIVE_DIR = (
    REPO_ROOT / ".." / "acc_dse_env" / "synthesis" / "convolution"
).resolve()
# Chapter-7 exports are kept inside this repository by default.  A different
# destination can be selected explicitly with ``--chapter7-dir``.
CHAPTER7_DIR = REPO_ROOT / "report" / "chapter7"


def strip_project_prefix(name):
    return re.sub(r"^(sys|conv)-?", "", name, flags=re.IGNORECASE)


def format_project_name(name):
    # Current synthesis projects are scoped by their RTL directory, for
    # example ``conv2x2/stream4/tcn4-04mac``.  Keep that scope in the report
    # key; otherwise configurations with the same tcn/ifn suffix collide.
    if name.lower().startswith("conv"):
        return "Conv" + name[4:]
    if name.lower().startswith("sys"):
        return "Sys" + name[3:]
    name = strip_project_prefix(name)
    if len(name) < 2:
        return name.upper()
    return f"{name[:2].upper()}{name[2:]}"


def project_name_from_report(path):
    """Return the synthesis project directory containing a report file."""
    return Path(path).parent.parent.parent.parent.name


def synthesis_projects():
    """Yield current project directories under each RTL architecture.

    Synthesis was moved from the repository-level ``synthesis/*`` layout to
    ``rtl/conv*/synthesis/*``.  The architecture directory is part of the
    identity so, for example, ``conv3x3/synthesis/ifn9-06mac`` and
    ``conv3x3stream-if/synthesis/ifn9-06mac`` remain distinct rows.
    """
    for synthesis_root in sorted(Path(REPO_ROOT).glob("rtl/conv*/synthesis")):
        architecture = synthesis_root.parent.name
        # Some families add one grouping directory (for example
        # ``conv2x2/synthesis/stream12/tcn4-04mac``), while others place the
        # project directly below ``synthesis``.  ``list-file.txt`` is the
        # common marker for an actual synthesis project.
        for list_file in sorted(synthesis_root.rglob("list-file.txt")):
            project_dir = list_file.parent
            if any(part in EXCLUDED_PROJECTS for part in project_dir.relative_to(synthesis_root).parts):
                continue
            relative_parts = project_dir.relative_to(synthesis_root).parts
            if not relative_parts:
                continue
            configuration = "-".join(relative_parts)
            yield {
                "architecture": architecture,
                "configuration": configuration,
                "root": project_dir,
                "project": f"{architecture}-{configuration}",
                "prefix": "conv-",
            }


def project_records(prefix):
    """Return current synthesis records matching a report family."""
    if prefix != "conv-":
        return []
    return list(synthesis_projects())


def project_label(record):
    if isinstance(record, dict):
        return record["project"]
    return str(record)


def report_has_multiplier(report_dir, label):
    path = Path(report_dir) / f"{label}-report-merged.csv"
    if not path.exists():
        return False
    frame = pd.read_csv(path)
    return "mult" in frame.columns and frame["mult"].notna().any()


def parse_side(project):
    match = re.search(r"m(\d+)p", str(project), flags=re.IGNORECASE)
    if not match:
        return None
    return int(match.group(1))


def parse_time(path):
    with open(path, "r") as handle:
        content = handle.read()
    match = re.search(r"Total execution time:\s*([0-9.]+)", content)
    if not match:
        # Xcelium gate-level logs report simulated workload time instead of
        # the old ModelSim ``Total execution time`` marker.
        match = re.search(
            r"Simulation complete via .*? at time\s*([0-9.]+)\s*(PS|NS|US)",
            content,
            flags=re.IGNORECASE,
        )
    if not match:
        return None
    value = float(match.group(1))
    if len(match.groups()) > 1:
        unit = match.group(2).upper()
        value *= {"PS": 1e-3, "NS": 1.0, "US": 1e3}[unit]
    return value


def parse_cycles(path):
    with open(path, "r") as handle:
        content = handle.read()
    match = re.search(r"Total cycles:\s*(\d+)", content)
    if not match:
        # The 3x3 testbench emits ``Ciclos de sistema`` and may not emit the
        # English marker used by the 2x2/4x4 testbenches.
        match = re.search(r"Ciclos[^:]*:\s*(\d+)", content, flags=re.IGNORECASE)
    if not match:
        match = re.search(r"\bcycles\s*=\s*(\d+)", content, flags=re.IGNORECASE)
    if not match:
        return None
    return int(match.group(1))


def parse_multipliers(project):
    match = re.search(
        r"(?:^|-)([0-9]+)(?:mac|m(?=\d+p|[-$]))",
        str(project),
        flags=re.IGNORECASE,
    )
    if not match:
        return None
    return match.group(1)


def parse_extra(project):
    match = re.search(r"m\d+p-([^-]+)", project, flags=re.IGNORECASE)
    if not match:
        return None
    return match.group(1)


def parse_side_from_content(content, project):
    match = re.search(r"sim-(\d+)(?:-|/)", content, flags=re.IGNORECASE)
    if match:
        return int(match.group(1))
    return parse_side(project)


def report_lines(path):
    return read_file(path)


def parse_area_report(path):
    """Parse the top-level area row without relying on fixed line numbers."""
    for line in report_lines(path):
        tokens = line.split()
        if len(tokens) < 5 or tokens[0].lower() not in {"conv", "system", "convolution"}:
            continue
        try:
            values = [float(value) for value in tokens[-4:]]
        except ValueError:
            continue
        return {
            "cell-count": int(values[0]),
            "cell-area-um": values[1],
            "net-area-um": values[2],
            "total-area-um": values[3],
        }
    return None


def parse_flop_count(path):
    for line in report_lines(path):
        match = re.search(r"Total Flip-flops\s+(\d+)", line, flags=re.IGNORECASE)
        if match:
            return int(match.group(1))
    return None


def parse_power_report(path):
    """Parse category totals from Genus power_evaluation.txt."""
    categories = {}
    subtotal = None
    expected = {"memory", "register", "latch", "logic", "bbox", "clock", "pad", "pm"}
    for line in report_lines(path):
        tokens = line.split()
        if not tokens:
            continue
        category = tokens[0].lower()
        if category in expected and len(tokens) >= 5:
            try:
                categories[category] = float(tokens[4])
            except ValueError:
                pass
        elif category == "subtotal" and len(tokens) >= 5:
            try:
                subtotal = float(tokens[4])
            except ValueError:
                pass
    if subtotal is None or len(categories) != len(expected):
        return None
    categories["Subtotal"] = subtotal
    return categories


def read_file(file_path):
    with open(file_path, "r") as handle:
        return handle.readlines()


def add_name_mult_columns(df, project_col):
    df = df.copy()
    def design_name(project):
        text = str(project)
        parts = text.split("-")
        config_index = next(
            (
                index
                for index, part in enumerate(parts)
                if re.fullmatch(r"(?:tcn|ifn)\d+", part, flags=re.IGNORECASE)
            ),
            None,
        )
        if config_index is not None and config_index > 0:
            return "-".join(parts[:config_index])
        return parts[0]

    df["nome"] = df[project_col].map(design_name)
    df["mult"] = df[project_col].map(parse_multipliers)
    df["extra"] = df[project_col].map(parse_extra)
    df.loc[
        df[project_col].astype(str).str.contains("naive", case=False, na=False),
        "nome",
    ] = "naive"
    return df


def write_report_time(report_dir, prefix):
    rows = []
    for record in project_records(prefix):
        sim_candidates = [
            record["root"] / "sim" / "xrun.log",
            record["root"] / "sim" / "sim.log",
            record["root"] / "sim.log",
        ]
        sim_path = next((path for path in sim_candidates if path.exists()), None)
        if sim_path is None:
            continue
        content = sim_path.read_text(encoding="utf-8", errors="replace")
        project = project_label(record)
        side = parse_side_from_content(content, project)
        time_ns = parse_time(sim_path)
        cycles = parse_cycles(sim_path)
        if side is None or time_ns is None:
            continue
        if cycles is None:
            print(f"Warning: no cycle marker found in {sim_path}")
        rows.append(
            {
                "project": project,
                "side": side,
                "time/ns": time_ns,
                "cycles": cycles,
            }
        )

    if prefix == "sys-":
        sim_path = SYS_NAIVE_DIR / "sim.txt"
        if sim_path.exists():
            time_ns = parse_time(sim_path)
            cycles = parse_cycles(sim_path)
            if time_ns is not None and cycles is not None:
                rows.append(
                    {
                        "project": SYS_NAIVE_PROJECT,
                        "side": SYS_NAIVE_SIDE,
                        "time/ns": time_ns,
                        "cycles": cycles,
                    }
                )

    if not rows:
        raise SystemExit(f"No valid simulation logs found for prefix {prefix!r}.")

    df = pd.DataFrame(rows)
    df["project"] = df["project"].map(format_project_name)
    df = add_name_mult_columns(df, "project")
    column_order = ["project", "nome", "mult", "side", "extra"]
    df = df[column_order + [c for c in df.columns if c not in column_order]]
    df.sort_values(by=["project"], inplace=True)
    df.reset_index(drop=True, inplace=True)
    label = prefix.rstrip("-")
    df.to_csv(report_dir / f"{label}-report-time.csv", index=False)


def write_report_logical(report_dir, prefix):
    report_area = {}
    report_clock = {}
    for record in project_records(prefix):
        reports_dir = record["root"] / "logical" / "results" / "reports"
        area_paths = sorted(reports_dir.glob("*_area.rpt"))
        clock_paths = sorted(reports_dir.glob("*_clock_gating.rpt"))
        if area_paths:
            area = parse_area_report(area_paths[0])
            if area is not None:
                report_area[project_label(record)] = area
        if clock_paths:
            flop_count = parse_flop_count(clock_paths[0])
            if flop_count is not None:
                report_clock[project_label(record)] = flop_count

    if prefix == "sys-":
        area_path = (
            SYS_NAIVE_DIR
            / "logical"
            / "results"
            / "reports"
            / "convolution_area.rpt"
        )
        if area_path.exists():
            area = parse_area_report(area_path)
            if area is not None:
                report_area[SYS_NAIVE_PROJECT] = area
        clock_path = (
            SYS_NAIVE_DIR
            / "logical"
            / "results"
            / "reports"
            / "convolution_clock_gating.rpt"
        )
        if clock_path.exists():
            report_clock[SYS_NAIVE_PROJECT] = parse_flop_count(clock_path)

    rows = []
    for project, area in report_area.items():
        if project not in report_clock:
            continue
        row = {
            "Project": format_project_name(project),
            "Cell Count": area["cell-count"],
            "Cell Area um^2": area["cell-area-um"],
            "Net Area um^2": area["net-area-um"],
            "Total Area um^2": area["total-area-um"],
            "Flop Count": report_clock[project],
        }
        rows.append(row)
    if not rows:
        raise SystemExit(f"No valid logical reports found for prefix {prefix!r}.")
    df = pd.DataFrame(rows)
    df = add_name_mult_columns(df, "Project")
    column_order = ["Project", "nome", "mult", "extra"]
    df = df[column_order + [c for c in df.columns if c not in column_order]]
    df.sort_values(by=["Project"], inplace=True)
    df.reset_index(drop=True, inplace=True)
    label = prefix.rstrip("-")
    df.to_csv(report_dir / f"{label}-report-logical.csv", index=False)


def write_report_power(report_dir, prefix):
    reports = []
    for record in project_records(prefix):
        power_path = record["root"] / "power" / "power_evaluation.txt"
        if power_path.exists():
            parsed = parse_power_report(power_path)
            if parsed is not None:
                reports.append((project_label(record), parsed))

    if prefix == "sys-":
        power_path = SYS_NAIVE_DIR / "power" / "power_evaluation.txt"
        if power_path.exists():
            parsed = parse_power_report(power_path)
            if parsed is not None:
                reports.append((SYS_NAIVE_PROJECT, parsed))

    if not reports:
        label = prefix.rstrip("-")
        columns = [
            "Project",
            "nome",
            "mult",
            "extra",
            "memory",
            "register",
            "latch",
            "logic",
            "bbox",
            "clock",
            "pad",
            "pm",
            "Subtotal",
        ]
        pd.DataFrame(columns=columns).to_csv(
            report_dir / f"{label}-report-power.csv", index=False
        )
        return

    rows = [{"Project": format_project_name(name), **values} for name, values in reports]
    df_total = pd.DataFrame(rows)
    df_total = add_name_mult_columns(df_total, "Project")
    column_order = ["Project", "nome", "mult", "extra"]
    df_total = df_total[
        column_order + [c for c in df_total.columns if c not in column_order]
    ]
    df_total.sort_values(by=["Project"], inplace=True)
    df_total.reset_index(drop=True, inplace=True)
    label = prefix.rstrip("-")
    df_total.to_csv(report_dir / f"{label}-report-power.csv", index=False)


def write_report_merge(report_dir, prefix):
    label = prefix.rstrip("-")
    df_time = pd.read_csv(report_dir / f"{label}-report-time.csv")
    df_logical = pd.read_csv(report_dir / f"{label}-report-logical.csv")
    df_power = pd.read_csv(report_dir / f"{label}-report-power.csv")

    df_time = df_time.rename(
        columns={"project": "Project", "time/ns": "time_ns", "cycles": "cycles"}
    )

    df = df_time.merge(df_logical, on="Project", how="left")
    df = df.merge(df_power, on="Project", how="left")

    df = add_name_mult_columns(df, "Project")
    df["size"] = pd.to_numeric(df["side"], errors="coerce") ** 2
    df["Subtotal"] = pd.to_numeric(df.get("Subtotal"), errors="coerce")
    df["time_ns"] = pd.to_numeric(df["time_ns"], errors="coerce")
    df["energy_nj"] = df["Subtotal"] * df["time_ns"] / 1000

    column_order = [
        "Project",
        "nome",
        "mult",
        "side",
        "extra",
        "time_ns",
        "cycles",
    ]
    remaining = [
        c for c in df.columns if c not in column_order and c != "energy_nj"
    ]
    df = df[column_order + remaining + ["energy_nj"]]
    df.sort_values(by=["Project"], inplace=True)
    df.reset_index(drop=True, inplace=True)

    df.to_csv(report_dir / f"{label}-report-merged.csv", index=False)


def write_chap7_conv_time(
    report_dir,
    prefix="conv",
    output_prefix=None,
    merge_extra_into_name=False,
    drop_names_with_k=False,
):
    if output_prefix is None:
        output_prefix = prefix
    source = report_dir / f"{prefix}-report-time.csv"
    if not source.exists():
        print(f"Skipping chap7 export, missing: {source}")
        return
    df = pd.read_csv(source)
    required_cols = {"nome", "mult", "cycles"}
    if not required_cols.issubset(df.columns):
        print(
            f"Skipping chap7 export, missing columns: {required_cols - set(df.columns)}"
        )
        return
    if merge_extra_into_name and "extra" not in df.columns:
        print("Skipping chap7 export, missing column: extra")
        return
    df = df[["nome", "mult", "extra", "cycles"]].dropna(
        subset=["nome", "cycles"]
    )
    df["extra"] = df["extra"].fillna("").astype(str).str.strip()
    if prefix == "conv":
        df["cycles"] = pd.to_numeric(df["cycles"], errors="coerce") * 9
    if merge_extra_into_name:
        df["nome"] = df["nome"] + df["extra"].map(
            lambda v: f"-{v}" if v else ""
        )
    if drop_names_with_k:
        df = df[~df["nome"].astype(str).str.contains("k", case=False, na=False)]
    df["mult"] = pd.to_numeric(df["mult"], errors="coerce")
    base_rows = df[df["mult"].isna()][["nome", "cycles"]].copy()
    df = df[df["mult"].notna()].copy()
    if not base_rows.empty and not df.empty:
        mult_values = sorted(df["mult"].dropna().unique())
        expanded = pd.DataFrame(
            [
                {"nome": row.nome, "mult": mult, "cycles": row.cycles}
                for row in base_rows.itertuples(index=False)
                for mult in mult_values
            ]
        )
        df = pd.concat([df, expanded], ignore_index=True)

    def merge_cycles(series):
        values = pd.to_numeric(series, errors="coerce").dropna().unique()
        if len(values) == 0:
            return None
        if len(values) == 1:
            return values[0]
        return None

    df = df.groupby(["mult", "nome"], as_index=False)["cycles"].agg(
        merge_cycles
    )
    df["mult"] = df["mult"].round().astype("Int64")
    df_pivot = df.pivot(index="mult", columns="nome", values="cycles")
    df_pivot = (
        df_pivot.apply(pd.to_numeric, errors="coerce").round().astype("Int64")
    )
    df_pivot.sort_index(axis=0, inplace=True)
    df_pivot = df_pivot.reset_index()
    output_dir = CHAPTER7_DIR
    if not output_dir.exists():
        print(f"Skipping chap7 export, missing: {output_dir}")
        return
    df_pivot.to_csv(
        output_dir / f"{output_prefix}-report-time.csv", index=False
    )


def write_chap7_conv_logical(
    report_dir,
    prefix="conv",
    output_prefix=None,
    merge_extra_into_name=False,
    drop_names_with_k=False,
):
    if output_prefix is None:
        output_prefix = prefix
    source = report_dir / f"{prefix}-report-logical.csv"
    if not source.exists():
        print(f"Skipping chap7 logical export, missing: {source}")
        return
    df = pd.read_csv(source)
    required_cols = {"nome", "mult", "extra", "Cell Area um^2", "Flop Count"}
    if not required_cols.issubset(df.columns):
        print(
            f"Skipping chap7 logical export, missing columns: {required_cols - set(df.columns)}"
        )
        return
    if not merge_extra_into_name:
        df = df[
            df["extra"].isna() | (df["extra"].astype(str).str.strip() == "")
        ]
    output_dir = CHAPTER7_DIR
    if not output_dir.exists():
        print(f"Skipping chap7 logical export, missing: {output_dir}")
        return
    df = df[["nome", "mult", "extra", "Cell Area um^2", "Flop Count"]].copy()
    df["extra"] = df["extra"].fillna("").astype(str).str.strip()
    if merge_extra_into_name:
        df["nome"] = df["nome"] + df["extra"].map(
            lambda v: f"-{v}" if v else ""
        )
    if drop_names_with_k:
        df = df[~df["nome"].astype(str).str.contains("k", case=False, na=False)]
    df["mult"] = pd.to_numeric(df["mult"], errors="coerce")
    base_rows = df[df["mult"].isna()][
        ["nome", "Cell Area um^2", "Flop Count"]
    ].copy()
    df = df[df["mult"].notna()].copy()
    if not base_rows.empty and not df.empty:
        mult_values = sorted(df["mult"].dropna().unique())
        expanded = pd.DataFrame(
            [
                {
                    "nome": row["nome"],
                    "mult": mult,
                    "Cell Area um^2": row["Cell Area um^2"],
                    "Flop Count": row["Flop Count"],
                }
                for row in base_rows.to_dict("records")
                for mult in mult_values
            ]
        )
        df = pd.concat([df, expanded], ignore_index=True)

    def merge_metric(series):
        values = pd.to_numeric(series, errors="coerce").dropna().unique()
        if len(values) == 0:
            return None
        if len(values) == 1:
            return values[0]
        return None

    df["mult"] = df["mult"].round().astype("Int64")

    df_cell = df[["nome", "mult", "Cell Area um^2"]].dropna(
        subset=["Cell Area um^2"]
    )
    df_cell = (
        df_cell.groupby(["mult", "nome"])["Cell Area um^2"]
        .agg(merge_metric)
        .reset_index()
    )
    df_cell_pivot = df_cell.pivot(
        index="mult", columns="nome", values="Cell Area um^2"
    )
    df_cell_pivot.sort_index(axis=0, inplace=True)
    df_cell_pivot = df_cell_pivot.reset_index()
    df_cell_pivot.to_csv(
        output_dir / f"{output_prefix}-cell-area.csv", index=False
    )

    df_flop = df[["nome", "mult", "Flop Count"]].dropna(subset=["Flop Count"])
    df_flop = (
        df_flop.groupby(["mult", "nome"])["Flop Count"]
        .agg(merge_metric)
        .reset_index()
    )
    df_flop_pivot = df_flop.pivot(
        index="mult", columns="nome", values="Flop Count"
    )
    df_flop_pivot = (
        df_flop_pivot.apply(pd.to_numeric, errors="coerce")
        .round()
        .astype("Int64")
    )
    df_flop_pivot.sort_index(axis=0, inplace=True)
    df_flop_pivot = df_flop_pivot.reset_index()
    df_flop_pivot.to_csv(
        output_dir / f"{output_prefix}-flop-count.csv", index=False
    )


def write_chap7_conv_power(
    report_dir,
    prefix="conv",
    output_prefix=None,
    merge_extra_into_name=False,
    drop_names_with_k=False,
):
    if output_prefix is None:
        output_prefix = prefix
    source = report_dir / f"{prefix}-report-power.csv"
    if not source.exists():
        print(f"Skipping chap7 power export, missing: {source}")
        return
    df = pd.read_csv(source)
    required_cols = {"nome", "mult", "extra", "Subtotal"}
    if not required_cols.issubset(df.columns):
        print(
            f"Skipping chap7 power export, missing columns: {required_cols - set(df.columns)}"
        )
        return
    if not merge_extra_into_name:
        df = df[
            df["extra"].isna() | (df["extra"].astype(str).str.strip() == "")
        ]
    df = df[["nome", "mult", "extra", "Subtotal"]].dropna(
        subset=["nome", "Subtotal"]
    )
    df["extra"] = df["extra"].fillna("").astype(str).str.strip()
    if merge_extra_into_name:
        df["nome"] = df["nome"] + df["extra"].map(
            lambda v: f"-{v}" if v else ""
        )
    if drop_names_with_k:
        df = df[~df["nome"].astype(str).str.contains("k", case=False, na=False)]
    df["mult"] = pd.to_numeric(df["mult"], errors="coerce")
    base_rows = df[df["mult"].isna()][["nome", "Subtotal"]].copy()
    df = df[df["mult"].notna()].copy()
    if not base_rows.empty and not df.empty:
        mult_values = sorted(df["mult"].dropna().unique())
        expanded = pd.DataFrame(
            [
                {"nome": row["nome"], "mult": mult, "Subtotal": row["Subtotal"]}
                for row in base_rows.to_dict("records")
                for mult in mult_values
            ]
        )
        df = pd.concat([df, expanded], ignore_index=True)

    def merge_metric(series):
        values = pd.to_numeric(series, errors="coerce").dropna().unique()
        if len(values) == 0:
            return None
        if len(values) == 1:
            return values[0]
        return None

    df["mult"] = df["mult"].round().astype("Int64")
    df_power = (
        df.groupby(["mult", "nome"])["Subtotal"].agg(merge_metric).reset_index()
    )
    df_pivot = df_power.pivot(index="mult", columns="nome", values="Subtotal")
    df_pivot.sort_index(axis=0, inplace=True)
    df_pivot = df_pivot.reset_index()
    output_dir = CHAPTER7_DIR
    if not output_dir.exists():
        print(f"Skipping chap7 power export, missing: {output_dir}")
        return
    df_pivot.to_csv(output_dir / f"{output_prefix}-power.csv", index=False)


def write_chap7_conv_energy(
    report_dir,
    prefix="conv",
    output_prefix=None,
    merge_extra_into_name=False,
    drop_names_with_k=False,
):
    if output_prefix is None:
        output_prefix = prefix
    source = report_dir / f"{prefix}-report-merged.csv"
    if not source.exists():
        print(f"Skipping chap7 energy export, missing: {source}")
        return
    df = pd.read_csv(source)
    required_cols = {"nome", "mult", "extra", "energy_nj"}
    if not required_cols.issubset(df.columns):
        print(
            f"Skipping chap7 energy export, missing columns: {required_cols - set(df.columns)}"
        )
        return
    if not merge_extra_into_name:
        df = df[
            df["extra"].isna() | (df["extra"].astype(str).str.strip() == "")
        ]
    df = df[["nome", "mult", "extra", "energy_nj"]].dropna(
        subset=["nome", "energy_nj"]
    )
    df["extra"] = df["extra"].fillna("").astype(str).str.strip()
    if merge_extra_into_name:
        df["nome"] = df["nome"] + df["extra"].map(
            lambda v: f"-{v}" if v else ""
        )
    if drop_names_with_k:
        df = df[~df["nome"].astype(str).str.contains("k", case=False, na=False)]
    df["mult"] = pd.to_numeric(df["mult"], errors="coerce")
    base_rows = df[df["mult"].isna()][["nome", "energy_nj"]].copy()
    df = df[df["mult"].notna()].copy()
    if not base_rows.empty and not df.empty:
        mult_values = sorted(df["mult"].dropna().unique())
        expanded = pd.DataFrame(
            [
                {
                    "nome": row["nome"],
                    "mult": mult,
                    "energy_nj": row["energy_nj"],
                }
                for row in base_rows.to_dict("records")
                for mult in mult_values
            ]
        )
        df = pd.concat([df, expanded], ignore_index=True)

    def merge_metric(series):
        values = pd.to_numeric(series, errors="coerce").dropna().unique()
        if len(values) == 0:
            return None
        if len(values) == 1:
            return values[0]
        return None

    df["mult"] = df["mult"].round().astype("Int64")
    df_energy = (
        df.groupby(["mult", "nome"])["energy_nj"]
        .agg(merge_metric)
        .reset_index()
    )
    df_pivot = df_energy.pivot(index="mult", columns="nome", values="energy_nj")
    df_pivot.sort_index(axis=0, inplace=True)
    df_pivot = df_pivot.reset_index()
    output_dir = CHAPTER7_DIR
    if not output_dir.exists():
        print(f"Skipping chap7 energy export, missing: {output_dir}")
        return
    df_pivot.to_csv(output_dir / f"{output_prefix}-energy.csv", index=False)


def _add_distance_norm(df, metric_cols, name_col="nome"):
    df = df.copy()
    for col in metric_cols:
        df[col] = pd.to_numeric(df[col], errors="coerce")
    df["distance"] = 0
    for col in metric_cols:
        df["distance"] += df[col] ** 2
    df["distance"] = df["distance"] ** 0.5
    naive_rows = df[df[name_col].astype(str).str.lower() == "naive"]
    if not naive_rows.empty:
        naive_distance = pd.to_numeric(
            naive_rows.iloc[0]["distance"], errors="coerce"
        )
        df["distance_norm"] = (
            df["distance"] / naive_distance if naive_distance else None
        )
    else:
        df["distance_norm"] = None
    df.sort_values(by=["distance_norm"], inplace=True)
    df.drop(columns=["distance"], inplace=True)
    return df


def write_chap7_conv_power_cycles(
    report_dir,
    prefix="conv",
    output_prefix=None,
    merge_extra_into_name=False,
    drop_names_with_k=False,
    expand_base_rows=True,
):
    if output_prefix is None:
        output_prefix = prefix
    source = report_dir / f"{prefix}-report-merged.csv"
    if not source.exists():
        print(f"Skipping chap7 power/cycles export, missing: {source}")
        return
    df = pd.read_csv(source)
    required_cols = {
        "nome",
        "mult",
        "extra",
        "Subtotal",
        "energy_nj",
        "cycles",
        "Cell Area um^2",
    }
    if not required_cols.issubset(df.columns):
        print(
            f"Skipping chap7 power/cycles export, missing columns: {required_cols - set(df.columns)}"
        )
        return
    if not merge_extra_into_name:
        df = df[
            df["extra"].isna() | (df["extra"].astype(str).str.strip() == "")
        ]
    df = df[
        [
            "nome",
            "mult",
            "extra",
            "Subtotal",
            "energy_nj",
            "cycles",
            "Cell Area um^2",
        ]
    ].dropna(subset=["nome"])
    df["extra"] = df["extra"].fillna("").astype(str).str.strip()
    if merge_extra_into_name:
        df["nome"] = df["nome"] + df["extra"].map(
            lambda v: f"-{v}" if v else ""
        )
    if drop_names_with_k:
        df = df[~df["nome"].astype(str).str.contains("k", case=False, na=False)]
    df["mult"] = pd.to_numeric(df["mult"], errors="coerce")
    base_rows = df[df["mult"].isna()][
        ["nome", "Subtotal", "energy_nj", "cycles", "Cell Area um^2"]
    ].copy()
    df = df[df["mult"].notna()].copy()
    if expand_base_rows and not base_rows.empty and not df.empty:
        mult_values = sorted(df["mult"].dropna().unique())
        expanded = pd.DataFrame(
            [
                {
                    "nome": row["nome"],
                    "mult": mult,
                    "Subtotal": row["Subtotal"],
                    "energy_nj": row["energy_nj"],
                    "cycles": row["cycles"],
                    "Cell Area um^2": row["Cell Area um^2"],
                }
                for row in base_rows.to_dict("records")
                for mult in mult_values
            ]
        )
        df = pd.concat([df, expanded], ignore_index=True)
    elif not expand_base_rows and not base_rows.empty:
        df = pd.concat([df, base_rows], ignore_index=True)

    def merge_metric(series):
        values = pd.to_numeric(series, errors="coerce").dropna().unique()
        if len(values) == 0:
            return None
        if len(values) == 1:
            return values[0]
        return None

    df["mult"] = df["mult"].round().astype("Int64")
    df = df.groupby(["mult", "nome"], dropna=False).agg(
        energy=("energy_nj", merge_metric),
        cycles=("cycles", merge_metric),
        power=("Subtotal", merge_metric),
        cell_area=("Cell Area um^2", merge_metric),
    )
    df = df.reset_index()
    output_dir = CHAPTER7_DIR
    if not output_dir.exists():
        print(f"Skipping chap7 power/cycles export, missing: {output_dir}")
        return
    df = df[["nome", "mult", "energy", "cycles"]]
    df = _add_distance_norm(df, ["cycles", "energy"], "nome")
    df = df[["nome", "mult", "energy", "cycles", "distance_norm"]]
    df.to_csv(output_dir / f"{output_prefix}-energy-cycles.csv", index=False)


def write_chap7_conv_metric_cycles(
    report_dir,
    metric_col,
    output_suffix,
    metric_name,
    prefix="conv",
    output_prefix=None,
    merge_extra_into_name=False,
    drop_names_with_k=False,
    expand_base_rows=True,
):
    if output_prefix is None:
        output_prefix = prefix
    source = report_dir / f"{prefix}-report-merged.csv"
    if not source.exists():
        print(f"Skipping chap7 {metric_name}/cycles export, missing: {source}")
        return
    df = pd.read_csv(source)
    required_cols = {
        "nome",
        "mult",
        "extra",
        metric_col,
        "cycles",
        "Subtotal",
        "energy_nj",
        "Cell Area um^2",
    }
    if not required_cols.issubset(df.columns):
        print(
            f"Skipping chap7 {metric_name}/cycles export, missing columns: {required_cols - set(df.columns)}"
        )
        return
    if not merge_extra_into_name:
        df = df[
            df["extra"].isna() | (df["extra"].astype(str).str.strip() == "")
        ]
    df_cols = [
        "nome",
        "mult",
        "extra",
        metric_col,
        "cycles",
        "Subtotal",
        "energy_nj",
        "Cell Area um^2",
    ]
    df_cols = list(dict.fromkeys(df_cols))
    df = df[df_cols].dropna(subset=["nome"])
    df["extra"] = df["extra"].fillna("").astype(str).str.strip()
    if merge_extra_into_name:
        df["nome"] = df["nome"] + df["extra"].map(
            lambda v: f"-{v}" if v else ""
        )
    if drop_names_with_k:
        df = df[~df["nome"].astype(str).str.contains("k", case=False, na=False)]
    df["mult"] = pd.to_numeric(df["mult"], errors="coerce")
    base_cols = [
        "nome",
        metric_col,
        "cycles",
        "Subtotal",
        "energy_nj",
        "Cell Area um^2",
    ]
    base_cols = list(dict.fromkeys(base_cols))
    base_rows = df[df["mult"].isna()][base_cols].copy()
    df = df[df["mult"].notna()].copy()
    if expand_base_rows and not base_rows.empty and not df.empty:
        mult_values = sorted(df["mult"].dropna().unique())
        expanded = pd.DataFrame(
            [
                {
                    "nome": row["nome"],
                    "mult": mult,
                    metric_col: row[metric_col],
                    "cycles": row["cycles"],
                    "Subtotal": row["Subtotal"],
                    "energy_nj": row["energy_nj"],
                    "Cell Area um^2": row["Cell Area um^2"],
                }
                for row in base_rows.to_dict("records")
                for mult in mult_values
            ]
        )
        df = pd.concat([df, expanded], ignore_index=True)
    elif not expand_base_rows and not base_rows.empty:
        df = pd.concat([df, base_rows], ignore_index=True)

    def merge_metric(series):
        values = pd.to_numeric(series, errors="coerce").dropna().unique()
        if len(values) == 0:
            return None
        if len(values) == 1:
            return values[0]
        return None

    df["mult"] = df["mult"].round().astype("Int64")
    df = df.groupby(["mult", "nome"], dropna=False).agg(
        metric=(metric_col, merge_metric),
        cycles=("cycles", merge_metric),
        power=("Subtotal", merge_metric),
        energy=("energy_nj", merge_metric),
        cell_area=("Cell Area um^2", merge_metric),
    )
    df = df.reset_index()
    output_dir = CHAPTER7_DIR
    if not output_dir.exists():
        print(
            f"Skipping chap7 {metric_name}/cycles export, missing: {output_dir}"
        )
        return
    df = df[["nome", "mult", "metric", "cycles"]].rename(
        columns={"metric": metric_name}
    )
    df = _add_distance_norm(df, ["cycles", metric_name], "nome")
    df = df[["nome", "mult", metric_name, "cycles", "distance_norm"]]
    df.to_csv(output_dir / f"{output_prefix}-{output_suffix}.csv", index=False)


def write_chap7_conv_distance_4d(
    report_dir,
    prefix="conv",
    output_prefix=None,
    merge_extra_into_name=False,
    drop_names_with_k=False,
    expand_base_rows=True,
):
    if output_prefix is None:
        output_prefix = prefix
    source = report_dir / f"{prefix}-report-merged.csv"
    if not source.exists():
        print(f"Skipping chap7 4d distance export, missing: {source}")
        return
    df = pd.read_csv(source)
    required_cols = {
        "nome",
        "mult",
        "extra",
        "cycles",
        "Subtotal",
        "energy_nj",
        "Cell Area um^2",
    }
    if not required_cols.issubset(df.columns):
        print(
            f"Skipping chap7 4d distance export, missing columns: {required_cols - set(df.columns)}"
        )
        return
    if not merge_extra_into_name:
        df = df[df["extra"].isna() | (df["extra"].astype(str).str.strip() == "")]
    df = df[
        ["nome", "mult", "extra", "cycles", "Subtotal", "energy_nj", "Cell Area um^2"]
    ].dropna(subset=["nome"])
    df["extra"] = df["extra"].fillna("").astype(str).str.strip()
    if merge_extra_into_name:
        df["nome"] = df["nome"] + df["extra"].map(lambda v: f"-{v}" if v else "")
    if drop_names_with_k:
        df = df[~df["nome"].astype(str).str.contains("k", case=False, na=False)]
    df["mult"] = pd.to_numeric(df["mult"], errors="coerce")
    base_rows = df[df["mult"].isna()][
        ["nome", "cycles", "Subtotal", "energy_nj", "Cell Area um^2"]
    ].copy()
    df = df[df["mult"].notna()].copy()
    if expand_base_rows and not base_rows.empty and not df.empty:
        mult_values = sorted(df["mult"].dropna().unique())
        expanded = pd.DataFrame(
            [
                {
                    "nome": row["nome"],
                    "mult": mult,
                    "cycles": row["cycles"],
                    "Subtotal": row["Subtotal"],
                    "energy_nj": row["energy_nj"],
                    "Cell Area um^2": row["Cell Area um^2"],
                }
                for row in base_rows.to_dict("records")
                for mult in mult_values
            ]
        )
        df = pd.concat([df, expanded], ignore_index=True)
    elif not expand_base_rows and not base_rows.empty:
        df = pd.concat([df, base_rows], ignore_index=True)

    def merge_metric(series):
        values = pd.to_numeric(series, errors="coerce").dropna().unique()
        if len(values) == 0:
            return None
        if len(values) == 1:
            return values[0]
        return None

    df["mult"] = df["mult"].round().astype("Int64")
    df = df.groupby(["mult", "nome"], dropna=False).agg(
        cycles=("cycles", merge_metric),
        power=("Subtotal", merge_metric),
        energy=("energy_nj", merge_metric),
        cell_area=("Cell Area um^2", merge_metric),
    )
    df = df.reset_index()
    output_dir = CHAPTER7_DIR
    if not output_dir.exists():
        print(f"Skipping chap7 4d distance export, missing: {output_dir}")
        return
    df = df[["nome", "mult", "cycles", "cell_area", "power", "energy"]]
    df = _add_distance_norm(df, ["cycles", "cell_area", "power", "energy"], "nome")
    df = df[["nome", "mult", "cycles", "cell_area", "power", "energy", "distance_norm"]]
    df.to_csv(output_dir / f"{output_prefix}-4d-distance.csv", index=False)


def write_chap7_conv_distance_3d(
    report_dir,
    prefix="conv",
    output_prefix=None,
    merge_extra_into_name=False,
    drop_names_with_k=False,
    expand_base_rows=True,
):
    if output_prefix is None:
        output_prefix = prefix
    source = report_dir / f"{prefix}-report-merged.csv"
    if not source.exists():
        print(f"Skipping chap7 3d distance export, missing: {source}")
        return
    df = pd.read_csv(source)
    required_cols = {
        "nome",
        "mult",
        "extra",
        "cycles",
        "Subtotal",
        "Cell Area um^2",
    }
    if not required_cols.issubset(df.columns):
        print(
            f"Skipping chap7 3d distance export, missing columns: {required_cols - set(df.columns)}"
        )
        return
    if not merge_extra_into_name:
        df = df[df["extra"].isna() | (df["extra"].astype(str).str.strip() == "")]
    df = df[
        ["nome", "mult", "extra", "cycles", "Subtotal", "Cell Area um^2"]
    ].dropna(subset=["nome"])
    df["extra"] = df["extra"].fillna("").astype(str).str.strip()
    if merge_extra_into_name:
        df["nome"] = df["nome"] + df["extra"].map(lambda v: f"-{v}" if v else "")
    if drop_names_with_k:
        df = df[~df["nome"].astype(str).str.contains("k", case=False, na=False)]
    df["mult"] = pd.to_numeric(df["mult"], errors="coerce")
    base_rows = df[df["mult"].isna()][
        ["nome", "cycles", "Subtotal", "Cell Area um^2"]
    ].copy()
    df = df[df["mult"].notna()].copy()
    if expand_base_rows and not base_rows.empty and not df.empty:
        mult_values = sorted(df["mult"].dropna().unique())
        expanded = pd.DataFrame(
            [
                {
                    "nome": row["nome"],
                    "mult": mult,
                    "cycles": row["cycles"],
                    "Subtotal": row["Subtotal"],
                    "Cell Area um^2": row["Cell Area um^2"],
                }
                for row in base_rows.to_dict("records")
                for mult in mult_values
            ]
        )
        df = pd.concat([df, expanded], ignore_index=True)
    elif not expand_base_rows and not base_rows.empty:
        df = pd.concat([df, base_rows], ignore_index=True)

    def merge_metric(series):
        values = pd.to_numeric(series, errors="coerce").dropna().unique()
        if len(values) == 0:
            return None
        if len(values) == 1:
            return values[0]
        return None

    df["mult"] = df["mult"].round().astype("Int64")
    df = df.groupby(["mult", "nome"], dropna=False).agg(
        cycles=("cycles", merge_metric),
        power=("Subtotal", merge_metric),
        cell_area=("Cell Area um^2", merge_metric),
    )
    df = df.reset_index()
    output_dir = CHAPTER7_DIR
    if not output_dir.exists():
        print(f"Skipping chap7 3d distance export, missing: {output_dir}")
        return
    df = df[["nome", "mult", "cycles", "cell_area", "power"]]
    df = _add_distance_norm(df, ["cycles", "cell_area", "power"], "nome")
    df = df[["nome", "mult", "cycles", "cell_area", "power", "distance_norm"]]
    df.to_csv(output_dir / f"{output_prefix}-3d-distance.csv", index=False)


def write_chap7_conv_power_reg_logic(
    report_dir,
    prefix="conv",
    output_prefix=None,
    merge_extra_into_name=False,
    drop_names_with_k=False,
    expand_base_rows=True,
):
    if output_prefix is None:
        output_prefix = prefix
    source = report_dir / f"{prefix}-report-power.csv"
    if not source.exists():
        print(f"Skipping chap7 power reg/logic export, missing: {source}")
        return
    df = pd.read_csv(source)
    required_cols = {"nome", "mult", "extra", "register", "logic"}
    if not required_cols.issubset(df.columns):
        print(
            f"Skipping chap7 power reg/logic export, missing columns: {required_cols - set(df.columns)}"
        )
        return
    if not merge_extra_into_name:
        df = df[
            df["extra"].isna() | (df["extra"].astype(str).str.strip() == "")
        ]
    df = df[["nome", "mult", "extra", "register", "logic"]].dropna(
        subset=["nome"]
    )
    df["extra"] = df["extra"].fillna("").astype(str).str.strip()
    if merge_extra_into_name:
        df["nome"] = df["nome"] + df["extra"].map(
            lambda v: f"-{v}" if v else ""
        )
    if drop_names_with_k:
        df = df[~df["nome"].astype(str).str.contains("k", case=False, na=False)]
    df["mult"] = pd.to_numeric(df["mult"], errors="coerce")
    base_rows = df[df["mult"].isna()][["nome", "register", "logic"]].copy()
    df = df[df["mult"].notna()].copy()
    if expand_base_rows and not base_rows.empty and not df.empty:
        mult_values = sorted(df["mult"].dropna().unique())
        expanded = pd.DataFrame(
            [
                {
                    "nome": row["nome"],
                    "mult": mult,
                    "register": row["register"],
                    "logic": row["logic"],
                }
                for row in base_rows.to_dict("records")
                for mult in mult_values
            ]
        )
        df = pd.concat([df, expanded], ignore_index=True)
    elif not expand_base_rows and not base_rows.empty:
        df = pd.concat([df, base_rows], ignore_index=True)

    def merge_metric(series):
        values = pd.to_numeric(series, errors="coerce").dropna().unique()
        if len(values) == 0:
            return None
        if len(values) == 1:
            return values[0]
        return None

    df["mult"] = df["mult"].round().astype("Int64")
    df = df.groupby(["mult", "nome"], dropna=False).agg(
        register=("register", merge_metric),
        logic=("logic", merge_metric),
    )
    df = df.reset_index()
    output_dir = CHAPTER7_DIR
    if not output_dir.exists():
        print(f"Skipping chap7 power reg/logic export, missing: {output_dir}")
        return
    df = df[["nome", "mult", "register", "logic"]]
    df.to_csv(output_dir / f"{output_prefix}-power-reg-logic.csv", index=False)


def write_chap7_conv_tc9(report_dir, prefix="conv"):
    logical_source = report_dir / f"{prefix}-report-logical.csv"
    power_source = report_dir / f"{prefix}-report-power.csv"
    if not logical_source.exists():
        print(f"Skipping chap7 tc9 export, missing: {logical_source}")
        return
    if not power_source.exists():
        print(f"Skipping chap7 tc9 export, missing: {power_source}")
        return
    logical = pd.read_csv(logical_source)
    power = pd.read_csv(power_source)
    logical_required = {"nome", "mult", "extra", "Cell Area um^2", "Flop Count"}
    power_required = {"nome", "mult", "extra", "Subtotal", "register", "logic"}
    if not logical_required.issubset(logical.columns):
        print(
            f"Skipping chap7 tc9 export, missing columns: {logical_required - set(logical.columns)}"
        )
        return
    if not power_required.issubset(power.columns):
        print(
            f"Skipping chap7 tc9 export, missing columns: {power_required - set(power.columns)}"
        )
        return

    logical = logical[
        ["nome", "mult", "extra", "Cell Area um^2", "Flop Count"]
    ].dropna(subset=["nome"])
    power = power[
        ["nome", "mult", "extra", "Subtotal", "register", "logic"]
    ].dropna(subset=["nome"])

    logical = logical[
        logical["nome"].str.contains(r"(?i)^tc.*9$", regex=True, na=False)
    ]
    power = power[
        power["nome"].str.contains(r"(?i)^tc.*9$", regex=True, na=False)
    ]

    logical["extra"] = logical["extra"].fillna("").astype(str).str.strip()
    power["extra"] = power["extra"].fillna("").astype(str).str.strip()

    logical["mult"] = pd.to_numeric(logical["mult"], errors="coerce")
    power["mult"] = pd.to_numeric(power["mult"], errors="coerce")

    def expand_base_rows(df, metric_cols):
        base_rows = df[df["mult"].isna()][["nome"] + metric_cols].copy()
        df = df[df["mult"].notna()].copy()
        if not base_rows.empty and not df.empty:
            mult_values = sorted(df["mult"].dropna().unique())
            expanded = pd.DataFrame(
                [
                    dict(
                        {"nome": row["nome"], "mult": mult},
                        **{k: row[k] for k in metric_cols},
                    )
                    for row in base_rows.to_dict("records")
                    for mult in mult_values
                ]
            )
            df = pd.concat([df, expanded], ignore_index=True)
        return df

    logical = expand_base_rows(
        logical, ["extra", "Cell Area um^2", "Flop Count"]
    )
    power = expand_base_rows(power, ["extra", "Subtotal", "register", "logic"])

    def merge_metric(series):
        values = pd.to_numeric(series, errors="coerce").dropna().unique()
        if len(values) == 0:
            return None
        if len(values) == 1:
            return values[0]
        return None

    logical["mult"] = logical["mult"].round().astype("Int64")
    power["mult"] = power["mult"].round().astype("Int64")

    logical = logical.groupby(["mult", "nome", "extra"], dropna=False).agg(
        cell_area=("Cell Area um^2", merge_metric),
        flop_count=("Flop Count", merge_metric),
    )
    power = power.groupby(["mult", "nome", "extra"], dropna=False).agg(
        power_subtotal=("Subtotal", merge_metric),
        power_register=("register", merge_metric),
        power_logic=("logic", merge_metric),
    )

    df = logical.join(power, how="outer").reset_index()
    output_dir = CHAPTER7_DIR
    if not output_dir.exists():
        print(f"Skipping chap7 tc9 export, missing: {output_dir}")
        return
    df["nome_extra"] = df["nome"] + df["extra"].replace("", pd.NA).map(
        lambda v: f"-{v}" if pd.notna(v) and str(v).strip() else ""
    )
    df = df[
        [
            "nome",
            "extra",
            "nome_extra",
            "mult",
            "cell_area",
            "flop_count",
            "power_subtotal",
            "power_register",
            "power_logic",
        ]
    ]
    df.to_csv(output_dir / f"{prefix}-tc9.csv", index=False)


def write_ratio_tables(report_dir):
    report_dir = Path(report_dir).resolve()
    if not CHAPTER7_DIR.exists():
        print(f"Skipping ratio export, missing: {CHAPTER7_DIR}")
        return
    for label in ("conv", "sys"):
        source = report_dir / f"{label}-report-merged.csv"
        if not source.exists():
            print(f"Skipping {label} ratio export, missing: {source}")
            continue
        df = pd.read_csv(source)
        required = {"cycles", "Cell Area um^2", "Subtotal", "energy_nj"}
        missing = required - set(df.columns)
        if missing:
            print(f"Skipping {label} ratio export, missing {missing}")
            continue
        naive_rows = df[df["nome"].astype(str).str.lower() == "naive"]
        if naive_rows.empty:
            print(f"Skipping {label} ratio export, naive row missing")
            continue
        naive = naive_rows.iloc[0]
        naive_cycles = float(naive["cycles"])
        naive_area = float(naive["Cell Area um^2"])
        naive_power = float(naive["Subtotal"])
        naive_energy = float(naive["energy_nj"])
        out = df.copy()
        out["cycles"] = pd.to_numeric(out["cycles"], errors="coerce")
        out["Cell Area um^2"] = pd.to_numeric(out["Cell Area um^2"], errors="coerce")
        out["Subtotal"] = pd.to_numeric(out["Subtotal"], errors="coerce")
        out["energy_nj"] = pd.to_numeric(out["energy_nj"], errors="coerce")
        out["slowdown_cycles"] = round(
            100 * (1 - (out["cycles"] / naive_cycles)), 2
        )
        out["ratio_cell_area"] = round(
            100 * (1 - (out["Cell Area um^2"] / naive_area)), 2
        )
        out["ratio_power"] = round(
            100 * (1 - (out["Subtotal"] / naive_power)), 2
        )
        out["ratio_energy"] = round(
            100 * (1 - (out["energy_nj"] / naive_energy)), 2
        )
        cols = [
            "Project",
            "nome",
            "extra",
            "mult",
            "cycles",
            "Cell Area um^2",
            "Subtotal",
            "energy_nj",
            "slowdown_cycles",
            "ratio_cell_area",
            "ratio_power",
            "ratio_energy",
        ]
        out = out[cols].copy()
        out.sort_values(by=["nome", "mult", "extra"], inplace=True)
        out.to_csv(CHAPTER7_DIR / f"{label}-ratio-naive.csv", index=False)


def write_naive_energy_tables(report_dir, baselines):
    report_dir = Path(report_dir).resolve()
    if not CHAPTER7_DIR.exists():
        print(f"Skipping naive energy export, missing: {CHAPTER7_DIR}")
        return
    df = pd.read_csv(report_dir / "sys-report-merged.csv")
    for baseline in baselines:
        candidate = df[
            (df.get("Project", "").astype(str).str.lower() == baseline.lower())
            | (df["nome"].astype(str).str.lower() == baseline.lower())
        ]
        if candidate.empty:
            print(f"Skipping baseline {baseline}, not found")
            continue
        row = candidate.iloc[0]
        base_cycles = float(row["cycles"])
        base_energy = float(row["energy_nj"])
        metrics = []
        for _, entry in df.iterrows():
            cycles = pd.to_numeric(entry["cycles"], errors="coerce")
            energy = pd.to_numeric(entry["energy_nj"], errors="coerce")
            if pd.isna(cycles) or pd.isna(energy) or energy == 0:
                continue
            equivalent = (base_cycles / cycles) * base_energy
            delta = (equivalent - energy) / energy * 100
            metrics.append(
                {
                    "Project": entry.get("Project", ""),
                    "nome": entry["nome"],
                    "mult": entry.get("mult"),
                    "side": entry.get("side"),
                    "cycles": cycles,
                    "energy": energy,
                    "energy_baseline_eq": equivalent,
                    "energy_increase_pct": delta,
                }
            )
        if not metrics:
            continue
        out_df = pd.DataFrame(metrics)
        csv_path = CHAPTER7_DIR / f"sys-{baseline.lower()}-equivalent-energy.csv"
        txt_path = CHAPTER7_DIR / f"sys-{baseline.lower()}-equivalent-energy.txt"
        out_df.to_csv(csv_path, index=False)
        with txt_path.open("w", encoding="utf-8") as handle:
            handle.write(
                f"baseline={baseline} cycles={base_cycles:.0f} energy={base_energy:.6f} nJ\n\n"
            )
            for row in metrics:
                handle.write(
                    f"{row['Project']}: cycles={row['cycles']:.0f} "
                    f"energy={row['energy']:.6f} nJ | "
                    f"energy_baseline_eq={row['energy_baseline_eq']:.6f} nJ "
                    f"delta={row['energy_increase_pct']:.2f}%\n"
                )
        print(f"Wrote {csv_path}")
        print(f"Wrote {txt_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Collect current RTL-local synthesis reports into CSV tables."
    )
    parser.add_argument(
        "--report-dir",
        default=str(REPO_ROOT / "report"),
        help="Directory for generated report tables (default: report/).",
    )
    parser.add_argument(
        "--chapter7-dir",
        default=None,
        help="Optional directory for chapter-7 derived tables.",
    )
    args = parser.parse_args()
    report_dir = Path(args.report_dir).resolve()
    report_dir.mkdir(parents=True, exist_ok=True)
    global CHAPTER7_DIR
    if args.chapter7_dir:
        CHAPTER7_DIR = Path(args.chapter7_dir).resolve()
    CHAPTER7_DIR.mkdir(parents=True, exist_ok=True)

    prefixes = []
    if project_records("conv-"):
        prefixes.append("conv-")
    if SYS_NAIVE_DIR.exists() or project_records("sys-"):
        prefixes.append("sys-")

    for prefix in prefixes:
        write_report_time(report_dir, prefix)
        write_report_logical(report_dir, prefix)
        write_report_power(report_dir, prefix)
        write_report_merge(report_dir, prefix)
    if "conv-" in prefixes:
        write_chap7_conv_time(report_dir, prefix="conv", drop_names_with_k=True)
        write_chap7_conv_logical(report_dir, prefix="conv", drop_names_with_k=True)
        write_chap7_conv_power(report_dir, prefix="conv", drop_names_with_k=True)
        write_chap7_conv_energy(report_dir, prefix="conv", drop_names_with_k=True)
        write_chap7_conv_power_cycles(
            report_dir,
            prefix="conv",
            drop_names_with_k=True,
            expand_base_rows=False,
        )
        write_chap7_conv_distance_4d(
            report_dir,
            prefix="conv",
            drop_names_with_k=True,
            expand_base_rows=False,
        )
        write_chap7_conv_distance_3d(
            report_dir,
            prefix="conv",
            drop_names_with_k=True,
            expand_base_rows=False,
        )
        write_chap7_conv_metric_cycles(
            report_dir,
            metric_col="Cell Area um^2",
            output_suffix="cell-area-cycles",
            metric_name="cell_area",
            prefix="conv",
            drop_names_with_k=True,
            expand_base_rows=False,
        )
        write_chap7_conv_metric_cycles(
            report_dir,
            metric_col="Subtotal",
            output_suffix="power-cycles",
            metric_name="power",
            prefix="conv",
            drop_names_with_k=True,
            expand_base_rows=False,
        )
        write_chap7_conv_metric_cycles(
            report_dir,
            metric_col="energy_nj",
            output_suffix="energy-cycles",
            metric_name="energy",
            prefix="conv",
            drop_names_with_k=True,
            expand_base_rows=False,
        )
        write_chap7_conv_power_reg_logic(
            report_dir,
            prefix="conv",
            drop_names_with_k=True,
            expand_base_rows=False,
        )
        write_chap7_conv_tc9(report_dir, prefix="conv")

    if "sys-" in prefixes and report_has_multiplier(report_dir, "sys"):
        write_chap7_conv_time(report_dir, prefix="sys", merge_extra_into_name=True)
        write_chap7_conv_logical(
            report_dir, prefix="sys", merge_extra_into_name=True
        )
        write_chap7_conv_power(report_dir, prefix="sys", merge_extra_into_name=True)
        write_chap7_conv_energy(
            report_dir, prefix="sys", merge_extra_into_name=True
        )
        write_chap7_conv_power_cycles(
            report_dir,
            prefix="sys",
            merge_extra_into_name=True,
            drop_names_with_k=False,
            expand_base_rows=False,
        )
        write_chap7_conv_distance_4d(
            report_dir,
            prefix="sys",
            merge_extra_into_name=True,
            drop_names_with_k=False,
            expand_base_rows=False,
        )
        write_chap7_conv_distance_3d(
            report_dir,
            prefix="sys",
            merge_extra_into_name=True,
            drop_names_with_k=False,
            expand_base_rows=False,
        )
        write_chap7_conv_metric_cycles(
            report_dir,
            metric_col="Cell Area um^2",
            output_suffix="cell-area-cycles",
            metric_name="cell_area",
            prefix="sys",
            merge_extra_into_name=True,
            drop_names_with_k=False,
            expand_base_rows=False,
        )
        write_chap7_conv_metric_cycles(
            report_dir,
            metric_col="Subtotal",
            output_suffix="power-cycles",
            metric_name="power",
            prefix="sys",
            merge_extra_into_name=True,
            drop_names_with_k=False,
            expand_base_rows=False,
        )
        write_chap7_conv_metric_cycles(
            report_dir,
            metric_col="energy_nj",
            output_suffix="energy-cycles",
            metric_name="energy",
            prefix="sys",
            merge_extra_into_name=True,
            drop_names_with_k=True,
            expand_base_rows=False,
        )
        write_chap7_conv_power_reg_logic(
            report_dir,
            prefix="sys",
            merge_extra_into_name=True,
            drop_names_with_k=False,
            expand_base_rows=False,
        )

    write_ratio_tables(report_dir)
    if "sys-" in prefixes:
        write_naive_energy_tables(report_dir, ["naive", "TCn9-05m032p-bus"])


if __name__ == "__main__":
    main()
