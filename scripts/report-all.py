import glob
import re
from pathlib import Path

import pandas as pd

EXCLUDED_PROJECTS = {"source", "template"}
REPO_ROOT = Path(__file__).resolve().parent.parent


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
    df["nome"] = df[project_col].astype(str).str[:4]
    df["mult"] = df[project_col].map(parse_multipliers)
    df["extra"] = df[project_col].map(parse_extra)
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
            {"project": project, "side": side, "time/ns": time_ns, "cycles": cycles}
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
    path = REPO_ROOT / "synthesis" / "*" / "logical" / "results" / "reports" / "*_area.rpt"
    all_files = glob.glob(path.as_posix())
    report_area = {project_name_from_report(f): read_file(f) for f in all_files}
    report_area = {k: v for k, v in report_area.items() if k.startswith(prefix)}
    excluded_area = {k for k in report_area if k in EXCLUDED_PROJECTS}
    for name in sorted(excluded_area):
        print(f"Skipping excluded project: {name}")
    report_area = {k: v for k, v in report_area.items() if k not in EXCLUDED_PROJECTS}

    cell_count = {k: v[14].split()[1] for k, v in report_area.items()}
    cell_area = {k: v[14].split()[2] for k, v in report_area.items()}
    net_area = {k: v[14].split()[3] for k, v in report_area.items()}
    total_area = {k: v[14].split()[4] for k, v in report_area.items()}

    path = REPO_ROOT / "rtl" / "conv" / "*" / "sintese" / "results" / "reports" / "*_clock_gating.rpt"
    all_files = glob.glob(path.as_posix())
    report_clock = {project_name_from_report(f): read_file(f) for f in all_files}
    report_clock = {k: v for k, v in report_clock.items() if k.startswith(prefix)}
    excluded_clock = {k for k in report_clock if k in EXCLUDED_PROJECTS}
    for name in sorted(excluded_clock):
        print(f"Skipping excluded project: {name}")
    report_clock = {k: v for k, v in report_clock.items() if k not in EXCLUDED_PROJECTS}

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
    report = [read_file(f) for f in filtered_files]
    columns = report[0][15].split()[1:5]
    indexes = [v.split()[0] for v in report[0][17:27] if "--" not in v]
    data = [
        [[float(i) for i in vv.split()[1:5]] for vv in v[16:27] if "--" not in vv]
        for v in report
    ]

    list_df = {
        f: pd.DataFrame(columns=columns, index=indexes, data=list(d))
        for f, d in zip(file_names, data)
    }
    df_total = pd.DataFrame({f: df["Total"] for f, df in list_df.items()}).T
    df_total.insert(0, "Project", [format_project_name(n) for n in df_total.index])
    df_total = add_name_mult_columns(df_total, "Project")
    column_order = ["Project", "nome", "mult", "extra"]
    df_total = df_total[column_order + [c for c in df_total.columns if c not in column_order]]
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
    df["energy"] = (df["Subtotal"] * df["time_ns"]) / 1000

    column_order = ["Project", "nome", "mult", "side", "extra", "time_ns", "cycles"]
    df = df[column_order + [c for c in df.columns if c not in column_order]]
    df.sort_values(by=["Project"], inplace=True)
    df.reset_index(drop=True, inplace=True)

    df.to_csv(report_dir / f"{label}-report-merged.csv", index=False)

    mask_9_032p = df["Project"].astype(str).str.contains(r"9-.*032p", regex=True)
    df_9_032p = df[mask_9_032p].copy()
    df_9_032p.reset_index(drop=True, inplace=True)
    df_9_032p.to_csv(report_dir / f"{label}-report-merged-9-032p.csv", index=False)

    mask_ifn9_06m = df["Project"].astype(str).str.startswith("IFn9-06m")
    df_ifn9_06m = df[mask_ifn9_06m].copy()
    df_ifn9_06m.reset_index(drop=True, inplace=True)
    df_ifn9_06m.to_csv(report_dir / f"{label}-report-merged-IFn9-06m.csv", index=False)


def write_chap7_conv_time(report_dir):
    source = report_dir / "conv-report-time.csv"
    if not source.exists():
        print(f"Skipping chap7 export, missing: {source}")
        return
    df = pd.read_csv(source)
    required_cols = {"nome", "mult", "cycles"}
    if not required_cols.issubset(df.columns):
        print(f"Skipping chap7 export, missing columns: {required_cols - set(df.columns)}")
        return
    df = df[["nome", "mult", "cycles"]].dropna()
    df["mult"] = pd.to_numeric(df["mult"], errors="coerce")
    df = df.dropna(subset=["mult"])

    def merge_cycles(series):
        values = pd.to_numeric(series, errors="coerce").dropna().unique()
        if len(values) == 0:
            return None
        if len(values) == 1:
            return values[0]
        return None

    df = df.groupby(["mult", "nome"], as_index=False)["cycles"].agg(merge_cycles)
    df_pivot = df.pivot(index="mult", columns="nome", values="cycles")
    df_pivot.sort_index(axis=0, inplace=True)
    df_pivot = df_pivot.reset_index()
    output_dir = REPO_ROOT / ".." / "dissertation-doc" / "data" / "chap7"
    output_dir = output_dir.resolve()
    if not output_dir.exists():
        print(f"Skipping chap7 export, missing: {output_dir}")
        return
    df_pivot.to_csv(output_dir / "conv-report-time.csv", index=False)


def main():
    report_dir = Path(__file__).resolve().parent.parent / "report"
    for prefix in ("sys-", "conv-"):
        write_report_time(report_dir, prefix)
        write_report_logical(report_dir, prefix)
        write_report_power(report_dir, prefix)
        write_report_merge(report_dir, prefix)
    write_chap7_conv_time(report_dir)


if __name__ == "__main__":
    main()
