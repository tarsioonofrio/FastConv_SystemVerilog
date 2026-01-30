import glob
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


def strip_project_prefix(name):
    return re.sub(r"^(sys|conv)-?", "", name, flags=re.IGNORECASE)


def format_project_name(name):
    name = strip_project_prefix(name)
    if len(name) < 2:
        return name.upper()
    return f"{name[:2].upper()}{name[2:]}"


def project_name_from_report(path):
    return Path(path).parent.parent.parent.parent.name


def parse_side(project):
    match = re.search(r"m(\d+)p", project)
    if not match:
        return None
    return int(match.group(1))


def parse_time(path):
    with open(path, "r") as handle:
        content = handle.read()
    match = re.search(r"Total execution time:\s*([0-9.]+)", content)
    if not match:
        return None
    return float(match.group(1))


def parse_cycles(path):
    with open(path, "r") as handle:
        content = handle.read()
    match = re.search(r"Total cycles:\s*(\d+)", content)
    if not match:
        return None
    return int(match.group(1))


def parse_multipliers(project):
    match = re.search(r"-([0-9]+)m", project)
    if not match:
        return None
    return match.group(1)


def parse_extra(project):
    match = re.search(r"m\d+p-([^-]+)", project, flags=re.IGNORECASE)
    if not match:
        return None
    return match.group(1)


def read_file(file_path):
    with open(file_path, "r") as handle:
        return handle.readlines()


def add_name_mult_columns(df, project_col):
    df = df.copy()
    df["nome"] = df[project_col].astype(str).str.split("-").str[0]
    df["mult"] = df[project_col].map(parse_multipliers)
    df["extra"] = df[project_col].map(parse_extra)
    df.loc[
        df[project_col].astype(str).str.contains("naive", case=False, na=False),
        "nome",
    ] = "naive"
    return df


def write_report_time(report_dir, prefix):
    path = (REPO_ROOT / "synthesis" / "*" / "sim.log").as_posix()
    rows = []
    for file_path in glob.glob(path):
        project = Path(file_path).parent.name
        if not project.startswith(prefix):
            continue
        if project in EXCLUDED_PROJECTS:
            print(f"Skipping excluded project: {project}")
            continue
        side = parse_side(project)
        time_ns = parse_time(file_path)
        cycles = parse_cycles(file_path)
        if side is None or time_ns is None or cycles is None:
            continue
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
        raise SystemExit("No valid sim.log files found.")

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
    path = (
        REPO_ROOT
        / "synthesis"
        / "*"
        / "logical"
        / "results"
        / "reports"
        / "*_area.rpt"
    )
    all_files = glob.glob(path.as_posix())
    report_area = {project_name_from_report(f): read_file(f) for f in all_files}
    report_area = {k: v for k, v in report_area.items() if k.startswith(prefix)}
    if prefix == "sys-":
        area_path = (
            SYS_NAIVE_DIR
            / "logical"
            / "results"
            / "reports"
            / "convolution_area.rpt"
        )
        if area_path.exists():
            report_area[SYS_NAIVE_PROJECT] = read_file(area_path)
    excluded_area = {k for k in report_area if k in EXCLUDED_PROJECTS}
    for name in sorted(excluded_area):
        print(f"Skipping excluded project: {name}")
    report_area = {
        k: v for k, v in report_area.items() if k not in EXCLUDED_PROJECTS
    }

    cell_count = {k: v[14].split()[1] for k, v in report_area.items()}
    cell_area = {k: v[14].split()[2] for k, v in report_area.items()}
    net_area = {k: v[14].split()[3] for k, v in report_area.items()}
    total_area = {k: v[14].split()[4] for k, v in report_area.items()}

    path = (
        REPO_ROOT
        / "synthesis"
        / "*"
        / "logical"
        / "results"
        / "reports"
        / "*_clock_gating.rpt"
    )
    all_files = glob.glob(path.as_posix())
    report_clock = {
        project_name_from_report(f): read_file(f) for f in all_files
    }
    report_clock = {
        k: v for k, v in report_clock.items() if k.startswith(prefix)
    }
    if prefix == "sys-":
        clock_path = (
            SYS_NAIVE_DIR
            / "logical"
            / "results"
            / "reports"
            / "convolution_clock_gating.rpt"
        )
        if clock_path.exists():
            report_clock[SYS_NAIVE_PROJECT] = read_file(clock_path)
    excluded_clock = {k for k in report_clock if k in EXCLUDED_PROJECTS}
    for name in sorted(excluded_clock):
        print(f"Skipping excluded project: {name}")
    report_clock = {
        k: v for k, v in report_clock.items() if k not in EXCLUDED_PROJECTS
    }

    flop_count = {k: v[-4].split()[1] for k, v in report_clock.items()}

    df = pd.DataFrame(
        {
            "cell-count": cell_count,
            "cell-area-um": cell_area,
            "net-area-um": net_area,
            "total-area-um": total_area,
            "flop-count": flop_count,
        }
    )

    dft = df.T
    dft.columns = [format_project_name(n) for n in dft.columns]
    dft.sort_index(axis=1, inplace=True)

    df = dft.T
    df.columns = [
        "Cell Count",
        "Cell Area um^2",
        "Net Area um^2",
        "Total Area um^2",
        "Flop Count",
    ]

    df.insert(0, "Project", [format_project_name(n) for n in df.index])
    df = add_name_mult_columns(df, "Project")
    column_order = ["Project", "nome", "mult", "extra"]
    df = df[column_order + [c for c in df.columns if c not in column_order]]
    df.sort_values(by=["Project"], inplace=True)
    df.reset_index(drop=True, inplace=True)
    label = prefix.rstrip("-")
    df.to_csv(report_dir / f"{label}-report-logical.csv", index=False)


