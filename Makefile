# ==================================================================================== #
# PROJECT: AI Skills
# DESCRIPTION: Reusable AI agent skills for Claude Code and other AI tools
# ==================================================================================== #

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Core Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Project metadata
PROJECT_NAME := AI Skills
VERSION := 0.1.0

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Colors and Formatting
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ifneq ($(TERM),)
    RED := $(shell tput setaf 1)
    GREEN := $(shell tput setaf 2)
    YELLOW := $(shell tput setaf 3)
    BLUE := $(shell tput setaf 4)
    CYAN := $(shell tput setaf 6)
    BOLD := $(shell tput bold)
    DIM := $(shell tput dim)
    RESET := $(shell tput sgr0)
else
    RED :=
    GREEN :=
    YELLOW :=
    BLUE :=
    CYAN :=
    BOLD :=
    DIM :=
    RESET :=
endif

# Icons
CHECK := ✓
CROSS := ✗
INFO := ℹ
WARN := ⚠

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Helper Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

define print_header
	@echo ""
	@echo "$(BOLD)$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo "$(BOLD)$(BLUE)  $(1)$(RESET)"
	@echo "$(BOLD)$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo ""
endef

define print_success
	@echo "$(GREEN)$(CHECK)$(RESET) $(1)"
endef

define print_error
	@echo "$(RED)$(CROSS)$(RESET) $(1)"
endef

define print_warning
	@echo "$(YELLOW)$(WARN)$(RESET) $(1)"
endef

define print_info
	@echo "$(CYAN)$(INFO)$(RESET) $(1)"
endef

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Dependency Checks
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

.PHONY: check/deps
check/deps: ## Check required dependencies
	$(call print_header,Checking Dependencies)
	@MISSING=0; \
	\
	echo "$(BOLD)Required:$(RESET)"; \
	echo ""; \
	if command -v node >/dev/null 2>&1; then \
		NODE_VER=$$(node --version); \
		echo "$(GREEN)$(CHECK)$(RESET) node ($$NODE_VER)"; \
	else \
		echo "$(RED)$(CROSS)$(RESET) node not found"; \
		echo "  $(YELLOW)→$(RESET) Install: https://nodejs.org/"; \
		MISSING=$$((MISSING + 1)); \
	fi; \
	\
	if command -v npx >/dev/null 2>&1; then \
		NPX_VER=$$(npx --version 2>/dev/null); \
		echo "$(GREEN)$(CHECK)$(RESET) npx ($$NPX_VER)"; \
	else \
		echo "$(RED)$(CROSS)$(RESET) npx not found"; \
		MISSING=$$((MISSING + 1)); \
	fi; \
	\
	if command -v shellcheck >/dev/null 2>&1; then \
		SC_VER=$$(shellcheck --version 2>/dev/null | grep '^version:' | awk '{print $$2}'); \
		echo "$(GREEN)$(CHECK)$(RESET) shellcheck ($$SC_VER)"; \
	else \
		echo "$(YELLOW)$(WARN)$(RESET) shellcheck not found (needed for shell linting)"; \
		echo "  $(YELLOW)→$(RESET) Install: brew install shellcheck"; \
	fi; \
	\
	if command -v make >/dev/null 2>&1; then \
		MAKE_VER=$$(make --version 2>/dev/null | head -1); \
		echo "$(GREEN)$(CHECK)$(RESET) make ($$MAKE_VER)"; \
	else \
		echo "$(RED)$(CROSS)$(RESET) make not found"; \
		MISSING=$$((MISSING + 1)); \
	fi; \
	\
	echo ""; \
	if [ $$MISSING -eq 0 ]; then \
		echo "$(GREEN)$(CHECK)$(RESET) All dependencies satisfied"; \
	else \
		echo "$(RED)$(CROSS)$(RESET) $$MISSING dependencies missing"; \
		exit 1; \
	fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Installation
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

.PHONY: install
install: ## Install project dependencies
	$(call print_header,Installing Dependencies)
	@npm install
	$(call print_success,Dependencies installed)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Linting
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

.PHONY: lint
lint: lint/md lint/shell ## Run all linters
	$(call print_success,All linters passed)

.PHONY: lint/fix
lint/fix: lint/md/fix ## Auto-fix lint issues where possible
	$(call print_success,All auto-fixes applied)

