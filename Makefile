# Repository-level entry points for common FastConv tasks.
# Run long simulations and all ASIC EDA targets inside tmux.

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

PYTHON ?= $(if $(wildcard ../fast-convolution-rtl/.venv/bin/python),../fast-convolution-rtl/.venv/bin/python,python3)

# RTL simulation selection. CONFIG is the algorithm name for stream-column
# simulations (ifn9, tcn9, tcn16, or wpn16). ASIC targets use the exact RTL
# basename as CONFIG instead.
ARCH ?= conv2x2
ALGORITHM ?=
NUM_MULT ?= 8
PREFETCH_COLUMNS ?=
VARIANT ?= trunc-column

# ASIC synthesis configuration selection.
CONFIG ?=
CONFIG_ROOT = rtl/$(ARCH)/synthesis/$(CONFIG)

REPORT_ARGS ?=
REPORT_OPTIONS = $(if $(filter 1,$(INCLUDE_ARCHIVED)),--include-archived,) $(REPORT_ARGS)

.PHONY: help report metrics sim sim-all require-tmux require-asic-selection \
	check-asic-runners synth gate-sim power flow list-configs

help:
	@printf '%s\n' \
	  'FastConv repository tasks' \
	  '' \
	  'Reports:' \
	  '  make report [INCLUDE_ARCHIVED=1] [REPORT_ARGS="..."]' \
	  '  make metrics' \
	  '' \
	  'RTL simulation:' \
	  '  make sim ARCH=conv2x2 VARIANT=std' \
	  '  make sim ARCH=conv2x2 VARIANT=trunc-column NUM_MULT=8' \
	  '  make sim ARCH=conv3x3 ALGORITHM=ifn9 NUM_MULT=6 PREFETCH_COLUMNS=2' \
	  '  make sim ARCH=conv4x4 ALGORITHM=tcn16 NUM_MULT=6 PREFETCH_COLUMNS=3' \
	  '  make sim-all   # all active root RTL simulation cases' \
	  '' \
	  'ASIC flow (CONFIG is the exact synthesis directory name):' \
	  '  make synth ARCH=conv4x4 CONFIG=conv-tcn16-...-trunc-column' \
	  '  make gate-sim ARCH=conv4x4 CONFIG=conv-tcn16-...-trunc-column' \
	  '  make power ARCH=conv4x4 CONFIG=conv-tcn16-...-trunc-column' \
	  '  make flow ARCH=conv4x4 CONFIG=conv-tcn16-...-trunc-column' \
	  '  make list-configs ARCH=conv4x4' \
	  '' \
	  'Use make help for names; run long simulations and ASIC EDA inside tmux.'

# Consolidate RTL-local synthesis, simulation, and power reports. The helper
# Python environment is selected above when available; override PYTHON if needed.
report:
	$(PYTHON) scripts/report.py $(REPORT_OPTIONS)

metrics:
	$(PYTHON) scripts/metrics.py

# Run one selected functional RTL simulation. The 3x3/4x4 targets use the
# active streaming-column Makefile flow; 2x2 offers its standard and column
# variants through its dedicated targets.
sim: require-tmux
	@set -euo pipefail; \
	case "$(ARCH)" in \
	  conv2x2) \
	    case "$(VARIANT)" in \
	      std) target=run-std ;; \
	      std-column) target=run-std-column ;; \
	      trunc-column) \
	        case "$(NUM_MULT)" in \
	          4) target=run-stream08-prefetch8-rowconst4-trunc-column-4mac ;; \
	          8) target=run-stream08-prefetch8-rowconst4-trunc-column ;; \
	          *) echo 'For conv2x2 trunc-column, NUM_MULT must be 4 or 8.' >&2; exit 2 ;; \
	        esac ;; \
	      *) echo 'conv2x2 VARIANT must be std, std-column, or trunc-column.' >&2; exit 2 ;; \
	    esac; \
	    $(MAKE) -C rtl/conv2x2 "$$target" ;; \
	  conv3x3|conv4x4) \
	    test -n "$(ALGORITHM)" || { echo 'Set ALGORITHM (ifn9, tcn9, tcn16, or wpn16).' >&2; exit 2; }; \
	    test -n "$(PREFETCH_COLUMNS)" || { echo 'Set PREFETCH_COLUMNS to select the matching RTL file.' >&2; exit 2; }; \
	    test "$(NUM_MULT)" -gt 0 || { echo 'NUM_MULT must be a positive integer.' >&2; exit 2; }; \
	    $(MAKE) -C rtl/$(ARCH) run-stream-column \
	      CONFIG=$(ALGORITHM) NUM_MULT=$(NUM_MULT) STREAM_COLUMN_NUM_MULT=$(NUM_MULT) \
	      STREAM_COLUMN_PREFETCH_COLUMNS=$(PREFETCH_COLUMNS) ;; \
	  *) echo 'ARCH must be conv2x2, conv3x3, or conv4x4.' >&2; exit 2 ;; \
	esac

