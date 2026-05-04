#!/usr/bin/env bash
# ====================================================================================
# smoke-check-make-targets.sh - Validate `make <target>` references in skills
# ====================================================================================
#
# Static reference check (no command execution). For every `make <target>` invocation
# inside a fenced bash/makefile/shell code block in skills/*.md, verifies that the
# target is declared somewhere as a Makefile target.
#
# This catches the class of bug found in the 2026-05-04 audit: docs reference
# `make test` while the Makefile template doesn't define it, or `make release/first`
# that doesn't exist anywhere.
#
# Where the targets must be declared:
#   - The repo's local Makefile (catches references to local infra targets like
#     `make skills/index`, `make lint/skills`).
#   - The scaffold Makefile template at
#     `skills/repo-kickstart/assets/templates/makefile.tpl.md` (catches references
#     to canonical scaffold targets like `make qa`, `make release/patch`).
#
# Limits / out of scope:
#   - Does NOT verify `npm run X`, `pnpm X`, or arbitrary shell commands.
#   - Does NOT execute anything.
#   - Skills can declare additional ad-hoc Make targets in their own examples; if a
#     reference matches neither the local Makefile nor the scaffold template,
#     it's flagged. False positives are intentional — the goal is to catch typos
#     and stale references.
#
# Usage:
#   smoke-check-make-targets.sh [skills-directory]
#
# Exit codes:
#   0 - All `make <target>` references resolve to a declared target
#   1 - One or more references are unresolved
#
# ====================================================================================

set -euo pipefail

SKILLS_DIR="${1:-skills}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

LOCAL_MAKEFILE="${REPO_ROOT}/Makefile"
SCAFFOLD_MAKEFILE="${REPO_ROOT}/skills/repo-kickstart/assets/templates/makefile.tpl.md"

if [[ ! -d "${SKILLS_DIR}" ]]; then
    echo "ERROR: skills directory not found at ${SKILLS_DIR}" >&2
    exit 2
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Build the union of declared targets from the two known sources
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DECLARED=$(mktemp)
trap 'rm -f "${DECLARED}"' EXIT

# Extracts target names from a file. Lines like `target:` or `target: deps...`
# at column 0, or `.PHONY: a b c` lines.
extract_targets() {
    local file="$1"
    [[ -f "${file}" ]] || return 0
    awk '
        # .PHONY declarations: extract every target listed
        /^\.PHONY:[[:space:]]/ {
            sub(/^\.PHONY:[[:space:]]*/, "")
            n = split($0, parts, /[[:space:]]+/)
            for (i = 1; i <= n; i++) if (parts[i] != "") print parts[i]
            next
        }
        # Regular target declarations: `target:` or `target: deps`
        /^[a-zA-Z_][a-zA-Z0-9_\/.-]*:/ {
            t = $0
            sub(/:.*$/, "", t)
            print t
        }
    ' "${file}"
}

extract_targets "${LOCAL_MAKEFILE}" | sort -u >"${DECLARED}"
extract_targets "${SCAFFOLD_MAKEFILE}" | sort -u >>"${DECLARED}"
sort -u -o "${DECLARED}" "${DECLARED}"

DECLARED_COUNT=$(wc -l <"${DECLARED}" | tr -d ' ')

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Walk skills/*.md, extract `make <target>` from fenced bash/sh/makefile blocks
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extract_make_invocations() {
    awk '
        # Track fenced-code state and the language tag.
        /^[[:space:]]*```/ {
            if (in_fence) { in_fence = 0; lang = ""; next }
            in_fence = 1
            line = $0
            sub(/^[[:space:]]*```[[:space:]]*/, "", line)
            lang = line
            next
        }
        /^[[:space:]]*~~~/ {
            if (in_fence) { in_fence = 0; lang = ""; next }
            in_fence = 1
            line = $0
            sub(/^[[:space:]]*~~~[[:space:]]*/, "", line)
            lang = line
            next
        }
        # Only inspect bash/sh/zsh/makefile fences.
        in_fence && (lang == "bash" || lang == "sh" || lang == "shell" || lang == "zsh" || lang == "makefile" || lang == "make") {
            line = $0
            # Strip content inside double quotes — `echo "make not found"` is a
            # printable string, not a real make invocation. Without this, every
            # error message that happens to mention "make foo" gets flagged.
            gsub(/"[^"]*"/, "", line)
            # Find every `make <target>` occurrence.
            while (match(line, /(^|[[:space:]])make[[:space:]]+[a-zA-Z_][a-zA-Z0-9_\/.-]*/)) {
                token = substr(line, RSTART, RLENGTH)
                # Strip leading whitespace and the `make ` prefix
                sub(/^[[:space:]]*make[[:space:]]+/, "", token)
                if (length(token) > 0) print NR "\t" token
                line = substr(line, RSTART + RLENGTH)
            }
        }
    ' "$1"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main scan
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

UNRESOLVED=0
TOTAL=0

while IFS= read -r md_file; do
    while IFS=$'\t' read -r line_no target; do
        [[ -z "${target}" ]] && continue
        TOTAL=$((TOTAL + 1))
        # Quick exact-match check against the declared set
        if grep -qFx "${target}" "${DECLARED}"; then
            continue
        fi
        echo "UNRESOLVED: ${md_file}:${line_no} → make ${target}"
        UNRESOLVED=$((UNRESOLVED + 1))
    done < <(extract_make_invocations "${md_file}")
done < <(find "${SKILLS_DIR}" -type f -name '*.md' | sort)

echo ""
echo "Scanned ${TOTAL} 'make <target>' reference(s)."
echo "Cross-checked against ${DECLARED_COUNT} declared targets (local Makefile + scaffold template)."

if [[ ${UNRESOLVED} -gt 0 ]]; then
    echo "ERROR: ${UNRESOLVED} unresolved 'make <target>' reference(s)."
    echo ""
    echo "Targets not found in either:"
    echo "  - ${LOCAL_MAKEFILE}"
    echo "  - ${SCAFFOLD_MAKEFILE}"
    echo ""
    echo "Either declare the target in one of those files, or correct the reference"
    echo "in the skill that uses it."
    exit 1
fi

echo "All 'make <target>' references resolve."