.PHONY: lint/md
lint/md: ## Lint markdown files
	$(call print_header,Linting Markdown)
	@npx markdownlint-cli2 '**/*.md'
	$(call print_success,Markdown lint passed)

.PHONY: lint/md/fix
lint/md/fix: ## Fix markdown lint issues automatically
	$(call print_header,Fixing Markdown Lint Issues)
	@npx markdownlint-cli2 --fix '**/*.md'
	$(call print_success,Markdown fixes applied)

.PHONY: lint/shell
lint/shell: ## Lint shell scripts (shellcheck)
	$(call print_header,Linting Shell Scripts)
	@shellcheck --severity=warning -x .github/scripts/ci/*.sh .github/scripts/issues/*.sh .github/scripts/issues/lib/*.sh
	$(call print_success,Shell lint passed)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Formatting
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

.PHONY: format
format: ## Format markdown, JSON, and YAML files
	$(call print_header,Formatting Files)
	@npx prettier --write '**/*.{md,json,yml,yaml}'
	$(call print_success,Files formatted)

.PHONY: format/check
format/check: ## Check formatting without changes
	$(call print_header,Checking Format)
	@npx prettier --check '**/*.{md,json,yml,yaml}'
	$(call print_success,Format check passed)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Quality Assurance
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

.PHONY: qa
qa: lint format/check ## Run all quality checks
	$(call print_success,All quality checks passed)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Release
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# commit-and-tag-version bumps files + changelog only (--skip.commit --skip.tag),
# then we create the commit and tag manually.

RELEASE_FILES := CHANGELOG.md .semver Makefile

define _release_commit
	@NEW_VERSION=$$(cat .semver) && \
		git add $(RELEASE_FILES) && \
		git commit -m "chore(release): v$$NEW_VERSION" && \
		git tag -a "v$$NEW_VERSION" -m "chore(release): v$$NEW_VERSION"
endef

.PHONY: release
release: qa ## Create a release (auto-detect bump type from commits)
	$(call print_header,Creating Release)
	@npx commit-and-tag-version --skip.commit --skip.tag
	$(call _release_commit)
	$(call print_success,Release created)

.PHONY: release/dry-run
release/dry-run: ## Preview release without making changes
	$(call print_header,Release Dry Run)
	@npx commit-and-tag-version --dry-run

.PHONY: release/patch
release/patch: qa ## Create patch release (0.1.0 -> 0.1.1)
	$(call print_header,Creating Patch Release)
	@npx commit-and-tag-version --release-as patch --skip.commit --skip.tag
	$(call _release_commit)
	$(call print_success,Patch release created)

.PHONY: release/minor
release/minor: qa ## Create minor release (0.1.0 -> 0.2.0)
	$(call print_header,Creating Minor Release)
	@npx commit-and-tag-version --release-as minor --skip.commit --skip.tag
	$(call _release_commit)
	$(call print_success,Minor release created)

.PHONY: release/major
release/major: qa ## Create major release (0.1.0 -> 1.0.0)
	$(call print_header,Creating Major Release)
	@npx commit-and-tag-version --release-as major --skip.commit --skip.tag
	$(call _release_commit)
	$(call print_success,Major release created)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Cleanup
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

.PHONY: clean
clean: ## Clean temporary files
	$(call print_header,Cleaning Up)
	@rm -rf node_modules/ 2>/dev/null || true
	$(call print_success,Cleanup complete)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Help
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

.PHONY: help
help: ## Show this help message
	@echo "$(BOLD)$(BLUE)╔══════════════════════════════════════════════════════════════╗$(RESET)"
	@echo "$(BOLD)$(BLUE)║     $(PROJECT_NAME) v$(VERSION)                              ║$(RESET)"
	@echo "$(BOLD)$(BLUE)╚══════════════════════════════════════════════════════════════╝$(RESET)"
	@echo ""
	@echo "$(BOLD)Available Commands:$(RESET)"
	@echo ""
	@grep -E '^[a-zA-Z_/-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BOLD)Quick Start:$(RESET)"
	@echo "  $(DIM)make check/deps$(RESET)     # Verify dependencies"
	@echo "  $(DIM)make install$(RESET)         # Install tooling"
	@echo "  $(DIM)make lint$(RESET)            # Run all linters"
	@echo "  $(DIM)make lint/fix$(RESET)        # Auto-fix issues"
	@echo ""
