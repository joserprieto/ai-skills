#!/usr/bin/env bash
# ====================================================================================
# search.sh - Searches for open issues by labels
# ====================================================================================
#
# Usage:
#   search.sh --labels "label1,label2"
#
# Output:
#   Prints matching issue numbers to stdout, one per line.
#
# ====================================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

LABELS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --labels) LABELS="$2"; shift 2 ;;
        *)
            log_error "Unknown argument: $1"
            log_error "Usage: search.sh --labels \"label1,label2\""
            exit 1
            ;;
    esac
done

if [[ -z "${LABELS}" ]]; then
    log_error "Missing required argument: --labels"
    exit 1
fi

check_prerequisites

log_info "Searching for open issues with labels: ${LABELS}"

RESULTS="$(gh issue list \
    --repo "${REPO}" \
    --label "${LABELS}" \
    --state open \
    --json number \
    --jq '.[].number' \
    2>/dev/null || true)"

if [[ -z "${RESULTS}" ]]; then
    log_info "No open issues found matching labels: ${LABELS}"
    exit 0
fi

COUNT="$(echo "${RESULTS}" | wc -l | tr -d ' ')"
log_info "Found ${COUNT} open issue(s) matching labels: ${LABELS}"
echo "${RESULTS}"
