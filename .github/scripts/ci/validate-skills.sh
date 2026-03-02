#!/usr/bin/env bash
# ====================================================================================
# validate-skills.sh - Validates skills against the agentskills.io specification
# ====================================================================================
#
# Checks machine-verifiable rules from the Agent Skills specification:
#
#   R1:   Frontmatter name field (format, length, reserved words, directory match)
#   R2:   Frontmatter description field (existence, length, no XML tags)
#   R3.5: No unknown top-level frontmatter keys
#   R4:   Directory structure (SKILL.md exists, directory-name match)
#   R5.1: SKILL.md body ≤ 500 lines
#
# Usage:
#   validate-skills.sh [skills-directory]
#
# Arguments:
#   skills-directory   Path to the skills root directory (default: "skills")
#
# Exit codes:
#   0 - All skills pass validation
#   1 - One or more skills have FAIL-level violations
#
# ====================================================================================

set -euo pipefail

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SKILLS_DIR="${1:-skills}"

MAX_BODY_LINES=500
MAX_NAME_LENGTH=64
MAX_DESC_LENGTH=1024

ALLOWED_TOPLEVEL_KEYS="name description license compatibility metadata allowed-tools"
RESERVED_WORDS="anthropic claude"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Color Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    DIM=''
    RESET=''
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Counters
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_WARN=0
SKILL_PASS_COUNT=0
SKILL_FAIL_COUNT=0
CURRENT_SKILL_FAILED=false

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Logging
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

rule_pass() {
    local rule="$1" detail="$2"
    echo -e "  ${GREEN}PASS${RESET}  ${rule}  ${DIM}${detail}${RESET}"
    TOTAL_PASS=$((TOTAL_PASS + 1))
}

rule_fail() {
    local rule="$1" detail="$2"
    echo -e "  ${RED}FAIL${RESET}  ${rule}  ${detail}"
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
    CURRENT_SKILL_FAILED=true
}

