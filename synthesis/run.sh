#!/usr/bin/env bash
# Use bash from PATH for portability.
set -euo pipefail
# Exit on error, undefined var, or failed pipeline.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Resolve the script directory to support running from anywhere.

print_banner() {
  # Print a visible banner for each step.
  local msg="$1"
  # Capture the message argument.
  echo
  # Blank line for spacing.
  echo "========================================"
  # Top separator.
  echo "$msg"
  # Show the message content.
  echo "========================================"
  # Bottom separator.
  echo
  # Trailing blank line.
}

resolve_path() {
  # Normalize a path to an absolute path if possible.
  local in_path="$1"
  # Capture the input path.
  if [ -d "$in_path" ] || [ -f "$in_path" ]; then
    # If it exists as given, keep it.
    echo "$in_path"
    # Return the original path.
    return
  fi
  # Try relative to the script directory.
  if [ -d "$SCRIPT_DIR/$in_path" ] || [ -f "$SCRIPT_DIR/$in_path" ]; then
    # If it exists under the script directory, use that.
    echo "$SCRIPT_DIR/$in_path"
    # Return the resolved path.
    return
  fi
  # Fall back to the original input.
  echo "$in_path"
  # Let the caller handle missing paths.
}

run_dir() {
  # Run either a leaf run.sh or the logical/sim/power trio.
  local path
  # Declare the local path variable.
  path="$(resolve_path "$1")"
  # Capture the path argument.
  if [ -f "$path/run.sh" ]; then
    # Direct leaf script case.
    print_banner "RUNNING: $path"
    # Show which folder is running.
    ( cd "$path" && bash ./run.sh )
    # Run in a subshell without changing caller CWD.
    return
    # Done for this path.
  fi
  if [ -f "$path/logical/run.sh" ] && [ -f "$path/sim/run.sh" ] && [ -f "$path/power/run.sh" ]; then
    # Project root case with 3 stages.
    for stage in logical sim power; do
      # Enforce logical -> sim -> power order.
      print_banner "RUNNING: $path/$stage"
      # Show which stage is running.
      ( cd "$path/$stage" && bash ./run.sh )
      # Execute stage script in a subshell.
    done
    return
    # Done for this path.
  fi
  echo "Unknown target: $path" >&2
  # Fail fast on unexpected inputs.
  exit 2
  # Use a non-zero exit code for errors.
}

if [ "$#" -gt 0 ]; then
  # If arguments are provided, treat each as a target.
  for p in "$@"; do
    # Loop over all arguments.
    run_dir "$p"
    # Run each provided path.
  done
  exit 0
  # Exit after explicit targets are handled.
fi

for d in */; do
  # Iterate over subdirectories of synthesis/.
  if [ "$d" = "source/" ] || [ "$d" = "template/" ]; then
    # Skip non-project folders.
    continue
    # Move on to the next directory.
  fi
  if [ -f "$d/logical/run.sh" ] && [ -f "$d/sim/run.sh" ] && [ -f "$d/power/run.sh" ]; then
    # Only run directories that look like projects.
    run_dir "$d"
    # Run the project's stages in order.
  fi
done
