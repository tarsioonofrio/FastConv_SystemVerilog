SHELL := /bin/bash
.DEFAULT_GOAL := run

.PHONY: run _run help

help:
	@echo "Usage:"
	@echo "  make                  # run all projects (logical -> sim -> power)"
	@echo "  make <project>         # run logical/sim/power in that project"
	@echo "  make <path>            # run a specific logical/sim/power folder"
	@echo "  make run RUN_PATH=<path>   # same as above"

run:
	@$(MAKE) --no-print-directory _run

%:
	@$(MAKE) --no-print-directory _run RUN_PATHS="$@"

_run:
	@set -euo pipefail; \
	run_dir() { \
		local path="$$1"; \
		if [ -f "$$path/run.sh" ]; then \
			( cd "$$path" && ./run.sh ); \
			return; \
		fi; \
		if [ -f "$$path/logical/run.sh" ] && [ -f "$$path/sim/run.sh" ] && [ -f "$$path/power/run.sh" ]; then \
			for stage in logical sim power; do \
				( cd "$$path/$$stage" && ./run.sh ); \
			done; \
			return; \
		fi; \
		echo "Unknown target: $$path" >&2; \
		exit 2; \
	}; \
	if [ -n "$${RUN_PATH-}" ]; then \
		run_dir "$$RUN_PATH"; \
		exit 0; \
	fi; \
	if [ -n "$${RUN_PATHS-}" ]; then \
		for p in $$RUN_PATHS; do \
			run_dir "$$p"; \
		done; \
		exit 0; \
	fi; \
	for d in */; do \
		if [ "$$d" = "source/" ] || [ "$$d" = "template/" ]; then \
			continue; \
		fi; \
		if [ -f "$$d/logical/run.sh" ] && [ -f "$$d/sim/run.sh" ] && [ -f "$$d/power/run.sh" ]; then \
			run_dir "$$d"; \
		fi; \
	done
