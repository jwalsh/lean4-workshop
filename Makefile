# Lean 4 Workshop Makefile
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),FreeBSD)
SHELL := /usr/local/bin/bash
else
SHELL := /bin/bash
endif

.PHONY: help deps check build clean verify verify-examples verify-exercises \
        warmup solutions scratch tangle pdf emacs edit

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

deps: ## Check Lean 4 toolchain dependencies
	@echo "=== Lean 4 Toolchain Dependencies ==="
	@echo ""
	@echo "lean:"
	@which lean 2>/dev/null && lean --version || echo "  NOT FOUND - Install via elan or package manager"
	@echo ""
	@echo "lake:"
	@which lake 2>/dev/null && lake --version || echo "  NOT FOUND - Comes with Lean 4"
	@echo ""
	@echo "elan (optional version manager):"
	@which elan 2>/dev/null && elan --version || echo "  NOT FOUND - Install from https://github.com/leanprover/elan"
	@echo ""
	@echo "=== Editor Support ==="
	@echo "bin/l4w-emacs        isolated Emacs profile (lean4-mode + lsp, nothing touches ~/.emacs.d)"
	@echo "VS Code + lean4 extension also works"
	@echo ""

check: ## Verify Lean installation works
	@echo 'def main : IO Unit := IO.println "Hello, Lean 4"' | lean --stdin --run

build: ## Build the project with Lake
	lake build

clean: ## Clean build artifacts
	lake clean

# --- examples --------------------------------------------------------------

EXAMPLE_DIRS := satirical correct fp proofs data

verify-examples: ## Verify all examples compile
	@for d in $(EXAMPLE_DIRS); do \
	  echo "=== Verifying $$d examples ==="; \
	  for f in examples/$$d/*.lean; do echo "Checking $$f..."; lean "$$f" || exit 1; done; \
	  echo ""; \
	done; \
	echo "All examples verified!"

# --- exercises -------------------------------------------------------------

EXERCISES  := $(wildcard exercises/Ex*.lean)
SOLUTIONS  := $(wildcard exercises/Solutions/Sol*.lean)
WARMUP     := $(wildcard exercises/warmup/W*.lean)
WARMUP_SOL := $(wildcard exercises/warmup/Solutions/S*.lean)
SCRATCH    := $(wildcard scratch/*.lean)

verify-exercises: ## Verify exercises parse (sorry allowed) and solutions pass
	@echo "=== Verifying Exercises (sorry allowed) ==="
	@for f in $(EXERCISES) $(WARMUP); do echo "Checking $$f..."; lean "$$f" >/dev/null 2>&1 || true; done
	@$(MAKE) --no-print-directory solutions

warmup: ## Check the warm-up exercises; errors are the to-do list
	@for f in $(WARMUP); do echo "== $$f"; lean $$f; done; true

solutions: ## Verify every solution compiles with no errors
	@rc=0; for f in $(SOLUTIONS) $(WARMUP_SOL); do \
	  echo "== $$f"; lean $$f || rc=1; \
	  grep -q '\bsorry\b' $$f && echo "WARNING: $$f contains sorry"; \
	done; \
	printf 'a b\nc\n' | lean --run exercises/warmup/Solutions/S09_IO.lean | grep -qx '2 3' || rc=1; \
	exit $$rc

scratch: ## Verify tracked scratch files compile with no errors
	@rc=0; for f in $(SCRATCH); do echo "== $$f"; lean $$f || rc=1; done; exit $$rc

verify: verify-examples verify-exercises scratch ## Verify all Lean files

# --- documents and editor --------------------------------------------------

tangle: ## Tangle lean4-programming.org to exercises/Warmup.lean and check it
	emacs --batch -l org lean4-programming.org -f org-babel-tangle
	lean exercises/Warmup.lean; true

pdf: ## Export lean4-programming.org to PDF (pdflatex, listings, tcolorbox)
	emacs --batch -l org -l ox-latex \
	  --eval '(setq org-latex-src-block-backend (quote listings))' \
	  --eval '(setq org-latex-compiler "pdflatex")' \
	  --eval '(setq org-latex-listings-langs (cons (quote (lean "lean")) org-latex-listings-langs))' \
	  lean4-programming.org -f org-latex-export-to-pdf

emacs: ## Byte-compile lean4-workshop.el as a lint pass
	emacs --batch --eval "(package-initialize)" -L . -f batch-byte-compile lean4-workshop.el && rm -f lean4-workshop.elc

edit: ## Open the isolated Emacs profile (needs a terminal)
	bin/l4w-emacs
