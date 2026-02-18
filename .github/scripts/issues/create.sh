#!/usr/bin/env bash
# ====================================================================================
# create.sh - Creates a GitHub issue with title, body, and labels
# ====================================================================================
#
# Usage:
#   create.sh --title "..." --body "..." --labels "label1,label2"
#
# Output:
#   Prints the issue number to stdout on success.
#
# ====================================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Argument Parsing
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TITLE=""
BODY=""
LABELS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --title)  TITLE="$2";  shift 2 ;;
        --body)   BODY="$2";   shift 2 ;;
        --labels) LABELS="$2"; shift 2 ;;
        *)
            log_error "Unknown argument: $1"
            log_error "Usage: create.sh --title \"...\" --body \"...\" --labels \"label1,label2\""
            exit 1
            ;;
    esac
done

if [[ -z "${TITLE}" ]]; then
    log_error "Missing required argument: --title"
    exit 1
fi

if [[ -z "${BODY}" ]]; then
    log_error "Missing required argument: --body"
    exit 1
fi

check_prerequisites

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Create Issue
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_info "Creating issue: ${TITLE}"

GH_ARGS=(
    issue create
    --repo "${REPO}"
    --title "${TITLE}"
    --body "${BODY}"
)

if [[ -n "${LABELS}" ]]; then
    GH_ARGS+=(--label "${LABELS}")
fi

ISSUE_URL="$(gh "${GH_ARGS[@]}")"

if [[ -z "${ISSUE_URL}" ]]; then
    log_error "Failed to create issue."
    exit 1
fi

ISSUE_NUMBER="$(basename "${ISSUE_URL}")"
log_success "Issue #${ISSUE_NUMBER} created: ${ISSUE_URL}"
echo "${ISSUE_NUMBER}"
