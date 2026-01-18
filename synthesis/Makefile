SHELL := /bin/bash
.DEFAULT_GOAL := run

.PHONY: run _run help

help:
	@echo "Usage:"
	@echo "  make                  # run all projects (logical -> sim -> power)"
	@echo "  make <project>         # run logical/sim/power in that project"
	@echo "  make <path>            # run a specific logical/sim/power folder"
	@echo "  make run PATH=<path>   # same as above"

run:
	@$(MAKE) --no-print-directory _run

ifneq ($(filter-out run help,$(MAKECMDGOALS)),)
TARGETS := $(filter-out run help,$(MAKECMDGOALS))
.PHONY: $(TARGETS)
$(TARGETS):
	@if [ "$@" = "$(firstword $(TARGETS))" ]; then \
		$(MAKE) --no-print-directory _run PATHS="$(TARGETS)"; \
	fi
endif

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
	if [ -n "$${PATH-}" ]; then \
		run_dir "$$PATH"; \
		exit 0; \
	fi; \
	if [ -n "$${PATHS-}" ]; then \
		for p in $$PATHS; do \
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
