#!/usr/bin/env bash
# Use bash from PATH for portability.
set -euo pipefail
# Exit on error, undefined var, or failed pipeline.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Resolve the script directory to support running from anywhere.
ERROR_LOG="$SCRIPT_DIR/run-errors.txt"
# Log file for failed paths, stored next to this script.
MODE=""
# Optional mode filter: logical, sim, or power.

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
    if [ -n "$MODE" ] && [ "$(basename "$path")" != "$MODE" ]; then
      # Reject leaf folders that do not match the requested mode.
      echo "Mode '$MODE' does not match: $path" >&2
      # Report a clear mismatch.
      echo "$path" >> "$ERROR_LOG"
      # Record the failing path.
      return 1
      # Propagate failure to the caller.
    fi
    print_banner "RUNNING: $path"
    # Show which folder is running.
    if ! ( cd "$path" && bash ./run.sh ); then
      # Capture failures without stopping the whole script.
      echo "$path" >> "$ERROR_LOG"
      # Record the failing path.
      return 1
      # Propagate failure to the caller.
    fi
    # Run in a subshell without changing caller CWD.
    return
    # Done for this path.
  fi
  if [ -f "$path/logical/run.sh" ] && [ -f "$path/sim/run.sh" ] && [ -f "$path/power/run.sh" ]; then
    # Project root case with 3 stages.
    for stage in logical sim power; do
      # Enforce logical -> sim -> power order.
      if [ -n "$MODE" ] && [ "$stage" != "$MODE" ]; then
        # Skip stages that are not selected.
        continue
        # Move to the next stage.
      fi
      print_banner "RUNNING: $path/$stage"
      # Show which stage is running.
      if ! ( cd "$path/$stage" && bash ./run.sh ); then
        # Capture failures without stopping the whole script.
        echo "$path/$stage" >> "$ERROR_LOG"
        # Record the failing stage path.
        return 1
        # Propagate failure to the caller.
      fi
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

> "$ERROR_LOG"
# Start a fresh error log for this run.

ARGS=()
# Collect non-option arguments as paths.
while [ "$#" -gt 0 ]; do
  # Parse command line arguments.
  case "$1" in
    -logical)
      # Select only logical stage.
      MODE="logical"
      # Set the mode filter.
      shift
      # Consume this flag.
      ;;
    -sim)
      # Select only sim stage.
      MODE="sim"
      # Set the mode filter.
      shift
      # Consume this flag.
      ;;
    -power)
      # Select only power stage.
      MODE="power"
      # Set the mode filter.
      shift
      # Consume this flag.
      ;;
    --)
      # End of options marker.
      shift
      # Consume the marker.
      break
      # Stop option parsing.
      ;;
    -*)
      # Reject unknown flags.
      echo "Unknown option: $1" >&2
      # Report invalid option.
      exit 2
      # Exit with error status.
      ;;
    *)
      # Treat as a target path.
      ARGS+=("$1")
      # Store the path.
      shift
      # Consume this argument.
      ;;
  esac
done

for p in "$@"; do
  # Append any remaining args after --.
  ARGS+=("$p")
  # Store the path.
done

if [ "${#ARGS[@]}" -gt 0 ]; then
  # If arguments are provided, treat each as a target.
  for p in "${ARGS[@]}"; do
    # Loop over all arguments.
    if ! run_dir "$p"; then
      # Track if any path fails.
      FAILED=1
      # Continue to next path.
    fi
    # Run each provided path.
  done
  if [ "${FAILED:-0}" -ne 0 ]; then
    # Signal failure if any path failed.
    exit 1
  fi
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
    if ! run_dir "$d"; then
      # Track if any path fails.
      FAILED=1
      # Continue to next project.
    fi
    # Run the project's stages in order.
  fi
done
if [ "${FAILED:-0}" -ne 0 ]; then
  # Signal failure if any path failed.
  exit 1
fi
