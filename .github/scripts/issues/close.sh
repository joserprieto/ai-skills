#!/usr/bin/env bash
# ====================================================================================
# close.sh - Closes a GitHub issue with an optional comment
# ====================================================================================
#
# Usage:
#   close.sh --issue <number> [--comment "..."]
#
# ====================================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

ISSUE_NUMBER=""
COMMENT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --issue)   ISSUE_NUMBER="$2"; shift 2 ;;
        --comment) COMMENT="$2";      shift 2 ;;
        *)
            log_error "Unknown argument: $1"
            log_error "Usage: close.sh --issue <number> [--comment \"...\"]"
            exit 1
            ;;
    esac
done

if [[ -z "${ISSUE_NUMBER}" ]]; then
    log_error "Missing required argument: --issue"
    exit 1
fi

if ! [[ "${ISSUE_NUMBER}" =~ ^[0-9]+$ ]]; then
    log_error "Issue number must be a positive integer, got: ${ISSUE_NUMBER}"
    exit 1
fi

check_prerequisites

if [[ -n "${COMMENT}" ]]; then
    log_info "Adding comment to issue #${ISSUE_NUMBER}..."
    gh issue comment "${ISSUE_NUMBER}" \
        --repo "${REPO}" \
        --body "${COMMENT}"
    log_success "Comment added to issue #${ISSUE_NUMBER}."
fi

log_info "Closing issue #${ISSUE_NUMBER}..."
gh issue close "${ISSUE_NUMBER}" \
    --repo "${REPO}" \
    --reason "completed"
log_success "Issue #${ISSUE_NUMBER} closed."
