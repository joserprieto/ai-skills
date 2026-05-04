#!/usr/bin/env bash
# ====================================================================================
# generate-skills-index.sh - Regenerate the "Available Skills" table in README.md
# ====================================================================================
#
# Reads frontmatter from every skills/*/SKILL.md and rewrites the block between
# the AUTO-GENERATED markers in README.md with a fresh table.
#
# Columns:
#   - Skill (linked to skills/<dir>/SKILL.md)
#   - Version (from metadata.version)
#   - Summary (first sentence of description)
#
# Usage:
#   generate-skills-index.sh [--check]
#
# Modes:
#   default   Rewrites README.md in place
#   --check   Verifies README.md is in sync; exits 1 if not, 0 if yes (no changes)
#
# Exit codes:
#   0 - README.md updated (default mode) or already in sync (--check mode)
#   1 - --check failed: README.md is out of sync
#   2 - usage error or missing files
#
# ====================================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

README="${REPO_ROOT}/README.md"
SKILLS_DIR="${REPO_ROOT}/skills"
BEGIN_MARKER="<!-- BEGIN AUTO-GENERATED SKILLS TABLE - DO NOT EDIT BELOW -->"
END_MARKER="<!-- END AUTO-GENERATED SKILLS TABLE -->"

CHECK_MODE=0
if [[ "${1:-}" == "--check" ]]; then
    CHECK_MODE=1
elif [[ -n "${1:-}" ]]; then
    echo "Usage: $0 [--check]" >&2
    exit 2
fi

if [[ ! -f "${README}" ]]; then
    echo "ERROR: README.md not found at ${README}" >&2
    exit 2
fi

if [[ ! -d "${SKILLS_DIR}" ]]; then
    echo "ERROR: skills directory not found at ${SKILLS_DIR}" >&2
    exit 2
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Frontmatter helpers
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Extract the frontmatter block (between first two `---` lines)
extract_frontmatter() {
    awk '/^---$/{c++; if(c==2) exit; if(c==1) next} c==1{print}' "$1"
}

# Extract a single top-level scalar value
extract_top_field() {
    local file="$1"
    local key="$2"
    extract_frontmatter "${file}" | awk -v key="${key}" '
        $0 ~ "^"key":" {
            sub("^"key":[ ]*", "")
            sub(/^[\x27"]/, "")
            sub(/[\x27"]$/, "")
            print
            exit
        }
    '
}

# Extract metadata.version (nested key)
extract_version() {
    extract_frontmatter "$1" | awk '
        /^metadata:/ { in_meta = 1; next }
        in_meta && /^[a-zA-Z]/ { in_meta = 0 }
        in_meta && /^[ \t]+version:/ {
            sub(/^[ \t]+version:[ ]*/, "")
            sub(/^[\x27"]/, "")
            sub(/[\x27"]$/, "")
            print
            exit
        }
    '
}

# Extract description as a single normalized line
# Handles folded scalar (>-, >, |-) and inline single-line forms
extract_description() {
    extract_frontmatter "$1" | awk '
        /^description:/ {
            line = $0
            sub(/^description:[ ]*/, "", line)
            # Folded / literal block scalar markers
            if (line ~ /^[>|]-?[ ]*$/ || line == "") {
                in_block = 1
                next
            }
            # Inline single-line value
            print line
            exit
        }
        in_block {
            # Stop at the next top-level key (line starting with non-space alphabetic char)
            if (/^[a-zA-Z]/) exit
            sub(/^[ \t]+/, "")
            buf = (buf == "" ? $0 : buf " " $0)
        }
        END { if (buf != "") print buf }
    ' | sed -E 's/[[:space:]]+/ /g; s/^[[:space:]]+//; s/[[:space:]]+$//'
}

# Truncate to first real sentence boundary: a period followed by a space and an
# uppercase letter. This skips `.localhost`, `.md`, `e.g.`, etc. — those don't
# match the pattern because they're not followed by `[space][uppercase]`.
first_sentence() {
    local text="$1"
    echo "${text}" | awk '
        {
            pos = match($0, /\. [A-Z]/)
            if (pos > 0) {
                print substr($0, 1, pos)
            } else {
                print $0
            }
        }
    '
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Build the table
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

build_table() {
    echo "${BEGIN_MARKER}"
    echo ""
    echo "| Skill | Version | Summary |"
    echo "| ----- | ------- | ------- |"
    for skill_md in "${SKILLS_DIR}"/*/SKILL.md; do
        [[ -f "${skill_md}" ]] || continue
        local dir
        dir=$(basename "$(dirname "${skill_md}")")
        local version description summary
        version=$(extract_version "${skill_md}")
        description=$(extract_description "${skill_md}")
        summary=$(first_sentence "${description}")
        # Escape pipes in summary to avoid breaking the table
        summary=${summary//|/\\|}
        version=${version:-—}
        printf "| [%s](skills/%s/SKILL.md) | \`%s\` | %s |\n" \
            "${dir}" "${dir}" "${version}" "${summary}"
    done | sort
    echo ""
    echo "${END_MARKER}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Replace block between markers in README.md
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

replace_block() {
    local readme="$1"
    local new_block_file="$2"
    awk -v begin="${BEGIN_MARKER}" -v end="${END_MARKER}" -v new_file="${new_block_file}" '
        $0 == begin {
            while ((getline line < new_file) > 0) print line
            close(new_file)
            in_block = 1
            next
        }
        in_block && $0 == end {
            in_block = 0
            next
        }
        !in_block { print }
    ' "${readme}"
}

NEW_BLOCK_FILE=$(mktemp)
trap 'rm -f "${NEW_BLOCK_FILE}"' EXIT
build_table >"${NEW_BLOCK_FILE}"

if ! grep -qF "${BEGIN_MARKER}" "${README}"; then
    echo "ERROR: README.md does not contain BEGIN marker." >&2
    echo "       Add the following two lines where the table should appear:" >&2
    echo "       ${BEGIN_MARKER}" >&2
    echo "       ${END_MARKER}" >&2
    exit 2
fi

NEW_README=$(replace_block "${README}" "${NEW_BLOCK_FILE}")

if [[ "${CHECK_MODE}" -eq 1 ]]; then
    if ! diff -q <(echo "${NEW_README}") "${README}" >/dev/null 2>&1; then
        echo "ERROR: README.md is out of sync with skills/ frontmatter."
        echo "       Run 'make skills/index' to regenerate."
        echo ""
        echo "Diff:"
        diff <(echo "${NEW_README}") "${README}" || true
        exit 1
    fi
    echo "README.md skills index in sync."
    exit 0
fi

echo "${NEW_README}" >"${README}"
echo "README.md skills index regenerated."
