#!/usr/bin/env bash
set -euo pipefail

print_banner() {
  local msg="$1"
  echo
  echo "========================================"
  echo "$msg"
  echo "========================================"
  echo
}

run_dir() {
  local path="$1"
  if [ -f "$path/run.sh" ]; then
    print_banner "RUNNING: $path"
    ( cd "$path" && bash ./run.sh )
    return
  fi
  if [ -f "$path/logical/run.sh" ] && [ -f "$path/sim/run.sh" ] && [ -f "$path/power/run.sh" ]; then
    for stage in logical sim power; do
      print_banner "RUNNING: $path/$stage"
      ( cd "$path/$stage" && bash ./run.sh )
    done
    return
  fi
  echo "Unknown target: $path" >&2
  exit 2
}

if [ "$#" -gt 0 ]; then
  for p in "$@"; do
    run_dir "$p"
  done
  exit 0
fi

for d in */; do
  if [ "$d" = "source/" ] || [ "$d" = "template/" ]; then
    continue
  fi
  if [ -f "$d/logical/run.sh" ] && [ -f "$d/sim/run.sh" ] && [ -f "$d/power/run.sh" ]; then
    run_dir "$d"
  fi
done
