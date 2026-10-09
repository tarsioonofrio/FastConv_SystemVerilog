#!/usr/bin/env bash
set -u -o pipefail

ROOT=$(git rev-parse --show-toplevel)
RUN_ROOT=${RUN_ROOT:-/tmp/fastconv-root-rtl-simulations}
FAILURES=0

mkdir -p "$RUN_ROOT"

write_metadata() {
  local result_dir=$1 source=$2 dataset=$3 config=$4 num_mult=$5 prefetch_columns=$6
  {
    printf 'source=%s\n' "$source"
    printf 'source_sha256=%s\n' "$(sha256sum "$source" | awk '{print $1}')"
    printf 'dataset=%s\n' "$dataset"
    printf 'dataset_sha256=%s\n' "$(sha256sum "$dataset" | awk '{print $1}')"
    printf 'config=%s\n' "$config"
    printf 'num_mult=%s\n' "$num_mult"
    printf 'prefetch_columns=%s\n' "$prefetch_columns"
    printf 'git_commit=%s\n' "$(git -C "$ROOT" rev-parse HEAD)"
    printf 'verilator=%s\n' "$(verilator --version)"
  } > "$result_dir/metadata.txt"
}

record_result() {
  local summary=$1 name=$2 status=$3 result_dir=$4
  local cycles= elapsed_ns
  if [[ -f "$result_dir/execution_time.txt" ]]; then
    cycles=$(awk -F= '$1 == "job_execution_cycles" {print $2}' "$result_dir/execution_time.txt")
    elapsed_ns=$(awk -F= '$1 == "job_execution_time_ns" {print $2}' "$result_dir/execution_time.txt")
  fi
  printf '%s,%s,%s,%s\n' "$name" "$status" "${cycles:-}" "${elapsed_ns:-}" >> "$summary"
  if [[ "$status" != PASS ]]; then
    FAILURES=$((FAILURES + 1))
  fi
}

run_2x2() {
  local source_name=$1 macs=$2 target=$3
  local arch="$ROOT/rtl/conv2x2"
  local source="$arch/$source_name"
  local dataset="$arch/data/tcn4/sim/sim-032-3-3-normal-trunc/pack_data.sv"
  local result_dir="$arch/simulation_results/${source_name%.sv}"
  local objdir="$arch/obj_dir/stream08-prefetch8-rowconst4-trunc-column"
  if [[ "$macs" == 4 ]]; then
    objdir+="-4mac"
  fi
  local summary="$arch/simulation_results/summary.csv"
  mkdir -p "$result_dir" "$objdir"
  write_metadata "$result_dir" "$source" "$dataset" tcn4 "$macs" 2
  if make -C "$arch" -B "$target" > "$result_dir/build.log" 2>&1; then
    if (cd "$result_dir" && "$objdir/Vtb_prefetch8_column" > simulation.log 2>&1) &&
       grep -q 'simulation passed:' "$result_dir/simulation.log" &&
       [[ -s "$result_dir/execution_time.txt" ]]; then
      record_result "$summary" "$source_name" PASS "$result_dir"
      rm -rf -- "$objdir"
      return
    fi
  fi
  record_result "$summary" "$source_name" FAIL "$result_dir"
}

run_column() {
  local arch_name=$1 source_name=$2 config=$3 macs=$4 prefetch_columns=$5
  local extra_flags=${6:-}
  local arch="$ROOT/rtl/$arch_name"
  local source="$arch/$source_name"
  local dataset="$arch/data/$config/sim/sim-032-3-3-normal-trunc/pack_data.sv"
  local result_dir="$arch/simulation_results/${source_name%.sv}"
  local objdir="$RUN_ROOT/${source_name%.sv}/obj_dir"
  local summary="$arch/simulation_results/summary.csv"
  mkdir -p "$result_dir" "$(dirname "$objdir")"
  write_metadata "$result_dir" "$source" "$dataset" "$config" "$macs" "$prefetch_columns"
  local -a make_args=("-C" "$arch" -B stream-column "CONFIG=$config"
    "NUM_MULT=$macs" "STREAM_COLUMN_NUM_MULT=$macs"
    "STREAM_COLUMN_PREFETCH_COLUMNS=$prefetch_columns"
    "STREAM_COLUMN_SRC=$source_name" "STREAM_COLUMN_OBJDIR=$objdir")
  if [[ -n "$extra_flags" ]]; then
    make_args+=("STREAM_COLUMN_EXTRA_FLAGS=$extra_flags")
  fi
  if make "${make_args[@]}" > "$result_dir/build.log" 2>&1; then
    if (cd "$result_dir" && "$objdir/Vtb_stream_column" > simulation.log 2>&1) &&
       grep -q 'stream-column simulation passed:' "$result_dir/simulation.log" &&
       [[ -s "$result_dir/execution_time.txt" ]]; then
      record_result "$summary" "$source_name" PASS "$result_dir"
      rm -rf -- "$objdir"
      return
    fi
  fi
  record_result "$summary" "$source_name" FAIL "$result_dir"
}