# This batch is intentionally explicit and potentially long; it runs the
# tracked active-RTL Verilator cases and stores results below simulation_results/.
sim-all: require-tmux
	./scripts/run-root-rtl-simulations.sh

require-tmux:
	@if [[ -z "$${TMUX:-}" ]]; then \
	  echo 'This is a long-running task. Start tmux first, then run make again.' >&2; \
	  echo 'Example: tmux new-session -s fastconv' >&2; \
	  exit 2; \
	fi

require-asic-selection:
	@case "$(ARCH)" in conv2x2|conv3x3|conv4x4) ;; \
	  *) echo 'ARCH must be conv2x2, conv3x3, or conv4x4.' >&2; exit 2 ;; \
	esac
	@test -n "$(CONFIG)" || { echo 'Set CONFIG to the exact directory name under rtl/$(ARCH)/synthesis/.' >&2; exit 2; }
	@test -d "$(CONFIG_ROOT)" || { echo 'Synthesis configuration not found: $(CONFIG_ROOT)' >&2; exit 2; }

check-asic-runners: require-asic-selection
	@test -f "$(CONFIG_ROOT)/logical/run.sh" || { echo 'Missing logical/run.sh in $(CONFIG_ROOT).' >&2; exit 2; }
	@test -f "$(CONFIG_ROOT)/sim/run.sh" || { echo 'Missing sim/run.sh in $(CONFIG_ROOT).' >&2; exit 2; }
	@test -f "$(CONFIG_ROOT)/power/run.sh" || { echo 'Missing power/run.sh in $(CONFIG_ROOT).' >&2; exit 2; }

synth: require-tmux require-asic-selection
	@test -f "$(CONFIG_ROOT)/logical/run.sh" || { echo 'Missing logical/run.sh in $(CONFIG_ROOT).' >&2; exit 2; }
	@bash "$(CONFIG_ROOT)/logical/run.sh"

gate-sim: require-tmux require-asic-selection
	@test -f "$(CONFIG_ROOT)/sim/run.sh" || { echo 'Missing sim/run.sh in $(CONFIG_ROOT).' >&2; exit 2; }
	@bash "$(CONFIG_ROOT)/sim/run.sh"

power: require-tmux require-asic-selection
	@test -f "$(CONFIG_ROOT)/power/run.sh" || { echo 'Missing power/run.sh in $(CONFIG_ROOT).' >&2; exit 2; }
	@bash "$(CONFIG_ROOT)/power/run.sh"

# Keep the flow sequential: power consumes the simulation activity and mapped
# netlist created by the preceding stages. A failure stops the remaining steps.
flow: require-tmux check-asic-runners
	$(MAKE) synth ARCH=$(ARCH) CONFIG=$(CONFIG)
	$(MAKE) gate-sim ARCH=$(ARCH) CONFIG=$(CONFIG)
	$(MAKE) power ARCH=$(ARCH) CONFIG=$(CONFIG)

list-configs:
	@case "$(ARCH)" in conv2x2|conv3x3|conv4x4) ;; \
	  *) echo 'ARCH must be conv2x2, conv3x3, or conv4x4.' >&2; exit 2 ;; \
	esac
	@find "rtl/$(ARCH)/synthesis" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
