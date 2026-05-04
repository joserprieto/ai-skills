#!/usr/bin/env bash
# ====================================================================================
# validate-cross-refs.sh - Verify that internal links in skills point to existing files
# ====================================================================================
#
# Walks every .md file under skills/ and extracts markdown links of the form
# `[text](path)` and `![alt](path)`. For each link:
#
#   - Skips external URLs (http://, https://, mailto:, ftp://, etc.)
#   - Skips anchor-only links (`#section`)
#   - Skips reference-style links (`[text][ref]` definitions are not validated;
#     supporting them would require a second pass — out of scope for v1)
#   - Resolves the path relative to the file containing the link
#   - Strips trailing `#anchor` before checking
#   - Reports `BROKEN: file:line → link` if the resolved path doesn't exist
#
# Usage:
#   validate-cross-refs.sh [skills-directory]
#
# Arguments:
#   skills-directory   Path to the skills root (default: "skills")
#
# Exit codes:
#   0 - All cross-refs are valid
#   1 - One or more broken cross-refs found
#
# ====================================================================================

set -euo pipefail

SKILLS_DIR="${1:-skills}"

if [[ ! -d "${SKILLS_DIR}" ]]; then
    echo "ERROR: skills directory not found at ${SKILLS_DIR}" >&2
    exit 2
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Link extraction
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Extracts all markdown inline links from a file. Outputs one
# `line_number\tlink` per match. Uses awk's match() because BSD grep
# doesn't support PCRE on macOS by default.
#
# Skips content inside fenced code blocks (``` or ~~~). This is the
# common case where false positives appear: bash variables (${RUN_URL}),
# Handlebars templates ({{host}}/...), or pseudo-syntax like `[t](url)`
# meant as documentation, not as real links.
extract_links() {
    awk '
        # Toggle fenced-code state. Treat both ``` and ~~~ fences.
        /^[[:space:]]*```/ || /^[[:space:]]*~~~/ {
            in_fence = !in_fence
            next
        }
        in_fence { next }
        {
            line = $0
            # Strip inline-code spans: `...`. Markdown links inside backticks
            # are documentation of syntax, not real links (e.g. `[#42](url)`).
            gsub(/`[^`]*`/, "", line)
            while (match(line, /\[[^]]*\]\([^)]+\)/)) {
                token = substr(line, RSTART, RLENGTH)
                # Strip everything up to and including the opening "("
                sub(/^[^(]*\(/, "", token)
                # Strip the trailing ")"
                sub(/\)$/, "", token)
                # Strip trailing "#anchor" but keep the path
                sub(/#.*$/, "", token)
                # Skip empty (anchor-only links became empty here)
                if (length(token) > 0) {
                    print NR "\t" token
                }
                line = substr(line, RSTART + RLENGTH)
            }
        }
    ' "$1"
}

is_external() {
    [[ "$1" =~ ^(https?|ftp|mailto|tel|file|data): ]]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main scan
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BROKEN=0
TOTAL=0

while IFS= read -r md_file; do
    file_dir=$(dirname "${md_file}")
    while IFS=$'\t' read -r line_no link; do
        [[ -z "${link}" ]] && continue
        TOTAL=$((TOTAL + 1))
        if is_external "${link}"; then
            continue
        fi
        # Resolve relative to the file's directory
        resolved="${file_dir}/${link}"
        if [[ ! -e "${resolved}" ]]; then
            echo "BROKEN: ${md_file}:${line_no} → ${link}"
            BROKEN=$((BROKEN + 1))
        fi
    done < <(extract_links "${md_file}")
done < <(find "${SKILLS_DIR}" -type f -name '*.md' | sort)

echo ""
echo "Scanned ${TOTAL} link(s) across $(find "${SKILLS_DIR}" -type f -name '*.md' | wc -l | tr -d ' ') markdown file(s)."

if [[ ${BROKEN} -gt 0 ]]; then
    echo "ERROR: ${BROKEN} broken cross-ref(s) found."
    exit 1
fi

echo "All cross-refs valid."