for summary in "$ROOT"/rtl/conv{2x2,3x3,4x4}/simulation_results/summary.csv; do
  mkdir -p "$(dirname "$summary")"
  printf 'rtl,status,job_execution_cycles,job_execution_time_ns\n' > "$summary"
done

run_2x2 conv-i24-h13-t08-o4-m04-stream08-prefetch8-rowconst4-trunc-column.sv 4 stream08-prefetch8-rowconst4-trunc-column-4mac
run_2x2 conv-i24-h13-t08-o4-m08-stream08-prefetch8-rowconst4-trunc-column.sv 8 stream08-prefetch8-rowconst4-trunc-column

run_column conv3x3 conv-ifn9-i40-h15-t12-o9-m06-stream12-prefetch15-rowconst6-trunc-column.sv ifn9 6 3
run_column conv3x3 conv-ifn9-i40-h21-t24-o9-m12-stream12-prefetch15-rowconst6-trunc-column.sv ifn9 12 3
run_column conv3x3 conv-ifn9-i40-h27-t36-o9-m18-stream12-prefetch15-rowconst6-trunc-column.sv ifn9 18 3
run_column conv3x3 conv-tcn9-i40-h14-t10-o9-m05-stream10-prefetch15-rowconst5-trunc-column.sv tcn9 5 3

run_column conv4x4 conv-tcn16-i54-h15-t12-o16-m06-stream12-prefetch18-rowconst6-trunc-column.sv tcn16 6 3
run_column conv4x4 conv-tcn16-i54-h21-t24-o16-m12-stream12-prefetch18-rowconst6-trunc-column.sv tcn16 12 3
run_column conv4x4 conv-tcn16-i54-h27-t36-o16-m18-stream12-prefetch18-rowconst6-trunc-column.sv tcn16 18 3
run_column conv4x4 conv-tcn16-i60-h15-t12-o16-m06-stream12-prefetch24-rowconst6-trunc-column.sv tcn16 6 4
run_column conv4x4 conv-tcn16-i60-h21-t24-o16-m12-stream12-prefetch24-rowconst6-trunc-column.sv tcn16 12 4
run_column conv4x4 conv-tcn16-i60-h27-t36-o16-m18-stream12-prefetch24-rowconst6-trunc-column.sv tcn16 18 4
run_column conv4x4 conv-wpn16-i54-h17-t16-o16-m08-stream16-prefetch18-rowconst8-trunc-column.sv wpn16 8 3
run_column conv4x4 conv-wpn16-i54-h25-t32-o16-m16-stream16-prefetch18-rowconst8-trunc-column.sv wpn16 16 3
run_column conv4x4 conv-wpn16-i54-h41-t64-o16-m32-stream16-prefetch18-rowconst8-trunc-column.sv wpn16 32 3
run_column conv4x4 conv-wpn16-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8-trunc-column.sv wpn16 8 4
run_column conv4x4 conv-wpn16-i60-h25-t32-o16-m16-stream16-prefetch24-rowconst8-trunc-column.sv wpn16 16 4
run_column conv4x4 conv-wpn16-i60-h41-t64-o16-m32-stream16-prefetch24-rowconst8-trunc-column.sv wpn16 32 4
run_column conv4x4 conv-wpn16-pipe-i60-h17-t16-o16-m08-stream16-prefetch24-rowconst8-trunc-column.sv wpn16 8 4 '-DWPN16_PIPE_WEIGHT_TRANSFORM -DWPN16_PIPE_DSP_MULTIPLIER -DWPN16_PIPE_INVERSE_ACCUMULATE'

printf 'Campaign complete; failed simulations: %s\n' "$FAILURES"
exit "$FAILURES"