def write_report_power(report_dir, prefix):
    path = REPO_ROOT / "synthesis" / "*" / "power" / "power_evaluation.txt"
    all_files = glob.glob(path.as_posix())
    filtered_files = []
    for f in all_files:
        name = Path(f).parent.parent.name
        if not name.startswith(prefix):
            continue
        if name in EXCLUDED_PROJECTS:
            print(f"Skipping excluded project: {name}")
            continue
        filtered_files.append(f)

    if prefix == "sys-":
        power_path = SYS_NAIVE_DIR / "power" / "power_evaluation.txt"
        if power_path.exists():
            filtered_files.append(power_path.as_posix())

    if not filtered_files:
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

    file_names = [Path(f).parent.parent.name for f in filtered_files]
    if prefix == "sys-":
        file_names = [
            SYS_NAIVE_PROJECT if name == "convolution" else name
            for name in file_names
        ]
    report = [read_file(f) for f in filtered_files]
    columns = report[0][15].split()[1:5]
    indexes = [v.split()[0] for v in report[0][17:27] if "--" not in v]
    data = [
        [
            [float(i) for i in vv.split()[1:5]]
            for vv in v[16:27]
            if "--" not in vv
        ]
        for v in report
    ]

    list_df = {
        f: pd.DataFrame(columns=columns, index=indexes, data=list(d))
        for f, d in zip(file_names, data)
    }
    df_total = pd.DataFrame({f: df["Total"] for f, df in list_df.items()}).T
    df_total.insert(
        0, "Project", [format_project_name(n) for n in df_total.index]
    )
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
    output_dir = REPO_ROOT / ".." / "dissertation-doc" / "data" / "chap7"
    output_dir = output_dir.resolve()
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
    output_dir = REPO_ROOT / ".." / "dissertation-doc" / "data" / "chap7"
    output_dir = output_dir.resolve()
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
    output_dir = REPO_ROOT / ".." / "dissertation-doc" / "data" / "chap7"
    output_dir = output_dir.resolve()
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
    output_dir = REPO_ROOT / ".." / "dissertation-doc" / "data" / "chap7"
    output_dir = output_dir.resolve()
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
    output_dir = REPO_ROOT / ".." / "dissertation-doc" / "data" / "chap7"
    output_dir = output_dir.resolve()
    if not output_dir.exists():
        print(f"Skipping chap7 power/cycles export, missing: {output_dir}")
        return
    df = df[["nome", "mult", "energy", "cycles", "power", "cell_area"]]
    df = _add_distance_norm(
        df, ["cycles", "energy", "power", "cell_area"], "nome"
    )
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
    output_dir = REPO_ROOT / ".." / "dissertation-doc" / "data" / "chap7"
    output_dir = output_dir.resolve()
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
    output_dir = REPO_ROOT / ".." / "dissertation-doc" / "data" / "chap7"
    output_dir = output_dir.resolve()
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
    output_dir = REPO_ROOT / ".." / "dissertation-doc" / "data" / "chap7"
    output_dir = output_dir.resolve()
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


def main():
    report_dir = Path(__file__).resolve().parent.parent / "report"
    for prefix in ("sys-", "conv-"):
        write_report_time(report_dir, prefix)
        write_report_logical(report_dir, prefix)
        write_report_power(report_dir, prefix)
        write_report_merge(report_dir, prefix)
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


if __name__ == "__main__":
    main()
