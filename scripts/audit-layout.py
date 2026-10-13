#!/usr/bin/env python3
"""Read-only audit of active ASIC config file references."""

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parent.parent
ARCHITECTURES = ("conv2x2", "conv3x3", "conv4x4")
SKIP_PARTS = {"_template_conv", "_template_sys", "archive"}


def referenced_paths(list_file):
    for line_number, raw_line in enumerate(
        list_file.read_text(encoding="utf-8").splitlines(), start=1
    ):
        line = raw_line.split("#", 1)[0].strip()
        if not line:
            continue
        # The current manifests use one repository-relative path per line.
        # Keep this conservative: a future unsupported format should be visible.
        parts = line.split()
        if len(parts) != 1:
            yield line_number, line, None
            continue
        yield line_number, parts[0], ROOT / parts[0]


def main():
    config_count = 0
    reference_count = 0
    missing = []
    unsupported = []
    datasets = set()
    source_refs = set()

    for arch in ARCHITECTURES:
        synthesis_root = ROOT / "rtl" / arch / "synthesis"
        if not synthesis_root.is_dir():
            continue
        for list_file in sorted(synthesis_root.rglob("list-file.txt")):
            relative = list_file.relative_to(synthesis_root)
            if any(part in SKIP_PARTS for part in relative.parts):
                continue
            config_count += 1
            for line_number, value, path in referenced_paths(list_file):
                reference_count += 1
                if path is None:
                    unsupported.append((list_file, line_number, value))
                    continue
                if not path.is_file():
                    missing.append((list_file, line_number, value))
                    continue
                if path.suffix == ".sv" and path.name.startswith("conv-"):
                    source_refs.add(path.resolve())
                if "/data/" in value and value.endswith("pack_data.sv"):
                    datasets.add(path.resolve())

            rtl_top_file = list_file.with_name("rtl-top-file.txt")
            if rtl_top_file.is_file():
                entries = [
                    line.strip()
                    for line in rtl_top_file.read_text(encoding="utf-8").splitlines()
                    if line.strip() and not line.lstrip().startswith("#")
                ]
                if len(entries) != 1:
                    unsupported.append((rtl_top_file, 1, "expected one RTL source path"))
                else:
                    top_path = ROOT / entries[0]
                    if not top_path.is_file():
                        missing.append((rtl_top_file, 1, entries[0]))
                    elif top_path.resolve() not in source_refs:
                        missing.append(
                            (rtl_top_file, 1, f"top source not listed in list-file.txt: {entries[0]}")
                        )

    root_rtl = set()
    for arch in ARCHITECTURES:
        root_rtl.update(
            path.resolve()
            for path in (ROOT / "rtl" / arch).glob("conv-*.sv")
            if path.is_file()
        )
    unreferenced = sorted(root_rtl - source_refs)

    print(f"Synthesis manifests checked: {config_count}")
    print(f"Manifest entries checked: {reference_count}")
    print(f"Distinct referenced pack_data.sv files: {len(datasets)}")
    print(f"Root-level convolution RTL sources: {len(root_rtl)}")
    print(f"Root-level convolution RTL referenced by a manifest: {len(root_rtl & source_refs)}")

    if unreferenced:
        print("\nINFO: root-level convolution RTL not referenced by these manifests:")
        for path in unreferenced:
            print(f"  {path.relative_to(ROOT)}")
        print("  This is informational; RTL may be simulation-only or awaiting a flow.")

    if unsupported:
        print("\nERROR: unsupported list-file entry format:")
        for path, line_number, value in unsupported:
            print(f"  {path.relative_to(ROOT)}:{line_number}: {value}")
    if missing:
        print("\nERROR: referenced files not found:")
        for path, line_number, value in missing:
            print(f"  {path.relative_to(ROOT)}:{line_number}: {value}")

    return 1 if unsupported or missing else 0


if __name__ == "__main__":
    sys.exit(main())
