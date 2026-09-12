#!/usr/bin/env bash
set -euo pipefail

# The root runner is only an index. Each RTL directory owns its configurations
# under rtl/conv*/synthesis/<configuration>; no experiment is stored here.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ERROR_LOG="$SCRIPT_DIR/run-errors.txt"
MODE=""
FAILED=0

print_banner() {
    echo
    echo "========================================"
    echo "$1"
    echo "========================================"
}

resolve_path() {
    local candidate="$1"
    if [[ -e "$candidate" ]]; then
        printf '%s/%s\n' "$(cd "$(dirname "$candidate")" && pwd)" "$(basename "$candidate")"
    elif [[ -e "$SCRIPT_DIR/$candidate" ]]; then
        printf '%s/%s\n' "$(cd "$(dirname "$SCRIPT_DIR/$candidate")" && pwd)" "$(basename "$SCRIPT_DIR/$candidate")"
    elif [[ -e "$REPO_ROOT/$candidate" ]]; then
        printf '%s/%s\n' "$(cd "$(dirname "$REPO_ROOT/$candidate")" && pwd)" "$(basename "$REPO_ROOT/$candidate")"
    else
        printf '%s\n' "$candidate"
    fi
}

run_config() {
    local config="$1"
    local stage
    if [[ "$MODE" == vsim ]]; then
        [[ -f "$config/sim.tcl" ]] || { echo "Missing $config/sim.tcl" >&2; return 1; }
        print_banner "RUNNING: $config/sim.tcl"
        (cd "$config" && vsim -c -do sim.tcl)
        return
    fi
    for stage in logical sim power; do
        [[ -z "$MODE" || "$MODE" == "$stage" ]] || continue
        [[ -f "$config/$stage/run.sh" ]] || { echo "Missing $config/$stage/run.sh" >&2; return 1; }
        print_banner "RUNNING: $config/$stage"
        (cd "$config/$stage" && bash ./run.sh)
    done
}

run_target() {
    local path="$1"
    path="$(resolve_path "$path")"
    if [[ -f "$path" && "$(basename "$path")" == run.sh ]]; then
        (cd "$(dirname "$path")" && bash ./run.sh)
    elif [[ -f "$path" && "$(basename "$path")" == sim.tcl ]]; then
        (cd "$(dirname "$path")" && vsim -c -do sim.tcl)
    elif [[ -f "$path/logical/run.sh" && -f "$path/power/run.sh" ]]; then
        run_config "$path"
    else
        echo "Unknown synthesis target: $path" >&2
        return 1
    fi
}

> "$ERROR_LOG"

ARGS=()
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -logical|-sim|-power|-vsim)
            MODE="${1#-}"
            shift
            ;;
        --)
            shift
            ARGS+=("$@")
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

if [[ "${#ARGS[@]}" -gt 0 ]]; then
    for target in "${ARGS[@]}"; do
        if ! run_target "$target"; then
            echo "$target" >> "$ERROR_LOG"
            FAILED=1
        fi
    done
else
    while IFS= read -r -d '' stage_script; do
        config="$(dirname "$(dirname "$stage_script")")"
        if ! run_config "$config"; then
            echo "$config" >> "$ERROR_LOG"
            FAILED=1
        fi
    done < <(find "$REPO_ROOT/rtl" -type f -path '*/synthesis/*/logical/run.sh' -print0 | sort -z)
fi

exit "$FAILED"