rule_warn() {
    local rule="$1" detail="$2"
    echo -e "  ${YELLOW}WARN${RESET}  ${rule}  ${detail}"
    TOTAL_WARN=$((TOTAL_WARN + 1))
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# YAML Helpers
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Extract raw frontmatter (lines between first and second ---)
extract_frontmatter() {
    local file="$1"
    awk '/^---$/{n++; if(n==1){next} if(n==2){exit}} n==1{print}' "$file"
}

# Extract a simple scalar value from frontmatter (handles quoted/unquoted)
extract_field() {
    local frontmatter="$1" field="$2"
    local value
    value="$(echo "$frontmatter" | grep -m1 "^${field}:" | sed "s/^${field}:[[:space:]]*//")"
    # Strip surrounding quotes
    echo "$value" | sed "s/^['\"]//;s/['\"]$//"
}

# Extract description, handling >- / > / | multi-line YAML block scalars
extract_description() {
    local file="$1"
    local frontmatter
    frontmatter="$(extract_frontmatter "$file")"

    local desc_line
    desc_line="$(echo "$frontmatter" | grep -m1 '^description:')" || true

    if [[ -z "$desc_line" ]]; then
        echo ""
        return
    fi

    local value
    value="$(echo "$desc_line" | sed 's/^description:[[:space:]]*//')"

    # Check for block scalar indicators (>, >-, |, |-)
    if [[ "$value" =~ ^[\>\|] ]]; then
        # Multi-line: collect all indented continuation lines
        echo "$frontmatter" | awk '
            /^description:/ { found=1; next }
            found && /^[[:space:]]/ { gsub(/^[[:space:]]+/, ""); printf "%s ", $0; next }
            found && !/^[[:space:]]/ { exit }
        ' | sed 's/[[:space:]]$//'
    else
        # Single-line value — strip surrounding quotes
        echo "$value" | sed "s/^['\"]//;s/['\"]$//"
    fi
}

# Extract top-level keys from frontmatter (lines starting at column 0 with a colon)
extract_toplevel_keys() {
    local frontmatter="$1"
    echo "$frontmatter" | grep -E '^[a-zA-Z_-]+:' | sed 's/:.*//'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Validation Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

validate_name() {
    local name="$1" dir_name="$2"

    # R1.1: exists and non-empty
    if [[ -z "$name" ]]; then
        rule_fail "R1.1" "name field missing or empty"
        return
    fi
    rule_pass "R1.1" "name field exists: '${name}'"

    # R1.2: 1-64 characters
    if [[ ${#name} -gt $MAX_NAME_LENGTH ]]; then
        rule_fail "R1.2" "name is ${#name} chars (max ${MAX_NAME_LENGTH})"
    else
        rule_pass "R1.2" "name length: ${#name}"
    fi

    # R1.3: lowercase, digits, hyphens only
    if [[ ! "$name" =~ ^[a-z0-9-]+$ ]]; then
        rule_fail "R1.3" "name contains invalid characters: '${name}'"
    else
        rule_pass "R1.3" "name chars valid"
    fi

    # R1.4: no leading/trailing hyphens
    if [[ "$name" =~ ^- ]] || [[ "$name" =~ -$ ]]; then
        rule_fail "R1.4" "name starts or ends with hyphen: '${name}'"
    else
        rule_pass "R1.4" "no leading/trailing hyphens"
    fi

    # R1.5: no consecutive hyphens
    if [[ "$name" =~ -- ]]; then
        rule_fail "R1.5" "name contains consecutive hyphens: '${name}'"
    else
        rule_pass "R1.5" "no consecutive hyphens"
    fi

    # R1.6: matches directory name
    if [[ "$name" != "$dir_name" ]]; then
        rule_fail "R1.6" "name '${name}' does not match directory '${dir_name}'"
    else
        rule_pass "R1.6" "name matches directory"
    fi

    # R1.7: no reserved words
    local has_reserved=false
    for word in $RESERVED_WORDS; do
        if [[ "$name" == *"$word"* ]]; then
            rule_fail "R1.7" "name contains reserved word '${word}'"
            has_reserved=true
            break
        fi
    done
    if [[ "$has_reserved" == false ]]; then
        rule_pass "R1.7" "no reserved words"
    fi
}

validate_description() {
    local desc="$1"

    # R2.1: exists and non-empty
    if [[ -z "$desc" ]]; then
        rule_fail "R2.1" "description field missing or empty"
        return
    fi
    rule_pass "R2.1" "description exists (${#desc} chars)"

    # R2.2: 1-1024 characters
    if [[ ${#desc} -gt $MAX_DESC_LENGTH ]]; then
        rule_fail "R2.2" "description is ${#desc} chars (max ${MAX_DESC_LENGTH})"
    else
        rule_pass "R2.2" "description length: ${#desc}"
    fi

    # R2.3: no XML tags
    if echo "$desc" | grep -qE '<[a-zA-Z]'; then
        rule_fail "R2.3" "description contains XML-like tags"
    else
        rule_pass "R2.3" "no XML tags in description"
    fi
}

validate_toplevel_keys() {
    local frontmatter="$1"
    local keys
    keys="$(extract_toplevel_keys "$frontmatter")"

    local has_unknown=false
    while IFS= read -r key; do
        [[ -z "$key" ]] && continue
        local found=false
        for allowed in $ALLOWED_TOPLEVEL_KEYS; do
            if [[ "$key" == "$allowed" ]]; then
                found=true
                break
            fi
        done
        if [[ "$found" == false ]]; then
            rule_warn "R3.5" "unknown top-level key: '${key}'"
            has_unknown=true
        fi
    done <<< "$keys"

    if [[ "$has_unknown" == false ]]; then
        rule_pass "R3.5" "all top-level keys are recognized"
    fi
}

validate_body_lines() {
    local file="$1"
    local total
    total="$(wc -l < "$file" | tr -d ' ')"
    local frontmatter_end
    frontmatter_end="$(awk '/^---$/{n++; if(n==2){print NR; exit}}' "$file")"

    if [[ -z "$frontmatter_end" ]]; then
        rule_fail "R5.1" "could not find frontmatter closing '---'"
        return
    fi

    local body_lines
    body_lines=$((total - frontmatter_end))

    if [[ $body_lines -gt $MAX_BODY_LINES ]]; then
        rule_fail "R5.1" "body is ${body_lines} lines (max ${MAX_BODY_LINES})"
    else
        rule_pass "R5.1" "body: ${body_lines} lines"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${BLUE}  Agent Skills Specification Validator${RESET}"
echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

if [[ ! -d "$SKILLS_DIR" ]]; then
    echo -e "${RED}Error: Skills directory not found: ${SKILLS_DIR}${RESET}"
    exit 1
fi

# Find all SKILL.md files
shopt -s nullglob
SKILL_FILES=("${SKILLS_DIR}"/*/SKILL.md)
shopt -u nullglob

if [[ ${#SKILL_FILES[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No skills found in ${SKILLS_DIR}${RESET}"
    exit 0
fi

echo -e "Scanning ${BOLD}${#SKILL_FILES[@]}${RESET} skill(s) in ${DIM}${SKILLS_DIR}/${RESET}"
echo ""

for skill_file in "${SKILL_FILES[@]}"; do
    SKILL_DIR="$(dirname "$skill_file")"
    DIR_NAME="$(basename "$SKILL_DIR")"
    CURRENT_SKILL_FAILED=false

    echo -e "${BOLD}─── ${DIR_NAME} ───${RESET}"

    # Extract frontmatter
    frontmatter="$(extract_frontmatter "$skill_file")"

    if [[ -z "$frontmatter" ]]; then
        rule_fail "R4.1" "no YAML frontmatter found"
        SKILL_FAIL_COUNT=$((SKILL_FAIL_COUNT + 1))
        echo ""
        continue
    fi

    # R1: name field
    name="$(extract_field "$frontmatter" "name")"
    validate_name "$name" "$DIR_NAME"

    # R2: description field
    description="$(extract_description "$skill_file")"
    validate_description "$description"

    # R3.5: unknown top-level keys
    validate_toplevel_keys "$frontmatter"

    # R5.1: body line count
    validate_body_lines "$skill_file"

    # Track skill pass/fail
    if [[ "$CURRENT_SKILL_FAILED" == true ]]; then
        SKILL_FAIL_COUNT=$((SKILL_FAIL_COUNT + 1))
    else
        SKILL_PASS_COUNT=$((SKILL_PASS_COUNT + 1))
    fi

    echo ""
done

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Summary
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}Summary${RESET}"
echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  Skills scanned:  ${BOLD}${#SKILL_FILES[@]}${RESET}"
echo -e "  ${GREEN}Compliant:${RESET} ${SKILL_PASS_COUNT}  |  ${RED}Non-compliant:${RESET} ${SKILL_FAIL_COUNT}"
echo -e "  ${GREEN}PASS:${RESET} ${TOTAL_PASS}  |  ${RED}FAIL:${RESET} ${TOTAL_FAIL}  |  ${YELLOW}WARN:${RESET} ${TOTAL_WARN}"
echo ""

if [[ $TOTAL_FAIL -gt 0 ]]; then
    echo -e "${RED}${BOLD}Validation failed with ${TOTAL_FAIL} error(s).${RESET}"
    exit 1
else
    echo -e "${GREEN}${BOLD}All skills pass validation.${RESET}"
    exit 0
fi
